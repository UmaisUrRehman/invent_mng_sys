import 'entity.dart';

class Product extends Entity {
  String name;
  double price;
  int quantity;
  int categoryId;

  Product({
    required super.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.categoryId,
  });

  bool isLowStock(int threshold) => quantity <= threshold;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'categoryId': categoryId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      categoryId: json['categoryId'] as int,
    );
  }

  @override
  String displayDetails() {
    return 'Product [ID: $id] - $name | Price: \$${price.toStringAsFixed(2)} | Qty: $quantity | Category ID: $categoryId';
  }

  @override
  String toString() {
    return displayDetails();
  }
}