import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_order_provider.dart';

class SimpleOrderSummaryScreen extends StatelessWidget {
  const SimpleOrderSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riepilogo Ordine'),
      ),
      body: Consumer<SimpleOrderProvider>(
        builder: (context, order, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: order.selectedDishes.length,
                  itemBuilder: (context, index) {
                    final dish = order.selectedDishes[index];
                    return ListTile(
                      title: Text(dish.name),
                      subtitle: Text('€${dish.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          order.removeDish(dish);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rimosso: ${dish.name}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Totale:', style: TextStyle(fontSize: 20)),
                        Text(
                          '€${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: order.selectedDishes.isEmpty
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Conferma Ordine'),
                                  content: Text('Totale: €${order.total.toStringAsFixed(2)}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annulla'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        order.clearOrder();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ordine confermato!'),
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      },
                                      child: const Text('Conferma'),
                                    ),
                                  ],
                                ),
                              );
                            },
                      child: const Text('Conferma Ordine'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
