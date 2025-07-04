import 'package:flutter/material.dart';
import '../models/dish.dart';

class OrderProvider extends ChangeNotifier {
  final Map<String, Dish> _selectedDishes = {};

  Map<String, Dish> get selectedDishes => Map.unmodifiable(_selectedDishes);

  void updateDishQuantity(Dish dish, int newQuantity) {
    if (newQuantity > 0) {
      _selectedDishes[dish.id] = dish.copyWith(quantity: newQuantity);
    } else {
      _selectedDishes.remove(dish.id);
    }
    notifyListeners();
  }

  void removeDish(String dishId) {
    _selectedDishes.remove(dishId);
    notifyListeners();
  }

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

  double get totalCost => _selectedDishes.values.fold(
        0.0,
        (sum, dish) => sum + (dish.price * dish.quantity),
      );

  int get totalItems => _selectedDishes.values.fold(
        0,
        (sum, dish) => sum + dish.quantity,
      );

  void clear() {
    _selectedDishes.clear();
    notifyListeners();
  }
}
