import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> dishes = [];
  List<dynamic> filteredDishes = [];
  bool isLoading = true;
  dynamic currentShift;

  final TextEditingController searchController = TextEditingController();
  String selectedCategory = "Все";

  final List<String> categories = [
    "Все",
    "Горячее",
    "Салаты",
    "Напитки",
    "Выпечка",
    "Гарниры",
    "Десерты",
    "Основное"
  ];

  @override
  void initState() {
    super.initState();
    _loadDishes();
    _checkCurrentShift();
  }

  Future<void> _loadDishes() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase.from('dishes').select().order('name');
      setState(() {
        dishes = data;
        filteredDishes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      filteredDishes = dishes.where((dish) {
        final nameMatch = dish['name'].toString().toLowerCase().contains(query);
        final catMatch = selectedCategory == "Все" ||
            (dish['category']?.toString() ?? "Основное") == selectedCategory;
        return nameMatch && catMatch;
      }).toList();
    });
  }

  Future<void> _checkCurrentShift() async {
    try {
      final data = await supabase
          .from('shifts')
          .select()
          .filter('end_time', 'is', null)
          .maybeSingle();
      setState(() => currentShift = data);
    } catch (e) {
      setState(() => currentShift = null);
    }
  }

  // ==================== ДОБАВЛЕНИЕ ====================
  void _showAddDishDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: "500");
    final stockController = TextEditingController(text: "10");
    String selectedCat = "Горячее";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новое блюдо'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название')),
            TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Цена')),
            TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Остаток')),
            DropdownButtonFormField<String>(
              value: selectedCat,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: categories
                  .where((c) => c != "Все")
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => selectedCat = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await supabase.from('dishes').insert({
                'name': nameController.text.trim(),
                'price': double.tryParse(priceController.text) ?? 0,
                'stock': double.tryParse(stockController.text) ?? 0,
                'category': selectedCat,
              });
              Navigator.pop(context);
              _loadDishes();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Блюдо добавлено'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // ==================== ПРОДАЖА ====================
  void _sellDish(dynamic dish) {
    if (currentShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Откройте смену!'), backgroundColor: Colors.red));
      return;
    }

    final qtyController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Продажа: ${dish['name']}'),
        content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Количество')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 1;
              if (qty <= 0) return;

              await supabase.from('dishes').update(
                  {'stock': (dish['stock'] ?? 0) - qty}).eq('id', dish['id']);

              await supabase.from('sales').insert({
                'shift_id': currentShift['id'],
                'dish_id': dish['id'],
                'quantity': qty,
                'price': dish['price'],
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Продано ${qty.toInt()} × ${dish['name']}'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Продать'),
          ),
        ],
      ),
    );
  }

  // ==================== ПРИХОД ====================
  void _showIncomingDialog(dynamic dish) {
    final qtyController = TextEditingController(text: "10");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Приход: ${dish['name']}'),
        content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Сколько пришло?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;
              await supabase.from('dishes').update(
                  {'stock': (dish['stock'] ?? 0) + qty}).eq('id', dish['id']);
              Navigator.pop(context);
              _loadDishes();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ +${qty.toInt()} шт.'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  // ==================== УДАЛЕНИЕ ====================
  void _deleteDish(dynamic dish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить блюдо?'),
        content: Text('Вы уверены, что хотите удалить "${dish['name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.from('dishes').delete().eq('id', dish['id']);
              Navigator.pop(context);
              _loadDishes();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🗑 Блюдо удалено'),
                  backgroundColor: Colors.red));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // ==================== ОТКРЫТИЕ СМЕНЫ ====================
  void _openShift() async {
    final cashController = TextEditingController(text: "0");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Открыть смену'),
        content: TextField(
            controller: cashController,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Начальная наличка (₸)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final startCash = double.tryParse(cashController.text) ?? 0;
              final now = DateTime.now().toIso8601String();

              final res = await supabase.from('shifts').insert({
                'start_time': now,
                'opened_by': supabase.auth.currentUser?.id,
                'start_cash': startCash,
              }).select();

              setState(() => currentShift = res.first);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Смена открыта'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }

  // ==================== СДАЧА СМЕНЫ ====================
  void _closeShift() async {
    if (currentShift == null) return;

    final endCashController = TextEditingController();

    final salesData = await supabase
        .from('sales')
        .select('quantity, price')
        .eq('shift_id', currentShift['id']);

    double revenue = 0;
    for (var s in salesData) {
      revenue += (s['quantity'] ?? 0) * (s['price'] ?? 0);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сдача смены'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выручка: ${revenue.toInt()} ₸',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
                controller: endCashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Фактическая наличка в кассе')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final endCash = double.tryParse(endCashController.text) ?? 0;
              final now = DateTime.now().toIso8601String();

              await supabase.from('shifts').update({
                'end_time': now,
                'closed_by': supabase.auth.currentUser?.id,
                'end_cash': endCash,
                'revenue': revenue,
              }).eq('id', currentShift['id']);

              setState(() => currentShift = null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('✅ Смена сдана!\nВыручка: ${revenue.toInt()} ₸'),
                  backgroundColor: Colors.green));
            },
            child: const Text('Сдать смену'),
          ),
        ],
      ),
    );
  }

  // ==================== ИСТОРИЯ СМЕН ====================
  void _showAllShiftsHistory() async {
    final shifts = await supabase
        .from('shifts')
        .select()
        .not('end_time', 'is', null)
        .order('end_time', ascending: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('История смен'),
        content: SizedBox(
          width: double.maxFinite,
          height: 600,
          child: shifts.isEmpty
              ? const Center(child: Text('Пока нет закрытых смен'))
              : ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final shift = shifts[index];
                    final start = DateTime.parse(shift['start_time']);
                    final end = DateTime.parse(shift['end_time']);
                    final revenue = shift['revenue'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                            'Смена ${DateFormat('dd.MM.yyyy').format(start)}'),
                        subtitle: Text('Выручка: ${revenue.toInt()} ₸'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showShiftDetails(shift),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'))
        ],
      ),
    );
  }

  void _showShiftDetails(dynamic shift) async {
    final sales = await supabase
        .from('sales')
        .select('*, dishes(name)')
        .eq('shift_id', shift['id']);

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Детали смены'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            children: [
              Text('Выручка: ${(shift['revenue'] ?? 0).toInt()} ₸',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final s = sales[index];
                    return ListTile(
                      title: Text(s['dishes']['name']),
                      subtitle: Text('${s['quantity']} шт.'),
                      trailing:
                          Text('${(s['quantity'] * s['price']).toInt()} ₸'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Столовая'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDishes),
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showAllShiftsHistory),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => supabase.auth.signOut()),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FilterChip(
                    selected: cat == selectedCategory,
                    label: Text(cat),
                    onSelected: (selected) {
                      setState(() => selectedCategory = cat);
                      _applyFilters();
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Поиск блюда...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDishes.isEmpty
                    ? const Center(child: Text('Нет блюд'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredDishes.length,
                        itemBuilder: (context, index) {
                          final dish = filteredDishes[index];
                          final stock = (dish['stock'] ?? 0).toDouble();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () => _sellDish(dish),
                              title: Text(dish['name'],
                                  style: const TextStyle(fontSize: 20)),
                              subtitle: Text(
                                  '${dish['price']} ₸ • ${dish['category'] ?? "Основное"}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.green, size: 30),
                                    onPressed: () => _showIncomingDialog(dish),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 30),
                                    onPressed: () => _deleteDish(dish),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddDishDialog,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: currentShift == null ? _openShift : _closeShift,
            backgroundColor: currentShift == null ? Colors.green : Colors.red,
            label: Text(currentShift == null ? 'Открыть смену' : 'Сдать смену'),
            icon: Icon(currentShift == null ? Icons.play_arrow : Icons.stop),
          ),
        ],
      ),
    );
  }
}
