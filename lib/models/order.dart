import 'package:uuid/uuid.dart';
import 'order_item.dart';

class Order {
  final String id;
  final DateTime createdAt;
  final double total;
  final List<OrderItem> items;
  final int tableNumber;
  final String? notes;
  String? status; // 'new', 'in_preparation', 'ready', 'completed', 'cancelled'

  Order({
    String? id,
    DateTime? createdAt,
    required this.total,
    required this.items,
    required this.tableNumber,
    this.notes,
    this.status = 'new',
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'status': status,
      'table_number': tableNumber,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      total: (json['total'] as num).toDouble(),
      status: json['status'] ?? 'new',
      tableNumber: json['table_number'] as int? ?? 0,
      notes: json['notes'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}

// OrderItem model has been moved to order_item.dart
