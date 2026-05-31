import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/cart_provider.dart';
import '../providers/dishes_provider.dart';
import '../providers/shift_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final shift = ref.watch(currentShiftProvider).value;

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
        title: const Text(
          'Корзина',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Очистить',
                  style: TextStyle(color: AppColors.neonRed, fontSize: 13)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Фон
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.bgRadial),
            ),
          ),

          if (cart.isEmpty)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🛒', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('Корзина пуста',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Добавьте блюда на главном экране',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            )
          else
            Column(
              children: [
                // Список позиций
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: cart.length,
                    itemBuilder: (context, i) {
                      final item = cart[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Row(
                            children: [
                              // Эмодзи
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Center(
                                  child: Text(
                                    AppConstants.iconFor(item.dish.category),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Название + цена
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.dish.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.dish.price.toInt()} ₸ × ${item.quantity}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Счётчик
                              Row(
                                children: [
                                  _CounterBtn(
                                    icon: Icons.remove,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .removeOne(item.dish.id),
                                  ),
                                  Container(
                                    width: 36,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  _CounterBtn(
                                    icon: Icons.add,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .addItem(item.dish),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),

                              // Сумма позиции
                              Text(
                                '${item.total.toInt()} ₸',
                                style: const TextStyle(
                                  color: AppColors.neonCyan,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Итого + кнопка пробить
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    border:
                        Border(top: BorderSide(color: AppColors.borderSubtle)),
                  ),
                  child: Column(
                    children: [
                      // Итого
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Позиций:',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          Text('${cart.length}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итого:',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${total.toInt()} ₸',
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Кнопка пробить
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: shift == null
                              ? null
                              : () =>
                                  _checkout(context, ref, cart, shift, total),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonGreen,
                            foregroundColor: AppColors.bgDeep,
                            disabledBackgroundColor:
                                AppColors.textMuted.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            shift == null
                                ? 'Сначала откройте смену'
                                : '✅  Пробить  •  ${total.toInt()} ₸',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _checkout(
    BuildContext context,
    WidgetRef ref,
    List<CartItem> cart,
    Shift shift,
    double total,
  ) async {
    try {
      // Записываем каждую позицию как продажу
      for (final item in cart) {
        await recordSale(
          shiftId: shift.id,
          dishId: item.dish.id,
          quantity: item.quantity.toDouble(),
          price: item.dish.price,
          currentStock: item.dish.stock,
        );
      }

      // Обновляем список блюд
      ref.read(dishesProvider.notifier).refresh();
      ref.invalidate(currentShiftSalesProvider);

      // Очищаем корзину
      ref.read(cartProvider.notifier).clear();

      if (context.mounted) {
        Navigator.pop(context);
        _showReceipt(context, cart, total);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    }
  }

  void _showReceipt(BuildContext context, List<CartItem> cart, double total) {
    final now = DateTime.now();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Шапка
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Text('🏪', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text('СТОЛОВАЯ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 4,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd.MM.yyyy  HH:mm').format(now),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Перфорация
              _Perforation(),

              // Позиции
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      ...cart.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.dish.name} × ${item.quantity}',
                                    style: const TextStyle(
                                        color: Color(0xFF444444), fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${item.total.toInt()} ₸',
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(color: Color(0xFFE0E0E0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ИТОГО',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1,
                              )),
                          Text('${total.toInt()} ₸',
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              )),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Перфорация
              _Perforation(),

              // Подвал
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Спасибо за покупку! 🙏',
                        style:
                            TextStyle(color: Color(0xFF666666), fontSize: 13)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Закрыть'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Кнопка счётчика ─────────────────────────────────────────────────────────
class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─── Перфорация чека ─────────────────────────────────────────────────────────
class _Perforation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            color: i.isEven ? const Color(0xFFEEEEEE) : Colors.white,
          ),
        ),
      ),
    );
  }
}
