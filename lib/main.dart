import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/dish.dart';
import 'models/order.dart';
import 'providers/order_provider.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Get Supabase credentials from environment
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('Error: Missing Supabase credentials in .env file');
  }

  try {
    debugPrint('Initializing Supabase...');
    
    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: false,
    );
    
    debugPrint('Supabase initialized successfully');
    
    // Test connection
    try {
      final response = await Supabase.instance.client
          .from('dishes')
          .select('count')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      debugPrint('Supabase connected: $response');
    } catch (e) {
      debugPrint('Warning: Could not connect to Supabase: $e');
    }
  } catch (e, stackTrace) {
    debugPrint('Error initializing Supabase: $e\n$stackTrace');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        Provider(create: (_) => MenuService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sagra di San Lorenzo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const OrderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<Map<String, List<Dish>>> _dishesByCategoryFuture;
  final MenuService _menuService = MenuService();

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  void _loadDishes() {
    try {
      setState(() {
        _dishesByCategoryFuture = _menuService.getDishesGroupedByCategory();
      });
    } catch (e) {
      debugPrint('Error loading dishes: $e');
      setState(() {
        _dishesByCategoryFuture = Future.error('Errore nel caricamento del menù');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Menù Sagra San Lorenzo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDishes,
              ),
              Stack(
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
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
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
              ),
            ],
          ),
          body: _buildDishList(),
        );
      },
    );
  }

  Widget _buildDishList() {
    return FutureBuilder<Map<String, List<Dish>>>(
      future: _dishesByCategoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Errore: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDishes,
                  child: const Text('Riprova'),
                ),
              ],
            ),
          );
        }

        final dishesByCategory = snapshot.data;
        if (dishesByCategory == null || dishesByCategory.isEmpty) {
          return const Center(child: Text('Nessun piatto disponibile'));
        }

        return ListView(
          children: [
            ...dishesByCategory.entries.map(
              (entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        _getCategoryIcon(entry.key),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map((dish) => _buildDishItem(context, dish)),
                  const Divider(height: 1),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDishItem(BuildContext context, Dish dish) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final existingDish = orderProvider.selectedDishes[dish.id];
        final quantity = existingDish?.quantity ?? 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: _getCategoryIcon(dish.category),
            title: Text(dish.name),
            subtitle: Text('€${dish.price.toStringAsFixed(2)} • ${dish.description ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: quantity > 0
                      ? () => orderProvider.updateDishQuantity(dish, quantity - 1)
                      : null,
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    quantity > 0 ? '$quantity' : '0',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () => orderProvider.addDish(dish),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Icon _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('primo') || lowerCategory.contains('primi')) {
      return const Icon(Icons.lunch_dining);
    } else if (lowerCategory.contains('secondo') || lowerCategory.contains('secondi')) {
      return const Icon(Icons.set_meal);
    } else if (lowerCategory.contains('contorno') || lowerCategory.contains('contorni')) {
      return const Icon(Icons.grass);
    } else if (lowerCategory.contains('bevanda') || lowerCategory.contains('bevande')) {
      return const Icon(Icons.local_drink);
    } else if (lowerCategory.contains('dolce') || lowerCategory.contains('dessert')) {
      return const Icon(Icons.cake);
    } else if (lowerCategory.contains('antipasto') || lowerCategory.contains('antipasti')) {
      return const Icon(Icons.restaurant_menu);
    } else if (lowerCategory.contains('pizza')) {
      return const Icon(Icons.local_pizza);
    } else if (lowerCategory.contains('pane')) {
      return const Icon(Icons.breakfast_dining);
    }
    return const Icon(Icons.fastfood);
  }

  Future<void> _confirmOrder(BuildContext context, OrderProvider orderProvider, double orderTotal) async {
    try {
      final orderService = OrderService();
      
      // Crea l'ordine
      final order = Order(
        total: orderTotal,
        items: orderProvider.selectedDishes.entries.map((entry) {
          final dish = entry.value;
          return OrderItem(
            dishId: dish.id,
            dishName: dish.name,
            quantity: dish.quantity,
            price: dish.price,
          );
        }).toList(),
      );

      // Salva l'ordine su Supabase
      await orderService.saveOrder(order);
      
      // Svuota il carrello
      orderProvider.clear();
      
      if (!context.mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ordine inviato con successo! ID: ${order.id}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il salvataggio dell\'ordine: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderSummary(BuildContext context, OrderProvider orderProvider) {
    if (orderProvider.totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il carrello è vuoto')),
      );
      return;
    }

    bool isSubmitting = false;
    final orderTotal = orderProvider.totalCost;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Riepilogo Ordine',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...orderProvider.selectedDishes.entries.map((entry) {
                  final dish = entry.value;
                  final quantity = dish.quantity;
                  return ListTile(
                    leading: _getCategoryIcon(dish.category),
                    title: Text(dish.name),
                    subtitle: Text('€${dish.price.toStringAsFixed(2)} x $quantity'),
                    trailing: Text(
                      '€${(dish.price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Totale:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '€${orderTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              Navigator.pop(context);
                              orderProvider.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ordine annullato')),
                              );
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Annulla'),
                    ),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setState(() => isSubmitting = true);
                              await _confirmOrder(context, orderProvider, orderTotal);
                              if (context.mounted) {
                                setState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Conferma Ordine'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
