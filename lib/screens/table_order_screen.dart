import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../providers/order_provider.dart';
import '../services/dish_service.dart';

class TableOrderScreen extends StatefulWidget {
  final int tableNumber;

  const TableOrderScreen({super.key, required this.tableNumber});

  @override
  State<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends State<TableOrderScreen> {
  final Map<String, int> _dishQuantities = {};

  double get _totalCost {
    final dishService = context.read<DishService>();
    return _dishQuantities.entries.fold(0.0, (sum, entry) {
      final dish = dishService.dishes.firstWhere(
        (d) => d.id == entry.key,
        orElse: () => Dish(name: '', price: 0.0, category: ''),
      );
      return sum + (dish.price * entry.value);
    });
  }

  void _incrementDish(String dishId) {
    setState(() {
      _dishQuantities[dishId] = (_dishQuantities[dishId] ?? 0) + 1;
    });
  }

  void _decrementDish(String dishId) {
    setState(() {
      final currentQuantity = _dishQuantities[dishId] ?? 0;
      if (currentQuantity > 0) {
        _dishQuantities[dishId] = currentQuantity - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dishService = Provider.of<DishService>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tavolo ${widget.tableNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_dishQuantities.isEmpty) return;

              final orderItems = _dishQuantities.entries.map((entry) {
                final dish = dishService.dishes.firstWhere(
                  (d) => d.id == entry.key,
                  orElse: () => Dish(name: '', price: 0.0, category: ''),
                );
                return OrderItem(
                  dishId: dish.id,
                  name: dish.name,
                  price: dish.price,
                  quantity: entry.value,
                );
              }).toList();

              final order = Order(
                items: orderItems,
                total: _totalCost,
                tableNumber: widget.tableNumber,
              );

              orderProvider.addOrder(order);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ordine salvato!')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dishService.dishes.length,
              itemBuilder: (context, index) {
                final dish = dishService.dishes[index];
                final quantity = _dishQuantities[dish.id] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(dish.name[0]),
                  ),
                  title: Text(dish.name),
                  subtitle: Text('€${dish.price.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => _decrementDish(dish.id),
                      ),
                      Text(quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _incrementDish(dish.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Totale:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€${_totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
