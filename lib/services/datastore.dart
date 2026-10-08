import '../models/entity.dart';

class DataStore<T extends Entity> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
  }

  void addAll(List<T> items) {
    _items.addAll(items);
  }

  bool remove(T item) {
    return _items.remove(item);
  }

  bool removeById(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items.removeAt(index);
      return true;
    }
    return false;
  }

  T? getById(int id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  bool exists(int id) {
    return _items.any((item) => item.id == id);
  }

  List<T> getAll() {
    return List.unmodifiable(_items);
  }

  List<T> where(bool Function(T item) predicate) {
    return _items.where(predicate).toList();
  }

  void clear() {
    _items.clear();
  }

  int get count => _items.length;
}