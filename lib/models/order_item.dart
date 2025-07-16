import 'package:uuid/uuid.dart';
import 'dish.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String dishId;
  final String dishName;
  final double dishPrice;
  final String? dishCategory;
  final int quantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Dish? dish; // Riferimento all'oggetto Dish completo (opzionale)

  OrderItem({
    String? id,
    String? orderId,
    required this.dishId,
    required this.dishName,
    required this.dishPrice,
    this.dishCategory = 'Generico',
    this.quantity = 1,
    this.notes,
    DateTime? createdAt,
    this.updatedAt,
    this.dish,
  })  : id = id ?? const Uuid().v4(),
        orderId = orderId ?? '',
        createdAt = createdAt ?? DateTime.now();

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'] ?? '',
      dishId: json['dish_id'],
      dishName: json['dish_name'] ?? '',
      dishPrice: (json['dish_price'] ?? 0.0).toDouble(),
      dishCategory: json['dish_category'] ?? 'Generico',
      quantity: json['quantity'] ?? 1,
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'order_id': orderId,
      'dish_id': dishId,
      'dish_name': dishName,
      'dish_price': dishPrice,
      'dish_category': dishCategory,
      'quantity': quantity,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    
    if (dish != null) {
      json['dish'] = dish!.toJson();
    }
    
    return json;
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? dishId,
    String? dishName,
    double? dishPrice,
    String? dishCategory,
    int? quantity,
    String? notes,
    Dish? dish,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      dishPrice: dishPrice ?? this.dishPrice,
      dishCategory: dishCategory ?? this.dishCategory,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      dish: dish ?? this.dish,
    );
  }
}
