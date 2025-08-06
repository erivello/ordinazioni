import 'package:flutter/foundation.dart';
import '../models/simple_dish.dart';

class SimpleOrderProvider with ChangeNotifier {
  final List<SimpleDish> _selectedDishes = [];

  List<SimpleDish> get selectedDishes => List.unmodifiable(_selectedDishes);
  double get total => _selectedDishes.fold(0, (sum, dish) => sum + dish.price);

  void addDish(SimpleDish dish) {
    _selectedDishes.add(dish);
    notifyListeners();
  }

  void removeDish(SimpleDish dish) {
    _selectedDishes.remove(dish);
    notifyListeners();
  }

  void clearOrder() {
    _selectedDishes.clear();
    notifyListeners();
  }
}
