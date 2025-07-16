import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/dish.dart';
import '../models/order_item.dart';
import '../models/order.dart' show Order;
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final Map<String, Dish> _selectedDishes = {};
  bool _isSaving = false;
  final OrderService orderService = OrderService();
  int _tableNumber = 1;
  String? _orderNotes;
  Order? _currentOrder;

  int get tableNumber => _tableNumber;
  String? get orderNotes => _orderNotes;
  bool get isSaving => _isSaving;
  Order? get currentOrder => _currentOrder;

  void updateTableNumber(int number) {
    _tableNumber = number;
    notifyListeners();
  }

  void updateOrderNotes(String? notes) {
    _orderNotes = notes;
    notifyListeners();
  }

  Map<String, Dish> get selectedDishes => Map.unmodifiable(_selectedDishes);

  // Restituisce il totale dell'ordine
  double get totalAmount {
    return _selectedDishes.values.fold(
      0.0, 
      (sum, dish) => sum + (dish.price * dish.quantity)
    );
  }

  // Restituisce la quantità di un piatto nell'ordine
  int getQuantity(Dish dish) {
    return _selectedDishes[dish.id]?.quantity ?? 0;
  }

  // Aggiunge un piatto all'ordine (alias di addDish per compatibilità)
  void addItem(Dish dish) {
    addDish(dish);
  }

  // Rimuove un'unità di un piatto dall'ordine
  void removeItem(Dish dish) {
    final existingDish = _selectedDishes[dish.id];
    if (existingDish != null) {
      if (existingDish.quantity > 1) {
        _selectedDishes[dish.id] = dish.copyWith(
          quantity: existingDish.quantity - 1,
        );
      } else {
        _selectedDishes.remove(dish.id);
      }
      notifyListeners();
    }
  }

  // Aggiorna la quantità di un piatto
  void updateDishQuantity(Dish dish, int newQuantity) {
    if (newQuantity > 0) {
      _selectedDishes[dish.id] = dish.copyWith(quantity: newQuantity);
    } else {
      _selectedDishes.remove(dish.id);
    }
    notifyListeners();
  }

  // Metodo alternativo per rimuovere un piatto
  void removeDishAlternative(String dishId) {
    debugPrint('=== RIMOZIONE ALTERNATIVA ===');
    debugPrint('ID da rimuovere: "$dishId"');
    
    // Crea una nuova mappa senza il piatto da rimuovere
    final newMap = Map<String, Dish>.from(_selectedDishes);
    
    // Prova a rimuovere l'ID in vari modi
    final wasRemoved = newMap.remove(dishId) != null;
    
    if (wasRemoved) {
      // Aggiorna la mappa esistente
      _selectedDishes.clear();
      _selectedDishes.addAll(newMap);
      
      debugPrint('✅ Piatto rimosso con successo (metodo alternativo)');
      debugPrint('Nuovi piatti: ${_selectedDishes.keys}');
      notifyListeners();
    } else {
      debugPrint('❌ Impossibile rimuovere il piatto con ID: $dishId');
      debugPrint('Piatti attuali: ${_selectedDishes.keys}');
    }
  }
  
  // Rimuove completamente un piatto dall'ordine
  bool removeDish(String dishId) {
    try {
      debugPrint('=== RIMOZIONE PIATTO ===');
      debugPrint('ID da rimuovere: "$dishId" (tipo: ${dishId.runtimeType}, lunghezza: ${dishId.length})');
      
      // Stampa tutti gli ID presenti per il debug
      debugPrint('ID presenti nella mappa:');
      for (final id in _selectedDishes.keys) {
        debugPrint('- "$id" (tipo: ${id.runtimeType}, lunghezza: ${id.length})');
      }
      
      // Prova a rimuovere l'ID esatto
      if (_selectedDishes.containsKey(dishId)) {
        debugPrint('✅ Trovato corrispondenza esatta, rimozione in corso...');
        _selectedDishes.remove(dishId);
        debugPrint('✅ Piatto rimosso con successo');
        notifyListeners();
        return true;
      }
      
      // Se non trovato, prova a rimuovere senza considerare maiuscole/minuscole
      final matchingKey = _selectedDishes.keys.firstWhere(
        (key) => key.toString().toLowerCase() == dishId.toLowerCase(),
        orElse: () => '',
      );
      
      if (matchingKey.isNotEmpty) {
        debugPrint('✅ Trovata corrispondenza case-insensitive, rimozione in corso...');
        _selectedDishes.remove(matchingKey);
        debugPrint('✅ Piatto rimosso con successo (case-insensitive)');
        notifyListeners();
        return true;
      }
      
      debugPrint('❌ Nessuna corrispondenza trovata per l\'ID: $dishId');
      return false;
    } catch (e) {
      debugPrint('Errore durante la rimozione del piatto: $e');
      return false;
    }
  }

  // Aggiunge un piatto all'ordine
  void addDish(Dish dish) {
    final existingDish = _selectedDishes[dish.id];
    if (existingDish != null) {
      _selectedDishes[dish.id] = dish.copyWith(
        quantity: existingDish.quantity + 1,
      );
    } else {
      _selectedDishes[dish.id] = dish.copyWith(quantity: 1);
    }
    notifyListeners();
  }

  // Calcola il costo totale dell'ordine
  double get totalCost => _selectedDishes.values.fold(
        0.0,
        (sum, dish) => sum + (dish.price * dish.quantity),
      );

  // Imposta l'ordine corrente
  void setOrder(Order order) {
    _currentOrder = order;
    _selectedDishes.clear();
    
    for (final item in order.items) {
      // Crea un nuovo piatto con i dati dall'ordine
      final dish = Dish(
        id: item.dishId,
        name: item.dishName,
        price: item.dishPrice,
        category: item.dishCategory ?? 'Generico',
        isAvailable: true,
        description: item.notes ?? '',
      );
      
      _selectedDishes[item.dishId] = dish.copyWith(quantity: item.quantity);
    }
    
    _tableNumber = order.tableNumber;
    _orderNotes = order.notes;
    notifyListeners();
  }

  // Conta il numero totale di articoli nell'ordine
  int get totalItems => _selectedDishes.values.fold(
        0,
        (sum, dish) => sum + dish.quantity,
      );

  // Svuota l'ordine e resetta i campi
  void clearOrder() {
    _selectedDishes.clear();
    _tableNumber = 1;  // Resetta a tavolo 1
    _orderNotes = null;  // Cancella le note
    notifyListeners();
  }

  // Stato di caricamento

  // Notifica i listener che lo stato è cambiato
  void _notifyListeners() => notifyListeners();

  // Conferma il pagamento e salva l'ordine
  Future<Order> confirmPayment() async {
    if (_selectedDishes.isEmpty) {
      throw Exception('Impossibile confermare un ordine vuoto');
    }
    
    // Imposta lo stato di salvataggio
    _isSaving = true;
    _notifyListeners();
    
    try {
      final orderService = OrderService();
      
      // Verifica la connessione a Supabase
      final isConnected = await orderService.checkConnection();
      if (!isConnected) {
        throw Exception('Nessuna connessione al database. Verifica la tua connessione internet.');
      }
      
      // Converti i piatti in OrderItem
      final orderItems = _selectedDishes.values.map((dish) => OrderItem(
        id: const Uuid().v4(),
        dishId: dish.id,
        dishName: dish.name,
        dishPrice: dish.price,
        quantity: dish.quantity,
        dishCategory: dish.category,
      )).toList();
      
      // Crea l'ordine
      final order = Order(
        total: totalAmount,
        items: orderItems,
        tableNumber: _tableNumber,
        notes: _orderNotes,
        status: 'pending',
      );
      
      // Salva l'ordine su Supabase
      await orderService.saveOrder(order);
      
      // Svuota l'ordine locale
      clearOrder();
      
      debugPrint('Ordine salvato con successo: ${order.id}');
      
      return order; // Restituisci l'ordine salvato
    } catch (e) {
      debugPrint('Errore durante il salvataggio dell\'ordine: $e');
      rethrow;
    } finally {
      // Ripristina lo stato di salvataggio
      _isSaving = false;
      _notifyListeners();
    }
  }
  
  // Verifica se un piatto è già nell'ordine
  bool containsDish(String dishId) {
    return _selectedDishes.containsKey(dishId);
  }
  
  // Ottiene un piatto dall'ordine
  Dish? getDish(String dishId) {
    return _selectedDishes[dishId];
  }
}
