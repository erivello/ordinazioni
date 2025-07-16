import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../providers/order_provider.dart';
import 'order_summary_screen.dart';

class DishSelectionScreen extends StatefulWidget {
  const DishSelectionScreen({super.key});

  @override
  State<DishSelectionScreen> createState() => _DishSelectionScreenState();
}

class _DishSelectionScreenState extends State<DishSelectionScreen> {
  List<Dish> selectedDishes = [];
  int _selectedTable = 1; // Aggiunto per gestire il numero del tavolo
  List<Dish> availableDishes = [
    Dish(
      name: 'Pasta alla Norma',
      price: 12.0,
      category: 'Primi',
    ),
    Dish(
      name: 'Arancini',
      price: 6.0,
      category: 'Antipasti',
    ),
    Dish(
      name: 'Cannoli',
      price: 4.0,
      category: 'Dolci',
    ),
    // Add more dishes as needed
  ];

  double get totalCost {
    return selectedDishes.fold(0.0, (sum, dish) => sum + dish.price * dish.quantity);
  }

  void addDish(Dish dish) {
    setState(() {
      final existingDishIndex = selectedDishes.indexWhere((d) => d.id == dish.id);
      
      if (existingDishIndex == -1) {
        selectedDishes.add(dish.copyWith(quantity: 1));
      } else {
        final existingDish = selectedDishes[existingDishIndex];
        selectedDishes[existingDishIndex] = existingDish.copyWith(
          quantity: existingDish.quantity + 1
        );
      }
    });
  }

  void removeDish(Dish dish) {
    setState(() {
      final existingDishIndex = selectedDishes.indexWhere((d) => d.id == dish.id);
      
      if (existingDishIndex != -1) {
        final existingDish = selectedDishes[existingDishIndex];
        if (existingDish.quantity > 1) {
          selectedDishes[existingDishIndex] = existingDish.copyWith(
            quantity: existingDish.quantity - 1
          );
        } else {
          selectedDishes.removeAt(existingDishIndex);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selezione Piatti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              if (selectedDishes.isNotEmpty) {
                // Aggiorna il numero del tavolo nel provider
                final orderProvider = context.read<OrderProvider>();
                orderProvider.updateTableNumber(_selectedTable);
                
                // Naviga alla schermata di riepilogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderSummaryScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: availableDishes.length,
              itemBuilder: (context, index) {
                final dish = availableDishes[index];
                final isSelected = selectedDishes.any((d) => d.id == dish.id);

                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[100] : Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              dish.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('€ ${dish.price.toStringAsFixed(2)}'),
                            if (isSelected)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => removeDish(dish),
                                  ),
                                  Text('${dish.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => addDish(dish),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Totale: € ${totalCost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
