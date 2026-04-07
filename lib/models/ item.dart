class Item {
  final String? id;
  final String name;
  final int quantity;
  final double price;
  final DateTime createdAt;

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.createdAt,
  });

  /// Convert Item -> Map for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert Firestore document -> Item.
  factory Item.fromMap(String id, Map<String, dynamic> map) {
    return Item(
      id: id,
      name: (map['name'] ?? '') as String,
      quantity: (map['quantity'] ?? 0) as int,
      price: (map['price'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Total value helper used by the dashboard.
  double get totalValue => quantity * price;

  /// Low stock flag used by the UI badge (enhanced feature).
  bool get isLowStock => quantity < 5;
}