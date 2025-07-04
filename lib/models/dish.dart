import 'package:uuid/uuid.dart';

class Dish {
  final String id;
  final String name;
  final double price;
  final String category; // Changed from DishCategory to String
  final String? description;
  final String? imageUrl;
  int quantity;

  Dish({
    String? id,
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.imageUrl,
    this.quantity = 0,
  }) : id = id ?? const Uuid().v4();

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: (json['category'] as String?)?.toLowerCase() ?? 'primi',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      if (quantity > 0) 'quantity': quantity,
    };
  }

  Dish copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? description,
    String? imageUrl,
    int? quantity,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dish &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Metodo mantenuto per compatibilità
  static List<Dish> getSampleDishes() {
    return [
      // Primi
      Dish(name: 'Pasta alla Carbonara', price: 12.50, category: 'primi'),
      Dish(name: 'Pasta al Pomodoro', price: 8.00, category: 'primi'),
      Dish(name: 'Risotto ai Funghi', price: 10.00, category: 'primi'),
      
      // Secondi
      Dish(name: 'Cotoletta alla Milanese', price: 15.00, category: 'secondi'),
      Dish(name: 'Grigliata Mista', price: 18.00, category: 'secondi'),
      Dish(name: 'Pollo alla Cacciatora', price: 14.00, category: 'secondi'),
      
      // Contorni
      Dish(name: 'Patate Fritte', price: 4.00, category: 'contorni'),
      Dish(name: 'Insalata Mista', price: 3.50, category: 'contorni'),
      Dish(name: 'Verdure Grigliate', price: 4.50, category: 'contorni'),
      
      // Bevande
      Dish(name: 'Acqua 0.5L', price: 1.00, category: 'bevande'),
      Dish(name: 'Coca Cola 0.33L', price: 2.50, category: 'bevande'),
      Dish(name: 'Vino della Casa 0.75L', price: 8.00, category: 'bevande'),
      
      // Dolci
      Dish(name: 'Tiramisù', price: 5.00, category: 'dessert'),
      Dish(name: 'Panna Cotta', price: 4.50, category: 'dessert'),
      Dish(name: 'Torta della Nonna', price: 4.50, category: 'dessert'),
    ];
  }
}
