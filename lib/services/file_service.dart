import 'dart:convert';
import 'dart:io';

import '../models/category.dart';
import '../models/product.dart';

class FileService {
  final String defaultFilePath;

  FileService({this.defaultFilePath = 'data/inventory.json'});

  Future<void> saveInventory({
    required List<Product> products,
    required List<Category> categories,
    String? filePath,
  }) async {
    final targetPath = filePath ?? defaultFilePath;
    final file = File(targetPath);

    // Create directory if it doesn't exist
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final data = {
      'categories': categories.map((c) => c.toJson()).toList(),
      'products': products.map((p) => p.toJson()).toList(),
    };

    final encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(data);

    await file.writeAsString(jsonString);
  }

  Future<Map<String, List<dynamic>>> loadInventory({String? filePath}) async {
    final targetPath = filePath ?? defaultFilePath;
    final file = File(targetPath);

    if (!await file.exists()) {
      return {
        'categories': <Category>[],
        'products': <Product>[],
      };
    }

    final jsonString = await file.readAsString();
    if (jsonString.trim().isEmpty) {
      return {
        'categories': <Category>[],
        'products': <Product>[],
      };
    }

    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;

    final rawCategories = data['categories'] as List<dynamic>? ?? [];
    final categories = rawCategories
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();

    final rawProducts = data['products'] as List<dynamic>? ?? [];
    final products = rawProducts
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();

    return {
      'categories': categories,
      'products': products,
    };
  }
}