import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../services/dish_service.dart';
import '../providers/order_provider.dart';
import 'order_summary_screen.dart';
import 'admin_dishes_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Carica i piatti all'inizializzazione
    final dishService = context.read<DishService>();
    dishService.getDishes();
  }

  // Funzione per ottenere le categorie ordinate
  Map<String, List<Dish>> getOrderedDishesByCategory(DishService dishService) {
    final Map<String, List<Dish>> result = {};
    
    // Ordina i piatti prima per sortOrder (crescente) e poi per nome
    final sortedDishes = List<Dish>.from(dishService.dishes)
      ..sort((a, b) {
        final orderComparison = a.sortOrder.compareTo(b.sortOrder);
        if (orderComparison != 0) return orderComparison;
        return a.name.compareTo(b.name); // Se sortOrder è uguale, ordina per nome
      });
    
    // Raggruppa i piatti per categoria
    for (var dish in sortedDishes) {
      result[dish.category] = [...result[dish.category] ?? [], dish];
    }
    
    // Ordina le categorie
    final orderedCategories = result.keys.toList()
      ..sort((a, b) {
        const categoryOrder = {
          'primi': 1,
          'secondi': 2,
          'contorni': 3,
          'bevande': 4,
          'dessert': 5,
        };
        
        final aOrder = categoryOrder[a.toLowerCase()] ?? 999;
        final bOrder = categoryOrder[b.toLowerCase()] ?? 999;
        return aOrder.compareTo(bOrder);
      });
    
    // Crea una nuova mappa ordinata
    final orderedResult = <String, List<Dish>>{};
    for (var category in orderedCategories) {
      orderedResult[category] = result[category]!;
    }
    
    return orderedResult;
  }

  @override
  Widget build(BuildContext context) {
    final dishService = Provider.of<DishService>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    
    // Ottieni i piatti raggruppati per categoria e ordinati
    final dishesByCategory = getOrderedDishesByCategory(dishService);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menù'),
        actions: [
          // Pulsante di aggiornamento
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Ricarica i piatti
              dishService.loadDishes();
              // Mostra un feedback visivo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu aggiornato'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // Menu a tendina per opzioni aggiuntive
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminDishesScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Area Amministrativa'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Icon(Icons.more_vert),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderSummaryScreen(),
                    ),
                  );
                },
              ),
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
          ),
        ],
      ),
      body: dishService.dishes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: dishesByCategory.length,
              itemBuilder: (context, index) {
                // Ottieni le categorie ordinate
                final categories = dishesByCategory.keys.toList()
                  ..sort((a, b) {
                    const categoryOrder = {
                      'primi': 1,
                      'secondi': 2,
                      'contorni': 3,
                      'bevande': 4,
                      'dessert': 5,
                    };
                    
                    final aOrder = categoryOrder[a.toLowerCase()] ?? 999;
                    final bOrder = categoryOrder[b.toLowerCase()] ?? 999;
                    return aOrder.compareTo(bOrder);
                  });
                
                final category = categories[index];
                final categoryDishes = dishesByCategory[category]!;
                    
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _getCategoryName(category),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...categoryDishes.map((dish) => _DishItem(dish: dish)),
                  ],
                );
              },
            ),
    );
  }

  // Metodo per ottenere il nome formattato della categoria
  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'primi':
        return 'PRIMI PIATTI';
      case 'secondi':
        return 'SECONDI PIATTI';
      case 'contorni':
        return 'CONTORNI';
      case 'bevande':
        return 'BEVANDE';
      case 'dessert':
        return 'DOLCI';
      case 'altro':
        return 'ALTRO';
      default:
        return category.toUpperCase();
    }
  }


}

class _DishItem extends StatelessWidget {
  final Dish dish;

  const _DishItem({required this.dish});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final itemQuantity = orderProvider.getQuantity(dish);
    
    return Opacity(
      opacity: dish.isAvailable ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: ListTile(
          title: Text(
            dish.name,
            style: TextStyle(
              decoration: !dish.isAvailable ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dish.description?.isNotEmpty ?? false)
                Text(dish.description!),
              if (itemQuantity > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Quantità: $itemQuantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '€${dish.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              if (dish.isAvailable) ...[
                if (itemQuantity > 0)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      orderProvider.removeItem(dish);
                    },
                  ),
                if (itemQuantity > 0)
                  Text(
                    '$itemQuantity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    orderProvider.addItem(dish);
                  },
                ),
              ] else
                const Text(
                  'ESURITO',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          onTap: !dish.isAvailable
              ? null
              : () {
                  _showDishDetails(context, dish);
                },
        ),
      ),
    );
  }

  void _showDishDetails(BuildContext context, Dish dish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dish.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dish.imageUrl != null)
              Image.network(
                dish.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            if (dish.description?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(dish.description!),
              ),
            Text(
              'Prezzo: €${dish.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CHIUDI'),
          ),
        ],
      ),
    );
  }
}
