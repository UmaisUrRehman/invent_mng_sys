import 'dart:io';
import 'package:inventory_management_system/models/category.dart';
import 'package:inventory_management_system/models/product.dart';
import 'package:inventory_management_system/services/datastore.dart';
import 'package:inventory_management_system/services/file_service.dart';
import 'package:inventory_management_system/services/inventory.dart';
import 'package:inventory_management_system/services/stock_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('Category Unit Tests', () {
    test('Create category and verify properties', () {
      final category = Category(id: 1, name: 'Electronics');
      expect(category.id, equals(1));
      expect(category.name, equals('Electronics'));
      expect(category.displayDetails(), contains('Electronics'));
    });

    test('Category JSON serialization and deserialization', () {
      final category = Category(id: 10, name: 'Books');
      final json = category.toJson();
      expect(json['id'], equals(10));
      expect(json['name'], equals('Books'));

      final fromJson = Category.fromJson(json);
      expect(fromJson.id, equals(10));
      expect(fromJson.name, equals('Books'));
    });
  });

  group('Product Unit Tests', () {
    test('Create product and verify low stock condition', () {
      final product = Product(
        id: 101,
        name: 'Laptop',
        price: 999.99,
        quantity: 3,
        categoryId: 1,
      );

      expect(product.id, equals(101));
      expect(product.name, equals('Laptop'));
      expect(product.price, equals(999.99));
      expect(product.quantity, equals(3));
      expect(product.categoryId, equals(1));
      expect(product.isLowStock(5), isTrue);
      expect(product.isLowStock(2), isFalse);
    });

    test('Product JSON serialization and deserialization', () {
      final product = Product(
        id: 202,
        name: 'Wireless Mouse',
        price: 25.50,
        quantity: 20,
        categoryId: 2,
      );

      final json = product.toJson();
      expect(json['id'], equals(202));
      expect(json['name'], equals('Wireless Mouse'));
      expect(json['price'], equals(25.50));
      expect(json['quantity'], equals(20));
      expect(json['categoryId'], equals(2));

      final deserialized = Product.fromJson(json);
      expect(deserialized.id, equals(202));
      expect(deserialized.name, equals('Wireless Mouse'));
      expect(deserialized.price, equals(25.50));
      expect(deserialized.quantity, equals(20));
    });
  });

  group('Generic DataStore Tests', () {
    test('DataStore operations with Category entities', () {
      final store = DataStore<Category>();
      final cat1 = Category(id: 1, name: 'Electronics');
      final cat2 = Category(id: 2, name: 'Books');

      store.add(cat1);
      store.add(cat2);
      expect(store.count, equals(2));
      expect(store.getById(1)?.name, equals('Electronics'));
      expect(store.exists(2), isTrue);

      store.removeById(1);
      expect(store.count, equals(1));
      expect(store.getById(1), isNull);
    });

    test('DataStore operations with Product entities', () {
      final store = DataStore<Product>();
      final prod1 = Product(id: 1, name: 'Item A', price: 10, quantity: 5, categoryId: 1);
      final prod2 = Product(id: 2, name: 'Item B', price: 20, quantity: 15, categoryId: 1);

      store.add(prod1);
      store.add(prod2);
      expect(store.count, equals(2));

      final filtered = store.where((p) => p.price > 15);
      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('Item B'));
    });
  });

  group('Inventory Management Integration Tests', () {
    late Inventory inventory;

    setUp(() {
      inventory = Inventory();
    });

    test('Category Creation & Search Test', () {
      final category = inventory.addCategory(name: 'Electronics');
      expect(inventory.categoryCount, equals(1));
      expect(category.name, equals('Electronics'));
      expect(category.id, equals(1));

      final found = inventory.searchCategoryByName('electronics');
      expect(found, isNotNull);
      expect(found!.id, equals(1));

      final searchResults = inventory.searchCategories('Elec');
      expect(searchResults.length, equals(1));
    });

    test('Product Creation Test', () {
      final cat = inventory.addCategory(name: 'Electronics');
      final initialCount = inventory.productCount;

      final product = inventory.addProduct(
        name: 'Laptop',
        price: 1200.0,
        quantity: 10,
        categoryId: cat.id,
      );

      expect(inventory.productCount, equals(initialCount + 1));
      expect(product.name, equals('Laptop'));
      expect(product.price, equals(1200.0));
      expect(product.quantity, equals(10));
    });

    test('Product Search Test', () {
      final cat1 = inventory.addCategory(name: 'Electronics');
      final cat2 = inventory.addCategory(name: 'Books');

      inventory.addProduct(name: 'Gaming Laptop', price: 1500, quantity: 5, categoryId: cat1.id);
      inventory.addProduct(name: 'Mouse', price: 20, quantity: 50, categoryId: cat1.id);
      inventory.addProduct(name: 'Dart Book', price: 30, quantity: 15, categoryId: cat2.id);

      final searchLaptop = inventory.searchByName('laptop');
      expect(searchLaptop.length, equals(1));
      expect(searchLaptop.first.name, equals('Gaming Laptop'));

      final searchCategory1 = inventory.searchByCategory(cat1.id);
      expect(searchCategory1.length, equals(2));
    });

    test('Product Update Test', () {
      final cat = inventory.addCategory(name: 'Electronics');
      final product = inventory.addProduct(
        name: 'Monitor',
        price: 300.0,
        quantity: 10,
        categoryId: cat.id,
      );

      final updated = inventory.updateProduct(
        id: product.id,
        quantity: 15,
        price: 280.0,
      );

      expect(updated, isTrue);

      final updatedProduct = inventory.searchById(product.id);
      expect(updatedProduct?.quantity, equals(15));
      expect(updatedProduct?.price, equals(280.0));
    });

    test('Product Removal Test', () {
      final cat = inventory.addCategory(name: 'Electronics');
      inventory.addProduct(name: 'Keyboard', price: 50, quantity: 12, categoryId: cat.id, customId: 101);

      expect(inventory.productExists(101), isTrue);

      final removed = inventory.removeProduct(101);
      expect(removed, isTrue);
      expect(inventory.productExists(101), isFalse);
      expect(inventory.searchById(101), isNull);
    });

    test('Category Deletion Validation', () {
      final cat = inventory.addCategory(name: 'Hardware');
      inventory.addProduct(name: 'RAM 16GB', price: 80, quantity: 5, categoryId: cat.id);

      // Attempting to remove category assigned to product should fail
      final removed = inventory.removeCategory(cat.id);
      expect(removed, isFalse);

      // Remove product first, then category removal succeeds
      inventory.clearProducts();
      final removedAfter = inventory.removeCategory(cat.id);
      expect(removedAfter, isTrue);
    });

    test('Inventory Calculations & Metrics', () {
      final cat = inventory.addCategory(name: 'General');
      inventory.addProduct(name: 'Item A', price: 10.0, quantity: 5, categoryId: cat.id); // 50.0
      inventory.addProduct(name: 'Item B', price: 20.0, quantity: 3, categoryId: cat.id); // 60.0

      expect(inventory.totalStock, equals(8));
      expect(inventory.totalInventoryValue, equals(110.0));
    });
  });

  group('Async JSON Persistence Tests', () {
    late Directory tempDir;
    late String tempFilePath;
    late FileService fileService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('inventory_test_');
      tempFilePath = '${tempDir.path}/test_inventory.json';
      fileService = FileService(defaultFilePath: tempFilePath);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Save and Load Inventory', () async {
      final categories = [
        Category(id: 1, name: 'Electronics'),
        Category(id: 2, name: 'Furniture'),
      ];

      final products = [
        Product(id: 1, name: 'Desk', price: 150.0, quantity: 4, categoryId: 2),
        Product(id: 2, name: 'Phone', price: 800.0, quantity: 12, categoryId: 1),
      ];

      await fileService.saveInventory(
        products: products,
        categories: categories,
        filePath: tempFilePath,
      );

      final file = File(tempFilePath);
      expect(await file.exists(), isTrue);

      final loaded = await fileService.loadInventory(filePath: tempFilePath);

      final loadedCategories = loaded['categories'] as List<Category>;
      final loadedProducts = loaded['products'] as List<Product>;

      expect(loadedCategories.length, equals(2));
      expect(loadedCategories[0].name, equals('Electronics'));
      expect(loadedCategories[1].name, equals('Furniture'));

      expect(loadedProducts.length, equals(2));
      expect(loadedProducts[0].name, equals('Desk'));
      expect(loadedProducts[1].price, equals(800.0));
    });
  });

  group('Stream-based Stock Monitoring Tests', () {
    late StockMonitor monitor;

    setUp(() {
      monitor = StockMonitor(threshold: 5);
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('Low Stock Alert Test for quantity <= threshold', () async {
      final lowStockProduct = Product(
        id: 1,
        name: 'SSD 1TB',
        price: 90.0,
        quantity: 3, // <= 5
        categoryId: 1,
      );

      final normalStockProduct = Product(
        id: 2,
        name: 'HDD 2TB',
        price: 60.0,
        quantity: 20, // > 5
        categoryId: 1,
      );

      final emittedAlerts = <Product>[];

      final subscription = monitor.stockStream.listen((product) {
        emittedAlerts.add(product);
      });

      monitor.checkStock(normalStockProduct);
      monitor.checkStock(lowStockProduct);

      await Future.delayed(Duration(milliseconds: 50));

      expect(emittedAlerts.length, equals(1));
      expect(emittedAlerts.first.id, equals(1));
      expect(emittedAlerts.first.name, equals('SSD 1TB'));

      await subscription.cancel();
    });
  });
}