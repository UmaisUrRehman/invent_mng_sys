import 'entity.dart';

class Category extends Entity {
  String name;

  Category({
    required super.id,
    required this.name,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  @override
  String displayDetails() {
    return 'Category [ID: $id] - Name: $name';
  }

  @override
  String toString() {
    return displayDetails();
  }
}