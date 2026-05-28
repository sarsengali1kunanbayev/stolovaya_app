import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

// ─── Модели ──────────────────────────────────────────────────────────────────
class Shift {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double startCash;
  final double? endCash;
  final double? revenue;

  const Shift({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startCash,
    this.endCash,
    this.revenue,
  });

  factory Shift.fromMap(Map<String, dynamic> map) => Shift(
        id: map['id'].toString(),
        startTime: DateTime.parse(map['start_time']),
        endTime:
            map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
        startCash: (map['start_cash'] ?? 0).toDouble(),
        endCash: map['end_cash'] != null ? (map['end_cash']).toDouble() : null,
        revenue: map['revenue'] != null ? (map['revenue']).toDouble() : null,
      );

  bool get isOpen => endTime == null;
}

class Sale {
  final String id;
  final String shiftId;
  final String dishId;
  final String? dishName;
  final double quantity;
  final double price;
  final DateTime? createdAt;

  const Sale({
    required this.id,
    required this.shiftId,
    required this.dishId,
    this.dishName,
    required this.quantity,
    required this.price,
    this.createdAt,
  });

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'].toString(),
        shiftId: map['shift_id'].toString(),
        dishId: map['dish_id'].toString(),
        dishName: map['dishes'] != null ? map['dishes']['name'] : null,
        quantity: (map['quantity'] ?? 0).toDouble(),
        price: (map['price'] ?? 0).toDouble(),
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : null,
      );

  double get total => quantity * price;
}

// ─── Текущая смена ───────────────────────────────────────────────────────────
final currentShiftProvider = AsyncNotifierProvider<ShiftNotifier, Shift?>(
  ShiftNotifier.new,
);

class ShiftNotifier extends AsyncNotifier<Shift?> {
  @override
  Future<Shift?> build() => _fetchCurrentShift();

  Future<Shift?> _fetchCurrentShift() async {
    final data = await supabase
        .from('shifts')
        .select()
        .filter('end_time', 'is', null)
        .maybeSingle();
    return data != null ? Shift.fromMap(data) : null;
  }

  Future<void> openShift(double startCash) async {
    final res = await supabase.from('shifts').insert({
      'start_time': DateTime.now().toIso8601String(),
      'opened_by': supabase.auth.currentUser?.id,
      'start_cash': startCash,
    }).select();
    state = AsyncData(Shift.fromMap(res.first));
  }

  Future<double> closeShift(double endCash) async {
    final shift = state.value;
    if (shift == null) return 0;

    // Считаем выручку
    final salesData = await supabase
        .from('sales')
        .select('quantity, price')
        .eq('shift_id', shift.id);

    double revenue = 0;
    for (var s in salesData) {
      revenue += (s['quantity'] ?? 0) * (s['price'] ?? 0);
    }

    await supabase.from('shifts').update({
      'end_time': DateTime.now().toIso8601String(),
      'closed_by': supabase.auth.currentUser?.id,
      'end_cash': endCash,
      'revenue': revenue,
    }).eq('id', shift.id);

    state = const AsyncData(null);
    return revenue;
  }
}

// ─── Продажи текущей смены ───────────────────────────────────────────────────
final currentShiftSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final shift = ref.watch(currentShiftProvider).value;
  if (shift == null) return [];

  final data = await supabase
      .from('sales')
      .select('*, dishes(name)')
      .eq('shift_id', shift.id)
      .order('created_at', ascending: false);

  return (data as List).map((e) => Sale.fromMap(e)).toList();
});

// ─── Все закрытые смены ──────────────────────────────────────────────────────
final allShiftsProvider = FutureProvider<List<Shift>>((ref) async {
  final data = await supabase
      .from('shifts')
      .select()
      .not('end_time', 'is', null)
      .order('end_time', ascending: false);

  return (data as List).map((e) => Shift.fromMap(e)).toList();
});

// ─── Детали смены (продажи) ──────────────────────────────────────────────────
final shiftSalesProvider =
    FutureProvider.family<List<Sale>, String>((ref, shiftId) async {
  final data = await supabase
      .from('sales')
      .select('*, dishes(name)')
      .eq('shift_id', shiftId);

  return (data as List).map((e) => Sale.fromMap(e)).toList();
});

// ─── Продать блюдо ───────────────────────────────────────────────────────────
Future<void> recordSale({
  required String shiftId,
  required String dishId,
  required double quantity,
  required double price,
  required double currentStock,
}) async {
  if (currentStock < quantity) {
    throw Exception('Недостаточно остатка (есть: ${currentStock.toInt()} шт.)');
  }

  // Обновляем остаток
  await supabase
      .from('dishes')
      .update({'stock': currentStock - quantity}).eq('id', dishId);

  // Записываем продажу
  await supabase.from('sales').insert({
    'shift_id': shiftId,
    'dish_id': dishId,
    'quantity': quantity,
    'price': price,
  });
}
