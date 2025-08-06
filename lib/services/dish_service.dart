import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dish.dart';
import 'dart:async';
import 'package:collection/collection.dart';

class DishService with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Dish> _dishes = [];
  bool _isLoading = false;
  
  List<Dish> get dishes => _dishes;
  bool get isLoading => _isLoading;
  
  Map<String, List<Dish>> get dishesByCategory => 
      groupBy(_dishes, (Dish dish) => dish.category);
  
  DishService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadDishes();
    _setupRealtimeUpdates();
  }
  
  Future<void> addDish(Dish dish) async {
    try {
      await _supabase.from('dishes').insert({
        'id': dish.id,
        'name': dish.name,
        'price': dish.price,
        'category': dish.category,
        'description': dish.description,
        'image_url': dish.imageUrl,
        'is_available': dish.isAvailable,
        'sort_order': dish.sortOrder,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Ricarica la lista dei piatti
      await _loadDishes();
    } catch (e) {
      debugPrint('Errore durante l\'aggiunta del piatto: $e');
      rethrow;
    }
  }

  Future<bool> deleteDish(String dishId) async {
    try {
      debugPrint('=== TENTATIVO DI ELIMINAZIONE PIATTO ===');
      debugPrint('ID piatto da eliminare: $dishId');
      
      final existingDish = _dishes.firstWhereOrNull((d) => d.id == dishId);
      if (existingDish == null) {
        return false;
      }
      
      // Primo tentativo: eliminazione diretta
      try {
        await _supabase
            .from('dishes')
            .delete()
            .eq('id', dishId);
            
        // Verifica se il piatto è stato effettivamente rimosso
        final checkDish = await _supabase
            .from('dishes')
            .select()
            .eq('id', dishId)
            .maybeSingle();
            
        if (checkDish == null) {
          _dishes.removeWhere((d) => d.id == dishId);
          notifyListeners();
          return true;
        }
      } catch (e) {
        // Continua con il prossimo approccio in caso di errore
      }
      
      // Secondo tentativo: disabilitazione
      try {
        await _supabase.rpc('disable_dish', params: {'dish_id': dishId});
        await _loadDishes();
        return true;
      } catch (e) {
        await _loadDishes();
        return !_dishes.any((d) => d.id == dishId);
      }
      
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDish(Dish dish) async {
    try {
      debugPrint('=== INIZIO AGGIORNAMENTO PIATTO ===');
      debugPrint('ID piatto: ${dish.id}');
      
      // Prova con una query SQL diretta
      try {
        final response = await _supabase.rpc('update_dish_direct', params: {
          'p_id': dish.id,
          'p_name': dish.name,
          'p_price': dish.price,
          'p_category': dish.category,
          'p_description': dish.description ?? '',
          'p_image_url': dish.imageUrl,
          'p_is_available': dish.isAvailable,
          'p_sort_order': dish.sortOrder,
        });
        
        debugPrint('Risposta da update_dish_direct: $response');
        await _loadDishes();
        debugPrint('=== FINE AGGIORNAMENTO PIATTO ===');
        return;
      } catch (e) {
        debugPrint('Errore in update_dish_direct: $e');
      }
      
      // Se arriviamo qui, il metodo diretto ha fallito, proviamo il metodo normale
      debugPrint('Tentativo con metodo normale...');
      
      // Prima verifichiamo se il piatto esiste
      final existingDish = await _supabase
          .from('dishes')
          .select()
          .eq('id', dish.id)
          .single()
          .catchError((error) {
            debugPrint('Errore nel recupero del piatto: $error');
            return null;
          });
          
      if (existingDish == null) {
        debugPrint('ERRORE: Nessun piatto trovato con ID: ${dish.id}');
        // Prova a trovare il piatto per nome
        debugPrint('Cerco il piatto per nome...');
        final dishByName = await _supabase
            .from('dishes')
            .select()
            .ilike('name', dish.name)
            .maybeSingle()
            .catchError((error) {
              debugPrint('Errore nella ricerca per nome: $error');
              return null;
            });
            
        if (dishByName != null) {
          debugPrint('Trovato piatto con nome simile, ID nel DB: ${dishByName['id']}');
          debugPrint('ID locale: ${dish.id}');
          debugPrint('Aggiorno con il nuovo ID...');
          
          // Aggiorna il piatto con l'ID corretto
          final updateResponse = await _supabase
              .from('dishes')
              .update({
                'name': dish.name,
                'price': dish.price,
                'category': dish.category,
                'description': dish.description,
                'image_url': dish.imageUrl,
                'is_available': dish.isAvailable,
                'sort_order': dish.sortOrder,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', dishByName['id'])
              .select();
              
          debugPrint('Risposta aggiornamento con ID corretto: $updateResponse');
          
          if (updateResponse != null && updateResponse.isNotEmpty) {
            debugPrint('Piatto aggiornato con successo con ID corretto');
          } else {
            debugPrint('Errore nell\'aggiornamento con ID corretto');
          }
        } else {
          debugPrint('Nessun piatto trovato neanche per nome');
        }
      } else {
        // Il piatto esiste, procedi con l'aggiornamento normale
        debugPrint('Dati da salvare: ${{
          'name': dish.name,
          'price': dish.price,
          'category': dish.category,
          'description': dish.description,
          'image_url': dish.imageUrl,
          'is_available': dish.isAvailable,
          'sort_order': dish.sortOrder,
          'updated_at': DateTime.now().toIso8601String(),
        }}');
        
        final response = await _supabase
            .from('dishes')
            .update({
              'name': dish.name,
              'price': dish.price,
              'category': dish.category,
              'description': dish.description,
              'image_url': dish.imageUrl,
              'is_available': dish.isAvailable,
              'sort_order': dish.sortOrder,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', dish.id)
            .select();
            
        debugPrint('Risposta da Supabase: $response');
        
        if (response != null && response.isNotEmpty) {
          debugPrint('Piatto aggiornato con successo: ${response[0]}');
        } else {
          debugPrint('Nessun piatto aggiornato, verifica l\'ID');
        }
      }
      
      // Ricarica la lista dei piatti in ogni caso
      await _loadDishes();
      debugPrint('=== FINE AGGIORNAMENTO PIATTO ===');
    } catch (e, stackTrace) {
      debugPrint('ERRORE durante l\'aggiornamento del piatto:');
      debugPrint('Tipo: ${e.runtimeType}');
      debugPrint('Messaggio: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }



  Future<void> _loadDishes() async {
    try {
      debugPrint('=== INIZIO CARICAMENTO PIATTI ===');
      _isLoading = true;
      notifyListeners();
      
      debugPrint('Recupero piatti da Supabase...');
      final response = await _supabase
          .from('dishes')
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);
      
      debugPrint('Dati ricevuti da Supabase: ${response.length} piatti');
      
      // Log dettagliato dei dati ricevuti
      for (var item in response) {
        debugPrint('Dati piatto ${item['name']} - sort_order: ${item['sort_order']}');
      }
      
      final newDishes = (response as List)
          .map((data) {
            debugPrint('Creazione piatto ${data['name']} con sort_order: ${data['sort_order']}');
            return Dish.fromJson(data);
          })
          .toList();
      
      debugPrint('Piatti elaborati: ${newDishes.map((d) => '${d.name} (ID:${d.id.substring(0, 5)}..., sort:${d.sortOrder})').toList()}');
      
      _dishes = newDishes;
      debugPrint('Lista piatti aggiornata con ${_dishes.length} elementi');
      
      notifyListeners();
      debugPrint('Notificati i listener del cambiamento');
      
    } catch (e, stackTrace) {
      debugPrint('ERRORE durante il caricamento dei piatti:');
      debugPrint('Tipo: ${e.runtimeType}');
      debugPrint('Messaggio: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== FINE CARICAMENTO PIATTI ===');
    }
  }
  
  // Metodo pubblico per il caricamento dei piatti
  Future<void> loadDishes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = await _supabase
          .from('dishes')
          .select()
          .order('name', ascending: true);
      
      // Mappiamo i dati in oggetti Dish
      final dishes = (data as List).map((json) => Dish.fromJson(json)).toList();
      
      // Log di debug disabilitato per ridurre il rumore nella console
      
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
      
      // Verifica se l'ordine è cambiato (senza log)
      
      _dishes = List.from(dishes); // Creiamo una nuova lista per forzare il refresh
      _isLoading = false;
      notifyListeners();
      
      debugPrint('Dopo notifyListeners()');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Errore nel caricamento dei piatti: $e');
      rethrow;
    }
  }
  

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
              _isLoading = false;
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
      await _supabase
          .from('dishes')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      // Aggiorna lo stato locale
      final index = _dishes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _dishes[index] = _dishes[index].copyWith(
          isAvailable: isAvailable,
        );
      } else {
        await _loadDishes();
      }
      
      notifyListeners();
      
    } catch (e) {
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
