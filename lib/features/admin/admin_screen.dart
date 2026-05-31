import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
import '../../shared/widgets/glass_card.dart';

// ─── Провайдеры статистики ───────────────────────────────────────────────────

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Все закрытые смены
  final shifts = await supabase
      .from('shifts')
      .select()
      .not('end_time', 'is', null)
      .order('start_time', ascending: false);

  // Все продажи
  final sales = await supabase.from('sales').select('*, dishes(name)');

  // Профили сотрудников
  final profiles = await supabase.from('profiles').select();

  // Общая выручка
  double totalRevenue = 0;
  for (var s in shifts) {
    totalRevenue += (s['revenue'] ?? 0).toDouble();
  }

  // Топ блюд
  final Map<String, Map<String, dynamic>> dishStats = {};
  for (var s in sales) {
    final name = s['dishes']?['name'] ?? 'Неизвестно';
    final qty = (s['quantity'] ?? 0).toDouble();
    final rev = qty * (s['price'] ?? 0).toDouble();
    if (dishStats.containsKey(name)) {
      dishStats[name]!['qty'] = (dishStats[name]!['qty'] as double) + qty;
      dishStats[name]!['revenue'] =
          (dishStats[name]!['revenue'] as double) + rev;
    } else {
      dishStats[name] = {'name': name, 'qty': qty, 'revenue': rev};
    }
  }
  final topDishes = dishStats.values.toList()
    ..sort((a, b) => (b['qty'] as double).compareTo(a['qty'] as double));

  // Выручка по дням (последние 7 дней)
  final Map<String, double> revenueByDay = {};
  final now = DateTime.now();
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final key = DateFormat('dd.MM').format(day);
    revenueByDay[key] = 0;
  }
  for (var s in shifts) {
    if (s['end_time'] != null) {
      final end = DateTime.parse(s['end_time']);
      final diff = now.difference(end).inDays;
      if (diff <= 6) {
        final key = DateFormat('dd.MM').format(end);
        revenueByDay[key] =
            (revenueByDay[key] ?? 0) + (s['revenue'] ?? 0).toDouble();
      }
    }
  }

  return {
    'totalRevenue': totalRevenue,
    'totalShifts': shifts.length,
    'totalSales': sales.length,
    'topDishes': topDishes.take(5).toList(),
    'revenueByDay': revenueByDay,
    'profiles': profiles,
    'shifts': shifts,
  };
});

// ─── Главный экран администратора ────────────────────────────────────────────
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

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
        title: const Text('Панель администратора',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(
                  decoration:
                      const BoxDecoration(gradient: AppGradients.bgRadial))),
          statsAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan)),
            error: (e, _) => Center(
                child: Text('Ошибка: $e',
                    style: const TextStyle(color: AppColors.neonRed))),
            data: (stats) => _buildContent(context, stats),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Сводка ───────────────────────────────────────────────────────
          _SectionTitle(title: 'Общая сводка', icon: Icons.analytics_outlined),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _StatCard(
              label: 'Выручка',
              value: '${(stats['totalRevenue'] as double).toInt()} ₸',
              icon: Icons.trending_up,
              color: AppColors.neonCyan,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              label: 'Смен',
              value: '${stats['totalShifts']}',
              icon: Icons.schedule,
              color: AppColors.neonPurple,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
              label: 'Продаж',
              value: '${stats['totalSales']}',
              icon: Icons.receipt_long,
              color: AppColors.neonGreen,
            )),
          ]),
          const SizedBox(height: 24),

          // ─── Выручка по дням ──────────────────────────────────────────────
          _SectionTitle(title: 'Выручка за 7 дней', icon: Icons.bar_chart),
          const SizedBox(height: 12),
          GlassCard(
            child: _RevenueChart(
              revenueByDay: stats['revenueByDay'] as Map<String, double>,
            ),
          ),
          const SizedBox(height: 24),

          // ─── Топ блюд ─────────────────────────────────────────────────────
          _SectionTitle(title: 'Топ блюд', icon: Icons.star_outline),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: (stats['topDishes'] as List).asMap().entries.map((e) {
                final i = e.key;
                final dish = e.value as Map<String, dynamic>;
                return _TopDishRow(
                  rank: i + 1,
                  name: dish['name'] as String,
                  qty: (dish['qty'] as double).toInt(),
                  revenue: (dish['revenue'] as double).toInt(),
                  isLast: i == (stats['topDishes'] as List).length - 1,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Сотрудники ───────────────────────────────────────────────────
          _SectionTitle(title: 'Сотрудники', icon: Icons.people_outline),
          const SizedBox(height: 12),
          ...(stats['profiles'] as List).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EmployeeCard(
                  profile: p,
                  shifts: (stats['shifts'] as List)
                      .where((s) => s['opened_by'] == p['id'])
                      .toList(),
                ),
              )),
          const SizedBox(height: 24),

          // ─── Последние смены ──────────────────────────────────────────────
          _SectionTitle(title: 'Последние смены', icon: Icons.history),
          const SizedBox(height: 12),
          ...(stats['shifts'] as List).take(10).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ShiftRow(shift: s),
              )),
        ],
      ),
    );
  }
}

// ─── Виджеты ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.neonCyan, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      shimmerBorder: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              )),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final Map<String, double> revenueByDay;
  const _RevenueChart({required this.revenueByDay});

  @override
  Widget build(BuildContext context) {
    final maxVal = revenueByDay.values.isEmpty
        ? 1.0
        : revenueByDay.values.reduce((a, b) => a > b ? a : b);
    final entries = revenueByDay.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((e) {
              final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (e.value > 0)
                        Text(
                          '${(e.value / 1000).toStringAsFixed(0)}к',
                          style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        height: 80 * ratio,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.neonCyan,
                              AppColors.neonCyan.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: entries
              .map((e) => Expanded(
                    child: Text(
                      e.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _TopDishRow extends StatelessWidget {
  final int rank;
  final String name;
  final int qty;
  final int revenue;
  final bool isLast;
  const _TopDishRow(
      {required this.rank,
      required this.name,
      required this.qty,
      required this.revenue,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonGreen,
      AppColors.neonOrange,
      AppColors.textSecondary,
    ];
    final color = colors[rank - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
              child: Text(
            '$rank',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 13),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(
          name,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$qty шт.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text('$revenue ₸',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ]),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final List<dynamic> shifts;
  const _EmployeeCard({required this.profile, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile['role'] == 'admin';
    final color = isAdmin ? AppColors.neonOrange : AppColors.neonCyan;

    double totalRevenue = 0;
    for (var s in shifts) {
      totalRevenue += (s['revenue'] ?? 0).toDouble();
    }

    return GlassCard(
      glowColor: color,
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
              child: Text(
            (profile['name'] ?? '?')[0].toUpperCase(),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 18),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile['name'] ?? 'Без имени',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 3),
            Row(children: [
              NeonBadge(
                text: isAdmin ? 'Администратор' : 'Продавец',
                color: color,
              ),
            ]),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${shifts.length} смен',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('${totalRevenue.toInt()} ₸',
              style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ]),
      ]),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final Map<String, dynamic> shift;
  const _ShiftRow({required this.shift});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(shift['start_time']);
    final revenue = (shift['revenue'] ?? 0).toDouble();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long,
              color: AppColors.neonCyan, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMMM yyyy', 'ru').format(start),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
            Text(DateFormat('HH:mm').format(start),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        )),
        Text('${revenue.toInt()} ₸',
            style: const TextStyle(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ]),
    );
  }
}

// NeonBadge используется из glass_card.dart
class NeonBadge extends StatelessWidget {
  final String text;
  final Color color;
  const NeonBadge(
      {super.key, required this.text, this.color = AppColors.neonCyan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
