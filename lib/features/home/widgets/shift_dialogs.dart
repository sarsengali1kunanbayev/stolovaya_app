import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../shared/dialogs/app_dialog.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/shift_provider.dart';

// ─── Открыть смену ───────────────────────────────────────────────────────────
void showOpenShiftDialog(BuildContext context, WidgetRef ref) {
  final cashCtrl = TextEditingController(text: '0');

  AppDialog.show(
    context: context,
    title: 'Открыть смену',
    titleIcon: Icons.play_circle_outline,
    accentColor: AppColors.neonGreen,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'После открытия смены вы сможете регистрировать продажи.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DialogTextField(
          controller: cashCtrl,
          label: 'Начальная наличка в кассе (₸)',
          keyboardType: TextInputType.number,
          icon: Icons.account_balance_wallet_outlined,
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
          final cash = double.tryParse(cashCtrl.text) ?? 0;
          Navigator.pop(context);
          await ref.read(currentShiftProvider.notifier).openShift(cash);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Смена открыта'),
                backgroundColor: AppColors.neonGreen,
              ),
            );
          }
        },
        child: const Text('Открыть смену',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ─── Закрыть смену ───────────────────────────────────────────────────────────
void showCloseShiftDialog(BuildContext context, WidgetRef ref, Shift shift) {
  final endCashCtrl = TextEditingController();
  final salesAsync = ref.read(currentShiftSalesProvider);
  final revenue = salesAsync.value?.fold<double>(0, (s, x) => s + x.total) ?? 0;

  AppDialog.show(
    context: context,
    title: 'Сдача смены',
    titleIcon: Icons.stop_circle_outlined,
    accentColor: AppColors.neonRed,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Итоги смены
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              _ShiftStat(
                label: 'Выручка за смену',
                value: '${revenue.toInt()} ₸',
                valueColor: AppColors.neonCyan,
              ),
              const SizedBox(height: 10),
              _ShiftStat(
                label: 'Начало смены',
                value: DateFormat('HH:mm  dd.MM').format(shift.startTime),
                valueColor: AppColors.textPrimary,
              ),
              const SizedBox(height: 10),
              _ShiftStat(
                label: 'Начальная касса',
                value: '${shift.startCash.toInt()} ₸',
                valueColor: AppColors.textPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DialogTextField(
          controller: endCashCtrl,
          label: 'Фактическая наличка в кассе (₸)',
          keyboardType: TextInputType.number,
          icon: Icons.account_balance_wallet_outlined,
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
          backgroundColor: AppColors.neonRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final endCash = double.tryParse(endCashCtrl.text) ?? 0;
          Navigator.pop(context);
          final finalRevenue =
              await ref.read(currentShiftProvider.notifier).closeShift(endCash);
          ref.invalidate(allShiftsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Смена закрыта · Выручка: ${finalRevenue.toInt()} ₸'),
                backgroundColor: AppColors.neonGreen,
              ),
            );
          }
        },
        child: const Text('Сдать смену',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

// ─── Экран истории смен ──────────────────────────────────────────────────────
class ShiftHistoryScreen extends ConsumerWidget {
  const ShiftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(allShiftsProvider);

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
          'История смен',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: shiftsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(
            child: Text('Ошибка: $e',
                style: const TextStyle(color: AppColors.neonRed))),
        data: (shifts) {
          if (shifts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Нет закрытых смен',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            itemBuilder: (context, i) => _ShiftCard(
              shift: shifts[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ShiftDetailScreen(shift: shifts[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onTap;

  const _ShiftCard({required this.shift, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = shift.endTime!.difference(shift.startTime);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long,
                  color: AppColors.neonCyan, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMMM yyyy', 'ru').format(shift.startTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('HH:mm').format(shift.startTime)} — '
                    '${DateFormat('HH:mm').format(shift.endTime!)}  •  '
                    '${hours}ч ${mins}м',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(shift.revenue ?? 0).toInt()} ₸',
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'выручка',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Детали смены ────────────────────────────────────────────────────────────
class ShiftDetailScreen extends ConsumerWidget {
  final Shift shift;

  const ShiftDetailScreen({super.key, required this.shift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(shiftSalesProvider(shift.id));

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
        title: Text(
          DateFormat('dd.MM.yyyy', 'ru').format(shift.startTime),
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Сводка смены
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              glowColor: AppColors.neonCyan,
              shimmerBorder: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _SummaryTile(
                        label: 'Выручка',
                        value: '${(shift.revenue ?? 0).toInt()} ₸',
                        color: AppColors.neonCyan,
                        icon: Icons.trending_up,
                      )),
                      Container(
                          width: 1, height: 50, color: AppColors.borderSubtle),
                      Expanded(
                          child: _SummaryTile(
                        label: 'Нач. касса',
                        value: '${shift.startCash.toInt()} ₸',
                        color: AppColors.neonPurple,
                        icon: Icons.account_balance_wallet_outlined,
                      )),
                      Container(
                          width: 1, height: 50, color: AppColors.borderSubtle),
                      Expanded(
                          child: _SummaryTile(
                        label: 'Конечная',
                        value: '${(shift.endCash ?? 0).toInt()} ₸',
                        color: AppColors.neonGreen,
                        icon: Icons.payments_outlined,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Продажи
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Продажи',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  )),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.neonCyan)),
              error: (e, _) => Center(
                  child: Text('Ошибка',
                      style: const TextStyle(color: AppColors.neonRed))),
              data: (sales) {
                if (sales.isEmpty) {
                  return const Center(
                    child: Text('Продаж нет',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (context, i) {
                    final s = sales[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.dishName ?? 'Блюдо',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            NeonBadge(
                              text: '${s.quantity.toInt()} шт.',
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${s.total.toInt()} ₸',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Вспомогательные виджеты ─────────────────────────────────────────────────
class _ShiftStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ShiftStat(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
