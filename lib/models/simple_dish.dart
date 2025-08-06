class SimpleDish {
  final String name;
  final double price;
  final String category;

  SimpleDish({
    required this.name,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
    };
  }

  factory SimpleDish.fromJson(Map<String, dynamic> json) {
    return SimpleDish(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
    );
  }
}
