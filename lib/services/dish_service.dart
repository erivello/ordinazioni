import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dish.dart';
import 'dart:async';
import 'package:collection/collection.dart';

class DishService with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Dish> _dishes = [];
  
  List<Dish> get dishes => _dishes;
  
  Map<String, List<Dish>> get dishesByCategory => 
      groupBy(_dishes, (Dish dish) => dish.category);
  
  DishService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadDishes();
    _setupRealtimeUpdates();
  }
  
  Future<void> loadDishes() async {
    try {
      final data = await _supabase
          .from('dishes')
          .select()
          .order('name', ascending: true);
      
      // Mappiamo i dati in oggetti Dish
      final dishes = (data as List).map((json) => Dish.fromJson(json)).toList();
      
      // Log per verificare le categorie prima dell'ordinamento
      debugPrint('Categorie prima dell\'ordinamento:');
      for (var dish in dishes) {
        debugPrint('- ${dish.name}: ${dish.category}');
      }
      
      // Definiamo l'ordine delle categorie
      const categoryOrder = [
        'primi',
        'secondi',
        'contorni',
        'bevande',
        'dessert',
      ];
      
      // Mappa per le varianti dei nomi delle categorie
      const categoryVariants = {
        'primi': ['primo', 'primi'],
        'secondi': ['secondo', 'secondi'],
        'contorni': ['contorno', 'contorni'],
        'bevande': ['bevanda', 'bevande'],
        'dessert': ['dolce', 'dolci', 'dessert'],
      };
      
      // Funzione per ottenere l'ordine di una categoria
      int getCategoryOrder(String category) {
        final cat = category.toLowerCase().trim();
        for (int i = 0; i < categoryOrder.length; i++) {
          final variants = categoryVariants[categoryOrder[i]]!;
          if (variants.any((v) => v == cat)) {
            return i;
          }
        }
        return 999; // Categorie non riconosciute vanno in fondo
      }
      
      // Ordiniamo prima per categoria e poi per nome
      dishes.sort((a, b) {
        final aOrder = getCategoryOrder(a.category);
        final bOrder = getCategoryOrder(b.category);
        
        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        
        return a.name.compareTo(b.name);
      });
      
      // Log per verificare l'ordinamento
      debugPrint('Categorie dopo l\'ordinamento:');
      for (var dish in dishes) {
        debugPrint('- ${dish.name}: ${dish.category}');
      }
      
      // Verifichiamo se l'ordine è cambiato
      bool orderChanged = _dishes.length != dishes.length;
      if (!orderChanged) {
        for (int i = 0; i < _dishes.length; i++) {
          if (_dishes[i].id != dishes[i].id) {
            orderChanged = true;
            break;
          }
        }
      }
      
      debugPrint('Ordine cambiato: $orderChanged');
      
      _dishes = List.from(dishes); // Creiamo una nuova lista per forzare il refresh
      notifyListeners();
      
      debugPrint('Dopo notifyListeners()');
    } catch (e) {
      debugPrint('Errore durante il caricamento dei piatti: $e');
      rethrow;
    }
  }
  
  // Metodo privato per il caricamento iniziale
  Future<void> _loadDishes() => loadDishes();
  
  void _setupRealtimeUpdates() {
    try {
      _supabase
          .from('dishes')
          .stream(primaryKey: ['id'])
          .listen(
            (List<Map<String, dynamic>> data) {
              _dishes = data
                  .map((dish) => Dish.fromJson(dish))
                  .toList();
              notifyListeners();
            },
            onError: (error) {
              debugPrint('Error in realtime subscription: $error');
              // Prova a riconnetterti dopo un ritardo
              Future.delayed(const Duration(seconds: 5), _setupRealtimeUpdates);
            },
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Error setting up realtime updates: $e');
      // Prova a riconnetterti dopo un ritardo in caso di errore
      Future.delayed(const Duration(seconds: 5), _setupRealtimeUpdates);
    }
  }

  // Ottiene lo stream dei piatti
  Stream<List<Map<String, dynamic>>> getDishesStream() {
    return _supabase
        .from('dishes')
        .stream(primaryKey: ['id']);
  }

  // Ottiene la lista dei piatti
  List<Dish> getDishes() => _dishes;

  // Aggiorna la disponibilità di un piatto
  Future<void> updateDishAvailability(String id, bool isAvailable) async {
    try {
      // Esegui l'aggiornamento tramite la stored procedure
      final response = await _supabase.rpc('update_dish_availability', params: {
        'p_id': id,
        'p_is_available': isAvailable,
      });
      
      if (response == null) {
        throw Exception('Nessuna risposta dal database');
      }
      
      // Verifica lo stato dopo l'aggiornamento
      final updatedDish = await _supabase
          .from('dishes')
          .select()
          .eq('id', id)
          .single();
      
      // Aggiorna lo stato locale
      final index = _dishes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _dishes[index] = _dishes[index].copyWith(
          isAvailable: updatedDish['is_available'] as bool,
        );
        notifyListeners();
      }
      
    } catch (e) {
      debugPrint('Errore durante l\'aggiornamento della disponibilità: $e');
      rethrow;
    }
  }

  // Cerca un piatto per ID
  Dish? getDishById(String id) {
    try {
      return _dishes.firstWhere((dish) => dish.id == id);
    } catch (e) {
      return null;
    }
  }
}
