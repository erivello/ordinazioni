import 'package:uuid/uuid.dart';

class Order {
  final String id;
  final DateTime createdAt;
  final double total;
  final List<OrderItem> items;
  String? status; // es. 'pending', 'in_preparation', 'ready', 'completed'

  Order({
    String? id,
    DateTime? createdAt,
    required this.total,
    required this.items,
    this.status = 'pending',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      total: (json['total'] as num).toDouble(),
      status: json['status'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}

class OrderItem {
  final String id;
  final String dishId;
  final String dishName;
  final int quantity;
  final double price;
  final String? notes;

  OrderItem({
    String? id,
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.price,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'dishId': dishId,  // Modificato per corrispondere alla funzione SQL
      'dishName': dishName,
      'quantity': quantity,
      'price': price,
      'notes': notes,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      dishId: json['dish_id'],
      dishName: json['dish_name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      notes: json['notes'],
    );
  }
}
