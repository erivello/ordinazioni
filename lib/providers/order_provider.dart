import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/dish.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final Map<String, Dish> _selectedDishes = {};
  bool _isSaving = false;
  final OrderService orderService = OrderService();
  int _tableNumber = 1;
  String? _orderNotes;

  int get tableNumber => _tableNumber;
  String? get orderNotes => _orderNotes;
  bool get isSaving => _isSaving;

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

  // Rimuove completamente un piatto dall'ordine
  void removeDish(String dishId) {
    _selectedDishes.remove(dishId);
    notifyListeners();
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
        quantity: dish.quantity,
        price: dish.price,
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
