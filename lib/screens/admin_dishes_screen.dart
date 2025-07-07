import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dish_service.dart';

class AdminDishesScreen extends StatelessWidget {
  const AdminDishesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dishService = Provider.of<DishService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Piatti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dishService.loadDishes(),
          ),
        ],
      ),
      body: Consumer<DishService>(
        builder: (context, dishService, _) {
          final dishes = dishService.dishes;
          
          return ListView.builder(
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: dish.isAvailable ? null : Colors.grey[200],
                child: ListTile(
                  title: Text(
                    dish.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: dish.isAvailable ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '€${dish.price.toStringAsFixed(2)} • ${dish.category}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dish.isAvailable ? 'Disponibile' : 'Non disponibile',
                        style: TextStyle(
                          color: dish.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: dish.isAvailable,
                        onChanged: (value) async {
                          try {
                            await dishService.updateDishAvailability(dish.id, value);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${dish.name}: ${value ? 'Disponibile' : 'Non disponibile'}'),
                                  backgroundColor: value ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Errore durante l\'aggiornamento: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Errore durante l\'aggiornamento'),
                                  backgroundColor: Colors.red,
                                  action: SnackBarAction(
                                    label: 'Riprova',
                                    onPressed: () => dishService.updateDishAvailability(dish.id, value),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        activeColor: Colors.green,
                        activeTrackColor: Colors.green[200],
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.red[200],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
