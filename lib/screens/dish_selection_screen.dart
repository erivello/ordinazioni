import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../models/order_item.dart';
import '../models/order.dart' show Order;
import '../providers/order_provider.dart';
import '../services/dish_service.dart';
import 'order_summary_screen.dart';

class DishSelectionScreen extends StatefulWidget {
  const DishSelectionScreen({super.key});

  @override
  State<DishSelectionScreen> createState() => _DishSelectionScreenState();
}

class _DishSelectionScreenState extends State<DishSelectionScreen> {
  final List<Dish> _selectedDishes = [];
  int _selectedTable = 1;
  final TextEditingController _notesController = TextEditingController();
  
  void _proceedToCheckout() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    // Calcola il totale dei piatti selezionati
    double total = 0;
    final orderItems = <OrderItem>[];
    
    for (final dish in _selectedDishes) {
      if (dish.quantity > 0) {
        total += dish.price * dish.quantity;
        orderItems.add(OrderItem(
          dishId: dish.id,
          dishName: dish.name,
          dishPrice: dish.price,
          dishCategory: dish.category,
          quantity: dish.quantity,
        ));
      }
    }
    
    // Crea l'ordine con i piatti selezionati
    final order = Order(
      total: total,
      items: orderItems,
      tableNumber: _selectedTable,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    
    // Imposta l'ordine nel provider
    orderProvider.setOrder(order);
    
    // Naviga alla schermata di riepilogo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderSummaryScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Carica i piatti all'inizializzazione
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dishService = context.read<DishService>();
      dishService.loadDishes();
    });
  }

  // Ottiene i piatti raggruppati per categoria
  Map<String, List<Dish>> get dishesByCategory {
    final dishService = context.watch<DishService>();
    return dishService.dishesByCategory;
  }
  
  // Calcola il costo totale
  double get totalCost {
    return _selectedDishes.fold(
      0.0, 
      (sum, dish) => sum + (dish.price * dish.quantity)
    );
  }

  // Aggiunge un piatto all'ordine
  void _addDish(Dish dish) {
    setState(() {
      final existingDishIndex = _selectedDishes.indexWhere((d) => d.id == dish.id);
      
      if (existingDishIndex == -1) {
        _selectedDishes.add(dish.copyWith(quantity: 1));
      } else {
        final existingDish = _selectedDishes[existingDishIndex];
        _selectedDishes[existingDishIndex] = existingDish.copyWith(
          quantity: existingDish.quantity + 1
        );
      }
    });
  }

  // Rimuove un piatto dall'ordine
  void _removeDish(Dish dish) {
    setState(() {
      final existingDishIndex = _selectedDishes.indexWhere((d) => d.id == dish.id);
      
      if (existingDishIndex != -1) {
        final existingDish = _selectedDishes[existingDishIndex];
        if (existingDish.quantity > 1) {
          _selectedDishes[existingDishIndex] = existingDish.copyWith(
            quantity: existingDish.quantity - 1
          );
        } else {
          _selectedDishes.removeAt(existingDishIndex);
        }
      }
    });
  }
  
  // Ottiene la quantità di un piatto nell'ordine
  int _getDishQuantity(Dish dish) {
    final existingDish = _selectedDishes.firstWhere(
      (d) => d.id == dish.id,
      orElse: () => dish.copyWith(quantity: 0),
    );
    return existingDish.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final dishService = context.watch<DishService>();
    
    if (dishService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selezione Piatti'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _selectedDishes.isEmpty ? null : _proceedToCheckout,
              ),
              if (_selectedDishes.isNotEmpty)
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
                      _selectedDishes.fold<int>(
                        0, (sum, dish) => sum + dish.quantity).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Selettore tavolo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int>(
              value: _selectedTable,
              decoration: const InputDecoration(
                labelText: 'Tavolo',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(20, (index) => index + 1)
                  .map((number) => DropdownMenuItem(
                        value: number,
                        child: Text('Tavolo $number'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTable = value;
                  });
                  orderProvider.updateTableNumber(value);
                }
              },
            ),
          ),
          
          // Note per l'ordine
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note per la cucina (opzionale)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: dishService.dishes.length,
              itemBuilder: (context, index) {
                final dish = dishService.dishes[index];
                final isSelected = _selectedDishes.any((d) => d.id == dish.id);

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
                                    onPressed: () => _removeDish(dish),
                                  ),
                                  Text('${_getDishQuantity(dish)}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _addDish(dish),
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
