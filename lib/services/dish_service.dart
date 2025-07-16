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
      
      // Controlla se il piatto esiste nella lista locale
      debugPrint('Verifica esistenza piatto nella lista locale...');
      final existingDish = _dishes.firstWhereOrNull((d) => d.id == dishId);
      if (existingDish == null) {
        debugPrint('ATTENZIONE: Piatto con ID $dishId non trovato nella lista locale');
        debugPrint('Piatti presenti: ${_dishes.map((d) => '${d.id} (${d.name})').toList()}');
        return false;
      } else {
        debugPrint('Piatto trovato: ${existingDish.name} (${existingDish.id})');
      }
      
      // Primo tentativo: eliminazione diretta
      debugPrint('\n⚡ Tentativo di ELIMINAZIONE DIRETTA del piatto...');
      try {
        final deleteResponse = await _supabase
            .from('dishes')
            .delete()
            .eq('id', dishId);
        
        debugPrint('Risposta eliminazione: $deleteResponse');
        
        // Verifica se il piatto è stato effettivamente eliminato
        final checkDish = await _supabase
            .from('dishes')
            .select()
            .eq('id', dishId)
            .maybeSingle();
            
        if (checkDish == null) {
          debugPrint('✅ Piatto rimosso con successo dal database');
          // Aggiorna la lista locale
          _dishes.removeWhere((d) => d.id == dishId);
          notifyListeners();
          return true;
        } else {
          debugPrint('❌ Il piatto è ancora presente dopo l\'eliminazione');
          debugPrint('Procedo con un approccio alternativo...');
        }
      } catch (e) {
        debugPrint('Errore durante l\'eliminazione diretta: $e');
      }
      
      // Secondo tentativo: disabilitazione
      debugPrint('\n⚡ Tentativo di DISABILITAZIONE del piatto...');
      try {
        final updateResponse = await _supabase.rpc('disable_dish', params: {'dish_id': dishId});
        debugPrint('Risposta disabilitazione: $updateResponse');
        
        // Verifica se il piatto è stato disabilitato
        final disabledDish = await _supabase
            .from('dishes')
            .select()
            .eq('id', dishId)
            .single();
            
        if (disabledDish['is_available'] == false) {
          debugPrint('✅ Piatto disabilitato con successo');
          await _loadDishes(); // Ricarica la lista completa
          return true;
        } else {
          debugPrint('❌ Impossibile disabilitare il piatto');
        }
      } catch (e) {
        debugPrint('Errore durante la disabilitazione: $e');
      }
      
      // Se siamo qui, entrambi i tentativi hanno fallito
      debugPrint('\n❌ Tutti i tentativi di eliminazione/disabilitazione hanno fallito');
      debugPrint('Motivi possibili:');
      debugPrint('1. Vincoli di chiave esterna nel database');
      debugPrint('2. Trigger che impediscono l\'aggiornamento/eliminazione');
      debugPrint('3. Problemi con i permessi RLS');
      
      // Ricarica la lista per assicurarci di avere i dati aggiornati
      await _loadDishes();
      
      // Verifica se il piatto è ancora presente
      final stillExists = _dishes.any((d) => d.id == dishId);
      debugPrint('Il piatto è ancora presente nella lista: $stillExists');
      
      return !stillExists;
      
    } catch (e, stackTrace) {
      debugPrint('ERRORE CRITICO durante l\'eliminazione del piatto:');
      debugPrint('Tipo di errore: ${e.runtimeType}');
      debugPrint('Messaggio: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (e is PostgrestException) {
        debugPrint('Dettagli errore Supabase:');
        debugPrint('- Messaggio: ${e.message}');
        debugPrint('- Dettagli: ${e.details}');
        debugPrint('- Hint: ${e.hint}');
        debugPrint('- Codice: ${e.code}');
      }
      
      rethrow;
    }
  }

  Future<void> updateDish(Dish dish) async {
    try {
      await _supabase.from('dishes').update({
        'name': dish.name,
        'price': dish.price,
        'category': dish.category,
        'description': dish.description,
        'image_url': dish.imageUrl,
        'is_available': dish.isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', dish.id);
      
      // Ricarica la lista dei piatti
      await _loadDishes();
    } catch (e) {
      debugPrint('Errore durante l\'aggiornamento del piatto: $e');
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
          .order('name');
      
      debugPrint('Dati ricevuti da Supabase: ${response.length} piatti');
      
      final newDishes = (response as List)
          .map((data) => Dish.fromJson(data))
          .toList();
      
      debugPrint('Piatti elaborati: ${newDishes.map((d) => '${d.name} (${d.id} - ${d.isAvailable ? 'disponibile' : 'non disponibile'})').toList()}');
      
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
      debugPrint('🔄 Aggiornamento disponibilità piatto: $id a $isAvailable');
      
      // Aggiornamento diretto
      final response = await _supabase
          .from('dishes')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      debugPrint('✅ Risposta aggiornamento: $response');
      
      // Aggiorna lo stato locale
      final index = _dishes.indexWhere((d) => d.id == id);
      if (index != -1) {
        _dishes[index] = _dishes[index].copyWith(
          isAvailable: isAvailable,
        );
        debugPrint('✅ Stato locale aggiornato');
      } else {
        debugPrint('⚠️ Piatto non trovato nella lista locale, ricarico...');
        await _loadDishes();
      }
      
      // Notifica i listener del cambiamento
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Errore durante l\'aggiornamento della disponibilità:');
      debugPrint('Tipo: ${e.runtimeType}');
      debugPrint('Messaggio: $e');
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
