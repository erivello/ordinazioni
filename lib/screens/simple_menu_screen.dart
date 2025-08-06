import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/simple_dish.dart';
import '../providers/simple_order_provider.dart';

class SimpleMenuScreen extends StatelessWidget {
  final List<SimpleDish> dishes;

  const SimpleMenuScreen({
    super.key,
    required this.dishes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleOrderSummaryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          final dish = dishes[index];
          return ListTile(
            title: Text(dish.name),
            subtitle: Text('€${dish.price.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.read<SimpleOrderProvider>().addDish(dish);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Aggiunto: ${dish.name}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
