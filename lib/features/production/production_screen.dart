import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../shared/widgets/glass_card.dart';
import '../home/providers/dishes_provider.dart';

// ─── Провайдер истории производства ─────────────────────────────────────────
final productionHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('production')
      .select('*, dishes(name, category)')
      .order('created_at', ascending: false)
      .limit(100);
  return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
});

// ─── Экран производства ──────────────────────────────────────────────────────
class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: const Text('Производство',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.neonCyan,
          indicatorWeight: 2,
          labelColor: AppColors.neonCyan,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Добавить'),
            Tab(text: 'История'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(
                  decoration:
                      const BoxDecoration(gradient: AppGradients.bgRadial))),
          TabBarView(
            controller: _tabController,
            children: [
              _AddProductionTab(onAdded: () {
                ref.invalidate(productionHistoryProvider);
                _tabController.animateTo(1);
              }),
              const _HistoryTab(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Таб добавления производства ─────────────────────────────────────────────
class _AddProductionTab extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _AddProductionTab({required this.onAdded});

  @override
  ConsumerState<_AddProductionTab> createState() => _AddProductionTabState();
}

class _AddProductionTabState extends ConsumerState<_AddProductionTab> {
  Dish? selectedDish;
  final qtyCtrl = TextEditingController(text: '1');
  final noteCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    qtyCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (selectedDish == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Выберите блюдо'),
        backgroundColor: AppColors.neonOrange,
      ));
      return;
    }
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Введите количество'),
        backgroundColor: AppColors.neonOrange,
      ));
      return;
    }

    setState(() => isLoading = true);
    try {
      await supabase.from('production').insert({
        'dish_id': selectedDish!.id,
        'quantity': qty,
        'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        'created_by': supabase.auth.currentUser?.id,
      });

      await ref
          .read(dishesProvider.notifier)
          .addStock(selectedDish!.id, selectedDish!.stock, qty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${qty.toInt()} × ${selectedDish!.name} добавлено'),
          backgroundColor: AppColors.neonGreen,
        ));
        setState(() => selectedDish = null);
        qtyCtrl.text = '1';
        noteCtrl.clear();
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: AppColors.neonRed,
        ));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(dishesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          GlassCard(
            glowColor: AppColors.neonGreen,
            shimmerBorder: true,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.factory_outlined,
                    color: AppColors.neonGreen, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Учёт производства',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Сколько изготовили сегодня',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Блюдо',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          dishesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan)),
            error: (e, _) => Text('Ошибка: $e',
                style: const TextStyle(color: AppColors.neonRed)),
            data: (dishes) => Container(
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selectedDish != null
                        ? AppColors.neonCyan
                        : AppColors.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Dish>(
                  value: selectedDish,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Выберите блюдо...',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  isExpanded: true,
                  dropdownColor: AppColors.bgElevated,
                  icon: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary),
                  ),
                  items: dishes
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(children: [
                                Text(AppConstants.iconFor(d.category),
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                  d.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                )),
                                Text('${d.stock.toInt()} шт.',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ]),
                            ),
                          ))
                      .toList(),
                  onChanged: (d) => setState(() => selectedDish = d),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedDish != null) ...[
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Text(AppConstants.iconFor(selectedDish!.category),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedDish!.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    Text('Сейчас в наличии: ${selectedDish!.stock.toInt()} шт.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                )),
                NeonBadge(
                    text: selectedDish!.category, color: AppColors.neonPurple),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Количество (шт.)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _CounterBtn(
              icon: Icons.remove,
              onTap: () {
                final v = double.tryParse(qtyCtrl.text) ?? 1;
                if (v > 1)
                  setState(() => qtyCtrl.text = (v - 1).toInt().toString());
              },
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.neonCyan, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            _CounterBtn(
              icon: Icons.add,
              onTap: () {
                final v = double.tryParse(qtyCtrl.text) ?? 1;
                setState(() => qtyCtrl.text = (v + 1).toInt().toString());
              },
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Заметка (необязательно)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: noteCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Например: утренняя партия, свежие...',
              filled: true,
              fillColor: AppColors.bgElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.neonCyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.bgDeep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.bgDeep))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        selectedDish != null
                            ? 'Добавить ${qtyCtrl.text} × ${selectedDish!.name}'
                            : 'Записать производство',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Таб истории ─────────────────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(productionHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan)),
      error: (e, _) => Center(
          child: Text('Ошибка: $e',
              style: const TextStyle(color: AppColors.neonRed))),
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('🏭', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Записей производства нет',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              SizedBox(height: 8),
              Text('Добавьте первую запись на вкладке «Добавить»',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
          );
        }

        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var r in records) {
          final date = DateTime.parse(r['created_at']);
          final key = DateFormat('dd MMMM yyyy', 'ru').format(date);
          grouped.putIfAbsent(key, () => []).add(r);
        }

        return RefreshIndicator(
          color: AppColors.neonCyan,
          onRefresh: () async => ref.invalidate(productionHistoryProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries
                .map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.neonCyan, size: 14),
                            const SizedBox(width: 8),
                            Text(entry.key,
                                style: const TextStyle(
                                    color: AppColors.neonCyan,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Container(
                                    height: 1, color: AppColors.borderSubtle)),
                          ]),
                        ),
                        ...entry.value.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _ProductionRecord(record: r),
                            )),
                      ],
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _ProductionRecord extends StatelessWidget {
  final Map<String, dynamic> record;
  const _ProductionRecord({required this.record});

  @override
  Widget build(BuildContext context) {
    final dish = record['dishes'];
    final name = dish?['name'] ?? 'Неизвестно';
    final category = dish?['category'] ?? 'Основное';
    final qty = (record['quantity'] ?? 0).toDouble();
    final note = record['note'] as String?;
    final time = DateTime.parse(record['created_at']);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
          ),
          child: Center(
              child: Text(AppConstants.iconFor(category),
                  style: const TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(note,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 3),
            Text(DateFormat('HH:mm').format(time),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+${qty.toInt()}',
              style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          const Text('шт.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      );
}
