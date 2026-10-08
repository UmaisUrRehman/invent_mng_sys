import 'dart:async';

import '../models/product.dart';

class StockMonitor {
  static const int lowStockThreshold = 5;
  final int threshold;

  final StreamController<Product> _stockController =
      StreamController<Product>.broadcast();

  StockMonitor({this.threshold = lowStockThreshold});

  Stream<Product> get stockStream => _stockController.stream;

  void checkStock(Product product) {
    if (product.isLowStock(threshold)) {
      _stockController.add(product);
    }
  }

  void checkAllProducts(List<Product> products) {
    for (final product in products) {
      checkStock(product);
    }
  }

  Future<void> dispose() async {
    await _stockController.close();
  }
}