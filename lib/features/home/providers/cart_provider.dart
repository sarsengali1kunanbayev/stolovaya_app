import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dishes_provider.dart';

// ─── Модель позиции корзины ───────────────────────────────────────────────────
class CartItem {
  final Dish dish;
  final int quantity;

  const CartItem({required this.dish, required this.quantity});

  double get total => dish.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(dish: dish, quantity: quantity ?? this.quantity);
}

// ─── Провайдер корзины ────────────────────────────────────────────────────────
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  // Добавить блюдо (или увеличить количество)
  void addItem(Dish dish) {
    final index = state.indexWhere((e) => e.dish.id == dish.id);
    if (index >= 0) {
      final item = state[index];
      // Не добавляем больше чем есть на складе
      if (item.quantity >= dish.stock.toInt()) return;
      final updated = List<CartItem>.from(state);
      updated[index] = item.copyWith(quantity: item.quantity + 1);
      state = updated;
    } else {
      if (dish.stock <= 0) return;
      state = [...state, CartItem(dish: dish, quantity: 1)];
    }
  }

  // Уменьшить количество (или убрать если 0)
  void removeOne(String dishId) {
    final index = state.indexWhere((e) => e.dish.id == dishId);
    if (index < 0) return;
    final item = state[index];
    if (item.quantity <= 1) {
      state = state.where((e) => e.dish.id != dishId).toList();
    } else {
      final updated = List<CartItem>.from(state);
      updated[index] = item.copyWith(quantity: item.quantity - 1);
      state = updated;
    }
  }

  // Убрать позицию полностью
  void removeItem(String dishId) {
    state = state.where((e) => e.dish.id != dishId).toList();
  }

  // Очистить корзину
  void clear() => state = [];

  // Итого
  double get total => state.fold(0, (sum, e) => sum + e.total);

  // Количество позиций
  int get itemCount => state.fold(0, (sum, e) => sum + e.quantity);
}

// ─── Удобные провайдеры ───────────────────────────────────────────────────────
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider.notifier).total;
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).itemCount;
});
