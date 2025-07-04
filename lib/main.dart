import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/dish.dart';
import 'models/dish_category.dart';
import 'providers/order_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => OrderProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Ordini',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const OrderScreen(),
    );
  }
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menù Sagra'),
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => _showOrderSummary(context, orderProvider),
                  ),
                  if (orderProvider.totalItems > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${orderProvider.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final dishesByCategory = _groupDishesByCategory(Dish.getSampleDishes());
          
          return ListView.builder(
            itemCount: dishesByCategory.length,
            itemBuilder: (context, index) {
              final category = dishesByCategory.keys.elementAt(index);
              final dishes = dishesByCategory[category]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  ...dishes.map((dish) {
                    final quantity = orderProvider.selectedDishes[dish.name]?.quantity ?? 0;
                    
                    return ListTile(
                      leading: _getCategoryIcon(dish.category),
                      title: Text(dish.name),
                      subtitle: Text('€${dish.price.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: quantity > 0
                                ? () => orderProvider.updateDishQuantity(dish, quantity - 1)
                                : null,
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => orderProvider.addDish(dish),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 32, thickness: 8, color: Colors.grey),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DishCategory, List<Dish>> _groupDishesByCategory(List<Dish> dishes) {
    final map = <DishCategory, List<Dish>>{};
    
    for (var dish in dishes) {
      if (!map.containsKey(dish.category)) {
        map[dish.category] = [];
      }
      map[dish.category]!.add(dish);
    }
    
    // Ordiniamo le categorie nell'ordine desiderato
    final orderedMap = <DishCategory, List<Dish>>{};
    for (var category in DishCategory.values) {
      if (map.containsKey(category)) {
        orderedMap[category] = map[category]!;
      }
    }
    
    return orderedMap;
  }
  
  Widget _getCategoryIcon(DishCategory category) {
    switch (category) {
      case DishCategory.primi:
        return const Icon(Icons.lunch_dining);
      case DishCategory.secondi:
        return const Icon(Icons.restaurant);
      case DishCategory.contorni:
        return const Icon(Icons.grass);
      case DishCategory.bevande:
        return const Icon(Icons.local_drink);
      case DishCategory.dessert:
        return const Icon(Icons.cake);
    }
  }

  void _showOrderSummary(BuildContext context, OrderProvider orderProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                final selectedDishes = orderProvider.selectedDishes.values.toList();
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Il tuo ordine',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Totale: €${orderProvider.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: selectedDishes.isEmpty
                            ? const Center(
                                child: Text('Nessun piatto selezionato'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: selectedDishes.length,
                                itemBuilder: (context, index) {
                                  final dish = selectedDishes[index];
                                  return Dismissible(
                                    key: Key('${dish.name}-$index'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      final removedDish = dish;
                                      orderProvider.removeDish(dish.name);
                                      
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${dish.name} rimosso'),
                                          action: SnackBarAction(
                                            label: 'Annulla',
                                            onPressed: () {
                                              orderProvider.addDish(removedDish);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      child: ListTile(
                                        leading: _getCategoryIcon(dish.category),
                                        title: Text(dish.name),
                                        subtitle: Text(
                                          '${dish.quantity} x €${dish.price.toStringAsFixed(2)} = '
                                          '€${(dish.quantity * dish.price).toStringAsFixed(2)}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                orderProvider.updateDishQuantity(
                                                  dish,
                                                  dish.quantity - 1,
                                                );
                                              },
                                            ),
                                            Text('${dish.quantity}'),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                orderProvider.addDish(dish);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (selectedDishes.isNotEmpty)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Azzera ordine'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    orderProvider.clear();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ordine azzerato'),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final orderTotal = orderProvider.totalCost;
                                  orderProvider.clear();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ordine inviato! Totale: €${orderTotal.toStringAsFixed(2)}'),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Conferma ordine'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
