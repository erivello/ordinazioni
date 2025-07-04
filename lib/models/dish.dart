import 'dish_category.dart';

class Dish {
  final String name;
  final double price;
  final DishCategory category;
  int quantity;

  Dish({
    required this.name, 
    required this.price,
    required this.category,
    this.quantity = 0,
  });

  Dish copyWith({int? quantity}) {
    return Dish(
      name: name,
      price: price,
      category: category,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dish && 
      runtimeType == other.runtimeType && 
      name == other.name;

  @override
  int get hashCode => name.hashCode;

  static List<Dish> getSampleDishes() {
    return [
      // Primi
      Dish(name: 'Pasta alla Carbonara', price: 12.50, category: DishCategory.primi),
      Dish(name: 'Pasta al Pomodoro', price: 8.00, category: DishCategory.primi),
      Dish(name: 'Risotto ai Funghi', price: 10.00, category: DishCategory.primi),
      
      // Secondi
      Dish(name: 'Cotoletta alla Milanese', price: 15.00, category: DishCategory.secondi),
      Dish(name: 'Grigliata Mista', price: 18.00, category: DishCategory.secondi),
      Dish(name: 'Pollo alla Cacciatora', price: 14.00, category: DishCategory.secondi),
      
      // Contorni
      Dish(name: 'Patate Fritte', price: 4.00, category: DishCategory.contorni),
      Dish(name: 'Insalata Mista', price: 3.50, category: DishCategory.contorni),
      Dish(name: 'Verdure Grigliate', price: 4.50, category: DishCategory.contorni),
      
      // Bevande
      Dish(name: 'Acqua 0.5L', price: 1.00, category: DishCategory.bevande),
      Dish(name: 'Coca Cola 0.33L', price: 2.50, category: DishCategory.bevande),
      Dish(name: 'Vino della Casa 0.75L', price: 8.00, category: DishCategory.bevande),
      
      // Dolci
      Dish(name: 'Tiramisù', price: 5.00, category: DishCategory.dessert),
      Dish(name: 'Panna Cotta', price: 4.50, category: DishCategory.dessert),
      Dish(name: 'Torta della Nonna', price: 4.50, category: DishCategory.dessert),
    ];
  }
}
