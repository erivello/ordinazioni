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
      debugPrint('Inizio caricamento piatti da Supabase...');
      
      // Prima carichiamo tutti i piatti
      final data = await _supabase
          .from('dishes')
          .select()
          .order('name', ascending: true);
          
      debugPrint('Dati ricevuti da Supabase: $data');
      
      // Mappiamo i dati in oggetti Dish
      final dishes = (data as List).map((json) {
        debugPrint('Mappatura piatto: ${json['name']} - Disponibile: ${json['is_available']}');
        return Dish.fromJson(json);
      }).toList();
      
      // Ordiniamo le categorie nell'ordine specificato
      const categoryOrder = {
        'primi': 1,
        'secondi': 2,
        'contorni': 3,
        'bevande': 4,
        'dessert': 5,
      };
      
      // Ordiniamo prima per categoria e poi per nome
      dishes.sort((a, b) {
        final aOrder = categoryOrder[a.category.toLowerCase()] ?? 999;
        final bOrder = categoryOrder[b.category.toLowerCase()] ?? 999;
        
        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        
        return a.name.compareTo(b.name);
      });
      
      _dishes = dishes;
      debugPrint('Totale piatti caricati: ${_dishes.length}');
      notifyListeners();
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
      debugPrint('=== INIZIO AGGIORNAMENTO ===');
      debugPrint('Piatto ID: $id');
      debugPrint('Nuovo stato: $isAvailable');
      
      // 1. Verifica stato attuale dal database
      final currentDish = await _supabase
          .from('dishes')
          .select()
          .eq('id', id)
          .single();
      debugPrint('Stato attuale dal DB: ${currentDish['is_available']}');
      
      // 2. Esegui l'aggiornamento con query SQL diretta
      debugPrint('Esecuzione aggiornamento con query SQL...');
      final response = await _supabase.rpc('update_dish_availability', params: {
        'p_id': id,
        'p_is_available': isAvailable,
      });
      
      debugPrint('Risposta aggiornamento: $response');
      
      if (response == null) {
        debugPrint('ATTENZIONE: Nessuna risposta dal database!');
        throw Exception('Nessuna risposta dal database');
      }
      
      // 3. Verifica lo stato dopo l'aggiornamento
      final updatedDish = await _supabase
          .from('dishes')
          .select()
          .eq('id', id)
          .single();
      
      debugPrint('Verifica finale - Stato dal DB: ${updatedDish['is_available']}');
      
      // 4. Aggiorna lo stato locale
      final index = _dishes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _dishes[index] = _dishes[index].copyWith(
          isAvailable: updatedDish['is_available'] as bool,
        );
        debugPrint('Aggiornato localmente: ${_dishes[index].name} a ${_dishes[index].isAvailable}');
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
