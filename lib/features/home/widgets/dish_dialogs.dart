import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../shared/dialogs/app_dialog.dart';
import '../providers/dishes_provider.dart';
import '../providers/shift_provider.dart';

// ─── Диалог ДОБАВЛЕНИЯ блюда ─────────────────────────────────────────────────
void showAddDishDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '500');
  final stockCtrl = TextEditingController(text: '10');
  String selectedCat = 'Горячее';

  AppDialog.show(
    context: context,
    title: 'Новое блюдо',
    titleIcon: Icons.restaurant_menu,
    accentColor: AppColors.neonCyan,
    content: StatefulBuilder(
        builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogTextField(
                    controller: nameCtrl,
                    label: 'Название',
                    icon: Icons.label_outline),
                const SizedBox(height: 14),
                DialogTextField(
                  controller: priceCtrl,
                  label: 'Цена (₸)',
                  keyboardType: TextInputType.number,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 14),
                DialogTextField(
                  controller: stockCtrl,
                  label: 'Начальный остаток',
                  keyboardType: TextInputType.number,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Категория',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _CategoryPicker(
                      selected: selectedCat,
                      onChanged: (val) => setState(() => selectedCat = val),
                    ),
                  ],
                ),
              ],
            )),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonCyan,
          foregroundColor: AppColors.bgDeep,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          final price = double.tryParse(priceCtrl.text) ?? 0;
          final stock = double.tryParse(stockCtrl.text) ?? 0;
          Navigator.pop(context);
          await ref.read(dishesProvider.notifier).addDish(
                name: name,
                price: price,
                stock: stock,
                category: selectedCat,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $name добавлено'),
                backgroundColor: AppColors.neonGreen,
              ),
            );
          }
        },
        child: const Text('Добавить',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ─── Диалог РЕДАКТИРОВАНИЯ блюда ─────────────────────────────────────────────
void showEditDishDialog(BuildContext context, WidgetRef ref, Dish dish) {
  final nameCtrl = TextEditingController(text: dish.name);
  final priceCtrl = TextEditingController(text: dish.price.toInt().toString());
  final stockCtrl = TextEditingController(text: dish.stock.toInt().toString());
  String selectedCat = dish.category;

  AppDialog.show(
    context: context,
    title: 'Редактировать блюдо',
    titleIcon: Icons.edit_outlined,
    accentColor: AppColors.neonPurple,
    content: StatefulBuilder(
        builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DialogTextField(
                    controller: nameCtrl,
                    label: 'Название',
                    icon: Icons.label_outline),
                const SizedBox(height: 14),
                DialogTextField(
                  controller: priceCtrl,
                  label: 'Цена (₸)',
                  keyboardType: TextInputType.number,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 14),
                DialogTextField(
                  controller: stockCtrl,
                  label: 'Остаток',
                  keyboardType: TextInputType.number,
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Категория',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    _CategoryPicker(
                      selected: selectedCat,
                      onChanged: (val) => setState(() => selectedCat = val),
                    ),
                  ],
                ),
              ],
            )),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          Navigator.pop(context);
          await ref.read(dishesProvider.notifier).updateDish(
                id: dish.id,
                name: name,
                price: double.tryParse(priceCtrl.text) ?? dish.price,
                stock: double.tryParse(stockCtrl.text) ?? dish.stock,
                category: selectedCat,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✏️ Блюдо обновлено'),
                backgroundColor: AppColors.neonPurple,
              ),
            );
          }
        },
        child: const Text('Сохранить',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ─── Диалог ПРОДАЖИ ──────────────────────────────────────────────────────────
void showSellDialog(
    BuildContext context, WidgetRef ref, Dish dish, Shift shift) {
  final qtyCtrl = TextEditingController(text: '1');

  AppDialog.show(
    context: context,
    title: 'Продажа',
    titleIcon: Icons.point_of_sale,
    accentColor: AppColors.neonGreen,
    content: StatefulBuilder(builder: (ctx, setState) {
      final qty = double.tryParse(qtyCtrl.text) ?? 1;
      final total = qty * dish.price;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Инфо о блюде
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Text(AppConstants.iconFor(dish.category),
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dish.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          )),
                      Text(
                        '${dish.price.toInt()} ₸ за шт.  •  ${dish.stock.toInt()} шт. в наличии',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Счётчик
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () {
                  final current = double.tryParse(qtyCtrl.text) ?? 1;
                  if (current > 1) {
                    qtyCtrl.text = (current - 1).toInt().toString();
                    setState(() {});
                  }
                },
              ),
              Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () {
                  final current = double.tryParse(qtyCtrl.text) ?? 1;
                  if (current < dish.stock) {
                    qtyCtrl.text = (current + 1).toInt().toString();
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Итого
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Итого:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                Text(
                  '${total.toInt()} ₸',
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.bgDeep,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final qty = double.tryParse(qtyCtrl.text) ?? 1;
          if (qty <= 0) return;

          Navigator.pop(context);

          try {
            await recordSale(
              shiftId: shift.id,
              dishId: dish.id,
              quantity: qty,
              price: dish.price,
              currentStock: dish.stock,
            );
            ref.read(dishesProvider.notifier).refresh();
            ref.invalidate(currentShiftSalesProvider);

            if (context.mounted) {
              // Показываем чек
              showReceiptDialog(context, dish: dish, qty: qty);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: AppColors.neonRed,
                ),
              );
            }
          }
        },
        child: const Text('Продать',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ─── ПРЕДПРОСМОТР ЧЕКА ───────────────────────────────────────────────────────
void showReceiptDialog(
  BuildContext context, {
  required Dish dish,
  required double qty,
}) {
  final now = DateTime.now();
  final total = qty * dish.price;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
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
            // Шапка чека
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Text('🏪', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text(
                    'СТОЛОВАЯ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy  HH:mm').format(now),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Перфорация
            _ReceiptPerforation(),

            // Тело чека
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ReceiptRow(
                      label: dish.name, value: '${dish.price.toInt()} ₸'),
                  const SizedBox(height: 8),
                  _ReceiptRow(label: 'Количество', value: '${qty.toInt()} шт.'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ИТОГО',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${total.toInt()} ₸',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Перфорация снизу
            _ReceiptPerforation(),

            // Подвал
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Спасибо за покупку! 🙏',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                  ),
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

// ─── Диалог ПРИХОДА ──────────────────────────────────────────────────────────
void showAddStockDialog(BuildContext context, WidgetRef ref, Dish dish) {
  final qtyCtrl = TextEditingController(text: '10');

  AppDialog.show(
    context: context,
    title: 'Приход товара',
    titleIcon: Icons.add_box_outlined,
    accentColor: AppColors.neonGreen,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Text(AppConstants.iconFor(dish.category),
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dish.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      'Сейчас: ${dish.stock.toInt()} шт.',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DialogTextField(
          controller: qtyCtrl,
          label: 'Сколько пришло?',
          keyboardType: TextInputType.number,
          icon: Icons.add,
        ),
      ],
    ),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Отмена'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.bgDeep,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final qty = double.tryParse(qtyCtrl.text) ?? 0;
          if (qty <= 0) return;
          Navigator.pop(context);
          await ref
              .read(dishesProvider.notifier)
              .addStock(dish.id, dish.stock, qty);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📦 +${qty.toInt()} шт. · ${dish.name}'),
                backgroundColor: AppColors.neonGreen,
              ),
            );
          }
        },
        child: const Text('Добавить',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ─── Вспомогательные виджеты ─────────────────────────────────────────────────
class _CategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cats = AppConstants.categories.where((c) => c != 'Все').toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.map((cat) {
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.neonCyan.withOpacity(0.2)
                  : AppColors.bgElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.neonCyan : AppColors.borderSubtle,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${AppConstants.iconFor(cat)} $cat',
              style: TextStyle(
                color:
                    isSelected ? AppColors.neonCyan : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF555555), fontSize: 14)),
        Text(value,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
      ],
    );
  }
}

class _ReceiptPerforation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          30,
          (i) => Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: i.isEven ? const Color(0xFFEEEEEE) : Colors.white,
                  ),
                ),
              )),
    );
  }
}
