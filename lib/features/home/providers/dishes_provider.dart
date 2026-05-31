import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

// ─── Модель блюда ────────────────────────────────────────────────────────────
class Dish {
  final String id;
  final String name;
  final double price;
  final double stock;
  final String category;

  const Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
  });

  factory Dish.fromMap(Map<String, dynamic> map) => Dish(
        id: map['id'].toString(),
        name: map['name'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        stock: (map['stock'] ?? 0).toDouble(),
        category: map['category'] ?? 'Основное',
      );

  Dish copyWith(
          {String? name, double? price, double? stock, String? category}) =>
      Dish(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        category: category ?? this.category,
      );
}

// ─── Провайдер поиска ────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── Провайдер выбранной категории ───────────────────────────────────────────
final selectedCategoryProvider = StateProvider<String>((ref) => 'Все');

// ─── Провайдер загрузки блюд ─────────────────────────────────────────────────
final dishesProvider = AsyncNotifierProvider<DishesNotifier, List<Dish>>(
  DishesNotifier.new,
);

class DishesNotifier extends AsyncNotifier<List<Dish>> {
  @override
  Future<List<Dish>> build() => _fetchDishes();

  Future<List<Dish>> _fetchDishes() async {
    final data = await supabase.from('dishes').select().order('name');
    return (data as List).map((e) => Dish.fromMap(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchDishes);
  }

  Future<void> addDish({
    required String name,
    required double price,
    required double stock,
    required String category,
  }) async {
    await supabase.from('dishes').insert({
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
    });
    await refresh();
  }

  Future<void> updateDish({
    required String id,
    required String name,
    required double price,
    required double stock,
    required String category,
  }) async {
    await supabase.from('dishes').update({
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
    }).eq('id', id);
    final current = state.value ?? [];
    state = AsyncData(current
        .map((d) => d.id == id
            ? d.copyWith(
                name: name, price: price, stock: stock, category: category)
            : d)
        .toList());
  }

  Future<void> addStock(String id, double currentStock, double qty) async {
    final newStock = currentStock + qty;
    await supabase.from('dishes').update({'stock': newStock}).eq('id', id);
    final current = state.value ?? [];
    state = AsyncData(current
        .map((d) => d.id == id ? d.copyWith(stock: newStock) : d)
        .toList());
  }

  Future<void> deleteDish(String id) async {
    // Сначала удаляем связанные продажи (foreign key constraint)
    await supabase.from('sales').delete().eq('dish_id', id);
    // Потом удаляем блюдо
    await supabase.from('dishes').delete().eq('id', id);
    // Убираем из локального состояния сразу
    final current = state.value ?? [];
    state = AsyncData(current.where((d) => d.id != id).toList());
  }
}

// ─── Производный провайдер отфильтрованных блюд ──────────────────────────────
final filteredDishesProvider = Provider<List<Dish>>((ref) {
  final dishesAsync = ref.watch(dishesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final category = ref.watch(selectedCategoryProvider);

  return dishesAsync.maybeWhen(
    data: (dishes) => dishes.where((d) {
      final nameMatch = d.name.toLowerCase().contains(query);
      final catMatch = category == 'Все' || d.category == category;
      return nameMatch && catMatch;
    }).toList(),
    orElse: () => [],
  );
});
