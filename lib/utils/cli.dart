import 'dart:io';

import '../models/category.dart';
import '../models/product.dart';
import '../services/file_service.dart';
import '../services/inventory.dart';
import '../services/stock_monitor.dart';

class CLI {
  final Inventory inventory;
  final FileService fileService;
  final StockMonitor stockMonitor;

  CLI({
    required this.inventory,
    required this.fileService,
    required this.stockMonitor,
  });

  Future<void> start() async {
    _setupStockMonitoring();

    await _loadInventory();

    while (true) {
      _showMainMenu();

      final choice = _readInput('Enter your choice: ');

      switch (choice) {
        case '1':
          _addProduct();
          break;

        case '2':
          _removeProduct();
          break;

        case '3':
          _updateProduct();
          break;

        case '4':
          _searchProduct();
          break;

        case '5':
          _viewProducts();
          break;

        case '6':
          await _saveInventory();
          break;

        case '7':
          await _loadInventory();
          break;

        case '8':
          _showStatistics();
          break;

        case '9':
          await _manageCategories();
          break;

        case '10':
          await _exit();
          return;

        default:
          print('\nInvalid choice. Please try again.\n');
      }
    }
  }

  // ============================================================
  // MAIN MENU
  // ============================================================

  void _showMainMenu() {
    print('\n==========================================');
    print('       INVENTORY MANAGEMENT SYSTEM        ');
    print('==========================================');
    print('1. Add Product');
    print('2. Remove Product');
    print('3. Update Product');
    print('4. Search Product');
    print('5. View All Products');
    print('6. Save Inventory');
    print('7. Load Inventory');
    print('8. Inventory Statistics');
    print('9. Manage Categories');
    print('10. Exit');
    print('==========================================');
  }

  // ============================================================
  // PRODUCT MANAGEMENT
  // ============================================================

  void _addProduct() {
    print('\n========== ADD PRODUCT ==========');

    final name = _readRequiredInput('Enter product name: ');
    final price = _readDouble('Enter product price: ');
    final quantity = _readInt('Enter product quantity: ');

    if (inventory.categoryCount == 0) {
      print('\nNo categories exist. Please create a category first.');
      return;
    }

    _displayCategories();

    final categoryId = _readInt('Enter category ID: ');

    if (!inventory.categoryExists(categoryId)) {
      print('Invalid category ID. Operation cancelled.');
      return;
    }

    final product = inventory.addProduct(
      name: name,
      price: price,
      quantity: quantity,
      categoryId: categoryId,
    );

    print('\nProduct added successfully.');
    print('Automatically assigned Product ID: ${product.id}');

    stockMonitor.checkStock(product);

    _saveInventory();
  }

  void _removeProduct() {
    print('\n========== REMOVE PRODUCT ==========');

    final id = _readInt('Enter product ID: ');

    final product = inventory.searchById(id);

    if (product == null) {
      print('Product not found.');
      return;
    }

    final category = inventory.searchCategoryById(product.categoryId);

    print('\nProduct found:');
    _displayProduct(product, category);

    final confirmation = _readInput(
      'Are you sure you want to remove this product? (y/n): ',
    );

    if (confirmation.toLowerCase() != 'y') {
      print('Operation cancelled.');
      return;
    }

    inventory.removeProduct(id);

    print('Product removed successfully.');

    _saveInventory();
  }

  void _updateProduct() {
    print('\n========== UPDATE PRODUCT ==========');

    final id = _readInt('Enter product ID: ');

    final product = inventory.searchById(id);

    if (product == null) {
      print('Product not found.');
      return;
    }

    print('\nCurrent product information:');

    final category = inventory.searchCategoryById(product.categoryId);

    _displayProduct(product, category);

    print('\nPress Enter to keep the current value.');

    final newName = _readInput('New name [${product.name}]: ');
    final newPriceInput = _readInput('New price [${product.price}]: ');
    final newQuantityInput = _readInput('New quantity [${product.quantity}]: ');

    int? newCategoryId;

    if (inventory.categoryCount > 0) {
      _displayCategories();

      final newCategoryInput = _readInput(
        'New category ID [${product.categoryId}]: ',
      );

      if (newCategoryInput.isNotEmpty) {
        newCategoryId = int.tryParse(newCategoryInput);

        if (newCategoryId == null ||
            !inventory.categoryExists(newCategoryId)) {
          print('Invalid category ID. Update cancelled.');
          return;
        }
      }
    }

    final double? newPrice =
        newPriceInput.isEmpty ? null : double.tryParse(newPriceInput);

    final int? newQuantity =
        newQuantityInput.isEmpty ? null : int.tryParse(newQuantityInput);

    if (newPriceInput.isNotEmpty && newPrice == null) {
      print('Invalid price.');
      return;
    }

    if (newQuantityInput.isNotEmpty && newQuantity == null) {
      print('Invalid quantity.');
      return;
    }

    inventory.updateProduct(
      id: id,
      name: newName.isEmpty ? null : newName,
      price: newPrice,
      quantity: newQuantity,
      categoryId: newCategoryId,
    );

    final updatedProduct = inventory.searchById(id);

    if (updatedProduct != null) {
      stockMonitor.checkStock(updatedProduct);
    }

    print('\nProduct updated successfully.');

    _saveInventory();
  }

  void _searchProduct() {
    print('\n========== SEARCH PRODUCT ==========');
    print('1. Search by ID');
    print('2. Search by Name');
    print('3. Search by Category');
    print('4. View Low Stock Products');

    final choice = _readInput('Enter search option: ');

    List<Product> results = [];

    switch (choice) {
      case '1':
        final id = _readInt('Enter product ID: ');
        final product = inventory.searchById(id);
        if (product != null) {
          results = [product];
        }
        break;

      case '2':
        final name = _readRequiredInput('Enter product name: ');
        results = inventory.searchByName(name);
        break;

      case '3':
        _displayCategories();
        final categoryId = _readInt('Enter category ID: ');
        if (!inventory.categoryExists(categoryId)) {
          print('Category not found.');
          return;
        }
        results = inventory.searchByCategory(categoryId);
        break;

      case '4':
        results = inventory.getLowStockProducts(StockMonitor.lowStockThreshold);
        break;

      default:
        print('Invalid search option.');
        return;
    }

    if (results.isEmpty) {
      print('\nNo products found.');
      return;
    }

    print('\n========== SEARCH RESULTS ==========');

    for (final product in results) {
      final category = inventory.searchCategoryById(product.categoryId);
      _displayProduct(product, category);
    }
  }

  void _viewProducts() {
    print('\n========== ALL PRODUCTS ==========');

    final products = inventory.getAllProducts();

    if (products.isEmpty) {
      print('No products available.');
      return;
    }

    for (final product in products) {
      final category = inventory.searchCategoryById(product.categoryId);
      _displayProduct(product, category);
    }
  }

  // ============================================================
  // CATEGORY MANAGEMENT
  // ============================================================

  Future<void> _manageCategories() async {
    while (true) {
      print('\n==========================================');
      print('          CATEGORY MANAGEMENT             ');
      print('==========================================');
      print('1. Add Category');
      print('2. View Categories');
      print('3. Search Category');
      print('4. Update Category');
      print('5. Remove Category');
      print('6. Back');
      print('==========================================');

      final choice = _readInput('Enter your choice: ');

      switch (choice) {
        case '1':
          _addCategory();
          break;

        case '2':
          _viewCategories();
          break;

        case '3':
          _searchCategory();
          break;

        case '4':
          _updateCategory();
          break;

        case '5':
          _removeCategory();
          break;

        case '6':
          return;

        default:
          print('Invalid choice.');
      }
    }
  }

  void _addCategory() {
    print('\n========== ADD CATEGORY ==========');

    final name = _readRequiredInput('Enter category name: ');

    if (inventory.searchCategoryByName(name) != null) {
      print('A category with this name already exists.');
      return;
    }

    final category = inventory.addCategory(name: name);

    print('\nCategory added successfully.');
    print('Automatically assigned Category ID: ${category.id}');

    _saveInventory();
  }

  void _viewCategories() {
    print('\n========== ALL CATEGORIES ==========');
    final categories = inventory.getAllCategories();

    if (categories.isEmpty) {
      print('No categories found.');
      return;
    }

    for (final category in categories) {
      final productCount = inventory.searchByCategory(category.id).length;
      print('ID: ${category.id} | Name: ${category.name} | Assigned Products: $productCount');
    }
  }

  void _searchCategory() {
    print('\n========== SEARCH CATEGORY ==========');

    final name = _readRequiredInput('Enter category name: ');

    final results = inventory.searchCategories(name);

    if (results.isEmpty) {
      print('No categories found.');
      return;
    }

    for (final category in results) {
      print('ID: ${category.id} | Name: ${category.name}');
    }
  }

  void _updateCategory() {
    print('\n========== UPDATE CATEGORY ==========');

    final id = _readInt('Enter category ID: ');
    final category = inventory.searchCategoryById(id);

    if (category == null) {
      print('Category not found.');
      return;
    }

    print('Current Category Name: ${category.name}');
    final newName = _readRequiredInput('Enter new category name: ');

    if (inventory.updateCategory(id: id, newName: newName)) {
      print('Category updated successfully.');
      _saveInventory();
    } else {
      print('Failed to update category.');
    }
  }

  void _removeCategory() {
    print('\n========== REMOVE CATEGORY ==========');

    final id = _readInt('Enter category ID: ');

    final category = inventory.searchCategoryById(id);

    if (category == null) {
      print('Category not found.');
      return;
    }

    if (inventory.isCategoryUsed(id)) {
      print('\nCannot remove this category.');
      print('The category is currently assigned to one or more products.');
      print('Remove or update those products first.');
      return;
    }

    print('\nCategory: ${category.name}');

    final confirmation = _readInput(
      'Are you sure you want to remove it? (y/n): ',
    );

    if (confirmation.toLowerCase() != 'y') {
      print('Operation cancelled.');
      return;
    }

    inventory.removeCategory(id);

    print('Category removed successfully.');

    _saveInventory();
  }

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  void _displayCategories() {
    final categories = inventory.getAllCategories();

    print('\nAvailable Categories:');

    for (final category in categories) {
      print('${category.id}. ${category.name}');
    }
  }

  void _displayProduct(Product product, Category? category) {
    print('------------------------------------------');
    print('Product ID: ${product.id}');
    print('Name: ${product.name}');
    print('Price: \$${product.price.toStringAsFixed(2)}');
    print('Quantity: ${product.quantity}');

    if (category != null) {
      print('Category: ${category.name} (ID: ${category.id})');
    } else {
      print('Category: Unknown (ID: ${product.categoryId})');
    }

    if (product.isLowStock(StockMonitor.lowStockThreshold)) {
      print('STATUS: [LOW STOCK ALERT]');
    }

    print('------------------------------------------');
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  void _showStatistics() {
    print('\n========== INVENTORY STATISTICS ==========');
    print('Total Products: ${inventory.productCount}');
    print('Total Categories: ${inventory.categoryCount}');
    print('Total Stock Units: ${inventory.totalStock}');
    print(
      'Total Inventory Value: \$${inventory.totalInventoryValue.toStringAsFixed(2)}',
    );
    final lowStock = inventory.getLowStockProducts(StockMonitor.lowStockThreshold);
    print('Low Stock Items (<= ${StockMonitor.lowStockThreshold}): ${lowStock.length}');
  }

  // ============================================================
  // FILE PERSISTENCE
  // ============================================================

  Future<void> _saveInventory() async {
    try {
      await fileService.saveInventory(
        products: inventory.getAllProducts(),
        categories: inventory.getAllCategories(),
      );

      print('Inventory saved successfully.');
    } catch (e) {
      print('Error saving inventory: $e');
    }
  }

  Future<void> _loadInventory() async {
    try {
      final data = await fileService.loadInventory();

      final categories = data['categories'] as List<Category>;
      final products = data['products'] as List<Product>;

      inventory.clear();

      inventory.addAllCategories(categories);
      inventory.addAllProducts(products);

      print('Inventory loaded successfully.');
      print(
        'Loaded ${categories.length} categories and ${products.length} products.',
      );

      stockMonitor.checkAllProducts(products);
    } catch (e) {
      print('Error loading inventory: $e');
    }
  }

  // ============================================================
  // STOCK MONITORING
  // ============================================================

  void _setupStockMonitoring() {
    stockMonitor.stockStream.listen((product) {
      final category = inventory.searchCategoryById(product.categoryId);

      print('\n');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('             LOW STOCK ALERT              ');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('Product: ${product.name}');
      print('Product ID: ${product.id}');
      print('Quantity: ${product.quantity}');

      if (category != null) {
        print('Category: ${category.name}');
      }

      print('Threshold: ${StockMonitor.lowStockThreshold}');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('\n');
    });
  }

  // ============================================================
  // EXIT
  // ============================================================

  Future<void> _exit() async {
    print('\nSaving inventory before exit...');

    await _saveInventory();

    await stockMonitor.dispose();

    print('\nThank you for using the Inventory Management System!');
  }

  // ============================================================
  // INPUT HELPERS
  // ============================================================

  String _readInput(String message) {
    while (true) {
      stdout.write(message);

      final input = stdin.readLineSync();

      if (input != null) {
        return input.trim();
      }
    }
  }

  String _readRequiredInput(String message) {
    while (true) {
      final input = _readInput(message);

      if (input.isNotEmpty) {
        return input;
      }

      print('This field cannot be empty.');
    }
  }

  int _readInt(String message) {
    while (true) {
      final input = _readInput(message);

      final value = int.tryParse(input);

      if (value != null && value >= 0) {
        return value;
      }

      print('Please enter a valid non-negative integer.');
    }
  }

  double _readDouble(String message) {
    while (true) {
      final input = _readInput(message);

      final value = double.tryParse(input);

      if (value != null && value >= 0) {
        return value;
      }

      print('Please enter a valid non-negative number.');
    }
  }
}