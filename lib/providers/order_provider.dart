import 'package:flutter/material.dart';
import '../models/dish.dart';

class OrderProvider extends ChangeNotifier {
  final Map<String, Dish> _selectedDishes = {};

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

  // Svuota l'ordine
  void clearOrder() {
    _selectedDishes.clear();
    notifyListeners();
  }

  // Conferma il pagamento e svuota l'ordine
  Future<void> confirmPayment() async {
    // Qui potresti aggiungere la logica per salvare l'ordine nel database
    await Future.delayed(const Duration(milliseconds: 500)); // Simula un'operazione asincrona
    clearOrder();
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
