import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../providers/shift_provider.dart';

class ShiftPanel extends ConsumerWidget {
  const ShiftPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftAsync = ref.watch(currentShiftProvider);
    final salesAsync = ref.watch(currentShiftSalesProvider);

    return shiftAsync.when(
      loading: () => const _PanelSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (shift) {
        if (shift == null) return const _ClosedPanel();
        final sales = salesAsync.value ?? [];
        final revenue = sales.fold<double>(0, (sum, s) => sum + s.total);
        final txCount = sales.length;

        return _OpenPanel(
          shift: shift,
          revenue: revenue,
          txCount: txCount,
        );
      },
    );
  }
}

// ─── Открытая смена ──────────────────────────────────────────────────────────
class _OpenPanel extends StatelessWidget {
  final Shift shift;
  final double revenue;
  final int txCount;

  const _OpenPanel({
    required this.shift,
    required this.revenue,
    required this.txCount,
  });

  @override
  Widget build(BuildContext context) {
    final duration = DateTime.now().difference(shift.startTime);
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2018), Color(0xFF0A1A12)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Пульсирующий индикатор
          _PulsingDot(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Смена открыта',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'с ${DateFormat('HH:mm').format(shift.startTime)} • ${hours}ч ${mins}м',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Метрики
          _Metric(
              label: 'Выручка',
              value: '${revenue.toInt()} ₸',
              color: AppColors.neonCyan),
          const SizedBox(width: 16),
          _Metric(
              label: 'Продаж', value: '$txCount', color: AppColors.neonPurple),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

// ─── Закрытая смена ──────────────────────────────────────────────────────────
class _ClosedPanel extends StatelessWidget {
  const _ClosedPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Смена не открыта',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const Spacer(),
          const Text(
            'Нажмите «Открыть смену»',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Скелетон загрузки ───────────────────────────────────────────────────────
class _PanelSkeleton extends StatelessWidget {
  const _PanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─── Пульсирующая точка ──────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonGreen.withOpacity(_anim.value * 0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
