import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../shared/dialogs/app_dialog.dart';
import 'providers/dishes_provider.dart';
import 'providers/shift_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/user_provider.dart';
import 'widgets/dish_card.dart';
import 'widgets/dish_dialogs.dart';
import 'widgets/shift_dialogs.dart';
import 'widgets/shift_panel.dart';
import 'widgets/cart_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/production/production_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimController;
  final TextEditingController _searchController = TextEditingController();
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userRoleProvider);
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabExpanded = !_fabExpanded);
    _fabExpanded ? _fabAnimController.forward() : _fabAnimController.reverse();
  }

  Future<void> _handleLogout() async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Выйти из аккаунта?',
      message: 'Вы уверены, что хотите выйти?',
      confirmLabel: 'Выйти',
      confirmColor: AppColors.neonOrange,
      icon: Icons.logout,
    );
    if (confirm && mounted) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleShiftAction() async {
    final shift = ref.read(currentShiftProvider).value;
    if (shift == null) {
      showOpenShiftDialog(context, ref);
    } else {
      final confirm = await showConfirmDialog(
        context: context,
        title: 'Закрыть смену?',
        message: 'Выручка будет подсчитана и смена завершена.',
        confirmLabel: 'Продолжить',
        confirmColor: AppColors.neonRed,
        icon: Icons.stop_circle_outlined,
      );
      if (confirm && mounted) {
        showCloseShiftDialog(context, ref, shift);
      }
    }
  }

  void _handleAddToCart(Dish dish) {
    final shift = ref.read(currentShiftProvider).value;
    if (shift == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Сначала откройте смену'),
        ]),
        backgroundColor: AppColors.neonOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (dish.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ ${dish.name} — нет в наличии'),
        backgroundColor: AppColors.neonRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    HapticFeedback.lightImpact();
    ref.read(cartProvider.notifier).addItem(dish);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text('${dish.name} добавлено в корзину'),
      ]),
      backgroundColor: AppColors.neonGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _handleDelete(Dish dish) async {
    final confirm = await showConfirmDialog(
      context: context,
      title: 'Удалить блюдо?',
      message:
          'Блюдо «${dish.name}» будет удалено без возможности восстановления.',
      confirmLabel: 'Удалить',
      confirmColor: AppColors.neonRed,
    );
    if (confirm) {
      try {
        await ref.read(dishesProvider.notifier).deleteDish(dish.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('🗑 ${dish.name} удалено'),
            backgroundColor: AppColors.neonRed,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: AppColors.neonRed,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(dishesProvider);
    final filteredDishes = ref.watch(filteredDishesProvider);
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(selectedCategoryProvider);
    final shiftAsync = ref.watch(currentShiftProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final isAdmin = roleAsync.maybeWhen(
      data: (role) => role == 'admin',
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, cartCount, isAdmin),
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(
                  decoration:
                      const BoxDecoration(gradient: AppGradients.bgRadial))),
          Column(
            children: [
              SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight),
              const ShiftPanel(),
              const SizedBox(height: 12),
              _buildCategoryFilter(category),
              const SizedBox(height: 8),
              _buildSearchBar(query),
              const SizedBox(height: 8),
              Expanded(
                child: dishesAsync.when(
                  loading: () => _buildShimmerList(),
                  error: (e, _) => _buildError(e),
                  data: (_) => filteredDishes.isEmpty
                      ? _buildEmpty(query, category)
                      : _buildDishList(filteredDishes, shiftAsync.value),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFab(shiftAsync.value),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, int cartCount, bool isAdmin) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgDeep, AppColors.bgDeep.withOpacity(0)],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppGradients.neonHeader,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Столовая',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  )),
              Text(supabase.auth.currentUser?.email ?? '',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
      actions: [
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined,
                color: AppColors.textSecondary, size: 24),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartScreen())),
            tooltip: 'Корзина',
          ),
          if (cartCount > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.neonGreen.withOpacity(0.5),
                        blurRadius: 6)
                  ],
                ),
                child: Center(
                    child: Text(
                  cartCount > 9 ? '9+' : '$cartCount',
                  style: const TextStyle(
                      color: AppColors.bgDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                )),
              ),
            ),
        ]),
        IconButton(
          icon: const Icon(Icons.refresh_rounded,
              color: AppColors.textSecondary, size: 22),
          onPressed: () => ref.read(dishesProvider.notifier).refresh(),
        ),
        IconButton(
          icon: const Icon(Icons.history_rounded,
              color: AppColors.textSecondary, size: 22),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ShiftHistoryScreen())),
        ),
        if (isAdmin) ...[
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined,
                color: AppColors.neonOrange, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminScreen())),
            tooltip: 'Панель администратора',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.neonPurple, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
            tooltip: 'Добавить сотрудника',
          ),
        ],
        IconButton(
          icon: const Icon(Icons.logout_rounded,
              color: AppColors.textSecondary, size: 22),
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCategoryFilter(String selectedCat) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.categories.length,
        itemBuilder: (context, i) {
          final cat = AppConstants.categories[i];
          final isSelected = cat == selectedCat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = cat,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.neonCyan.withOpacity(0.2)
                      : AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neonCyan
                        : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '${AppConstants.iconFor(cat)} $cat',
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.neonCyan
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(String currentQuery) {
    if (_searchController.text != currentQuery) {
      _searchController.text = currentQuery;
      _searchController.selection =
          TextSelection.collapsed(offset: currentQuery.length);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Поиск блюда...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: currentQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    ref.read(searchQueryProvider.notifier).state = '';
                    _searchController.clear();
                  },
                  child: const Icon(Icons.clear,
                      size: 18, color: AppColors.textMuted),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDishList(List<Dish> dishes, Shift? shift) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: dishes.length,
      itemBuilder: (context, i) {
        final dish = dishes[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DishCard(
            dish: dish,
            shiftOpen: shift != null,
            onSell: () => _handleAddToCart(dish),
            onAddStock: () => showAddStockDialog(context, ref, dish),
            onDelete: () => _handleDelete(dish),
            onEdit: () => showEditDishDialog(context, ref, dish),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: 6,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: _ShimmerCard(),
      ),
    );
  }

  Widget _buildEmpty(String query, String category) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty
                ? 'Ничего не найдено\nпо запросу «$query»'
                : 'В категории «$category»\nпока нет блюд',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.neonRed, size: 48),
          const SizedBox(height: 12),
          const Text('Ошибка загрузки',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.read(dishesProvider.notifier).refresh(),
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(Shift? shift) {
    final isOpen = shift != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _fabAnimController,
          builder: (context, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_fabAnimController.value > 0) ...[
                // Кнопка производства
                Transform.translate(
                  offset: Offset(0, 130 * (1 - _fabAnimController.value)),
                  child: Opacity(
                    opacity: _fabAnimController.value,
                    child: _FabMenuItem(
                      label: 'Производство',
                      icon: Icons.factory_outlined,
                      color: AppColors.neonGreen,
                      onTap: () {
                        _toggleFab();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProductionScreen()));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Кнопка добавить блюдо
                Transform.translate(
                  offset: Offset(0, 60 * (1 - _fabAnimController.value)),
                  child: Opacity(
                    opacity: _fabAnimController.value,
                    child: _FabMenuItem(
                      label: 'Добавить блюдо',
                      icon: Icons.add,
                      color: AppColors.neonCyan,
                      onTap: () {
                        _toggleFab();
                        showAddDishDialog(context, ref);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _GradientFab(
              label: isOpen ? 'Сдать смену' : 'Открыть смену',
              icon: isOpen ? Icons.stop_rounded : Icons.play_arrow_rounded,
              gradient:
                  isOpen ? AppGradients.redShift : AppGradients.greenShift,
              onTap: _handleShiftAction,
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _toggleFab,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: AnimatedRotation(
                  turns: _fabExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.add,
                      color: AppColors.textPrimary, size: 28),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Экран регистрации ───────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  bool isLoading = false;
  bool obscurePass = true;

  Future<void> _register() async {
    if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Заполните все поля'),
          backgroundColor: AppColors.neonOrange));
      return;
    }
    setState(() => isLoading = true);
    try {
      final res = await supabase.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        data: {'name': nameCtrl.text.trim()},
      );
      if (res.user != null) {
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'name': nameCtrl.text.trim(),
          'role': 'seller',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Сотрудник зарегистрирован'),
            backgroundColor: AppColors.neonGreen));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❌ Ошибка: $e'), backgroundColor: AppColors.neonRed));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Добавить сотрудника',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Stack(children: [
        Positioned.fill(
            child: Container(
                decoration:
                    const BoxDecoration(gradient: AppGradients.bgRadial))),
        SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.neonPurple.withOpacity(0.4)),
              ),
              child: const Icon(Icons.person_add,
                  color: AppColors.neonPurple, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Новый сотрудник',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Роль: Продавец',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
              ),
              child: Column(children: [
                TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Имя сотрудника',
                        prefixIcon: Icon(Icons.badge_outlined, size: 18))),
                const SizedBox(height: 14),
                TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email, size: 18))),
                const SizedBox(height: 14),
                TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePass,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => obscurePass = !obscurePass),
                          child: Icon(
                              obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textSecondary)),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Зарегистрировать',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ]),
        )),
      ]),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  const _GradientFab(
      {required this.label,
      required this.icon,
      required this.gradient,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ]),
        ),
      );
}

class _FabMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FabMenuItem(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      );
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            )),
      );
}
