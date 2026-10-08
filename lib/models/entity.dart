abstract class Entity {
  final int id;

  Entity({required this.id});

  Map<String, dynamic> toJson();

  String displayDetails();
}
