import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dish_service.dart';
import 'edit_dish_screen.dart';

class AdminDishesScreen extends StatelessWidget {
  const AdminDishesScreen({super.key});

  void _showDeleteConfirmation(
      BuildContext context, String dishId, String dishName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Sei sicuro di voler eliminare il piatto "$dishName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Chiudi il dialog
              final messenger = ScaffoldMessenger.of(context);
              try {
                await context.read<DishService>().deleteDish(dishId);
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Piatto eliminato con successo'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'eliminazione: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dishService = Provider.of<DishService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Piatti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditDishScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dishService.loadDishes(),
          ),
        ],
      ),
      body: Consumer<DishService>(
        builder: (context, dishService, _) {
          final dishes = dishService.dishes;
          
          if (dishes.isEmpty) {
            return const Center(
              child: Text('Nessun piatto disponibile'),
            );
          }
          
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
                    '€${dish.price.toStringAsFixed(2)} • ${dish.category}\n${dish.description ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditDishScreen(dish: dish),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(
                            context, dish.id, dish.name),
                      ),
                      Switch(
                        value: dish.isAvailable,
                        onChanged: (value) async {
                          try {
                            await dishService.updateDishAvailability(dish.id, value);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${dish.name}: ${value ? 'Disponibile' : 'Non disponibile'}'),
                                  backgroundColor:
                                      value ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Errore durante l\'aggiornamento della disponibilità'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            // Lo stato verrà automaticamente aggiornato dal DishService tramite notifyListeners
                          }
                        },
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
