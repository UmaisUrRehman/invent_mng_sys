import '../models/category.dart';
import '../models/product.dart';
import 'datastore.dart';

class Inventory {
  final DataStore<Product> _productStore = DataStore<Product>();
  final DataStore<Category> _categoryStore = DataStore<Category>();

  // ============================================================
  // AUTOMATIC ID GENERATION
  // ============================================================

  int get nextProductId {
    if (_productStore.count == 0) {
      return 1;
    }
    int highestId = 0;
    for (final product in _productStore.getAll()) {
      if (product.id > highestId) {
        highestId = product.id;
      }
    }
    return highestId + 1;
  }

  int get nextCategoryId {
    if (_categoryStore.count == 0) {
      return 1;
    }
    int highestId = 0;
    for (final category in _categoryStore.getAll()) {
      if (category.id > highestId) {
        highestId = category.id;
      }
    }
    return highestId + 1;
  }

  // ============================================================
  // PRODUCT MANAGEMENT
  // ============================================================

  Product addProduct({
    required String name,
    required double price,
    required int quantity,
    required int categoryId,
    int? customId,
  }) {
    final id = customId ?? nextProductId;
    final product = Product(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      categoryId: categoryId,
    );
    _productStore.add(product);
    return product;
  }

  bool removeProduct(int id) {
    return _productStore.removeById(id);
  }

  Product? searchById(int id) {
    return _productStore.getById(id);
  }

  List<Product> searchByName(String name) {
    final searchTerm = name.toLowerCase();
    return _productStore.where((product) {
      return product.name.toLowerCase().contains(searchTerm);
    });
  }

  List<Product> searchByCategory(int categoryId) {
    return _productStore.where((product) {
      return product.categoryId == categoryId;
    });
  }

  bool updateProduct({
    required int id,
    String? name,
    double? price,
    int? quantity,
    int? categoryId,
  }) {
    final product = searchById(id);
    if (product == null) {
      return false;
    }

    if (name != null && name.trim().isNotEmpty) {
      product.name = name.trim();
    }
    if (price != null) {
      product.price = price;
    }
    if (quantity != null) {
      product.quantity = quantity;
    }
    if (categoryId != null && categoryExists(categoryId)) {
      product.categoryId = categoryId;
    }

    return true;
  }

  List<Product> getAllProducts() {
    return _productStore.getAll();
  }

  List<Product> getLowStockProducts(int threshold) {
    return _productStore.where((product) => product.isLowStock(threshold));
  }

  int get productCount => _productStore.count;

  int get totalStock {
    int total = 0;
    for (final product in _productStore.getAll()) {
      total += product.quantity;
    }
    return total;
  }

  double get totalInventoryValue {
    double total = 0;
    for (final product in _productStore.getAll()) {
      total += product.price * product.quantity;
    }
    return total;
  }

  void addAllProducts(List<Product> products) {
    _productStore.addAll(products);
  }

  // ============================================================
  // CATEGORY MANAGEMENT
  // ============================================================

  Category addCategory({
    required String name,
    int? customId,
  }) {
    final id = customId ?? nextCategoryId;
    final category = Category(
      id: id,
      name: name.trim(),
    );
    _categoryStore.add(category);
    return category;
  }

  bool removeCategory(int id) {
    final category = searchCategoryById(id);
    if (category == null) {
      return false;
    }
    if (isCategoryUsed(id)) {
      return false;
    }
    return _categoryStore.remove(category);
  }

  bool updateCategory({
    required int id,
    required String newName,
  }) {
    final category = searchCategoryById(id);
    if (category == null || newName.trim().isEmpty) {
      return false;
    }
    category.name = newName.trim();
    return true;
  }

  Category? searchCategoryById(int id) {
    return _categoryStore.getById(id);
  }

  Category? searchCategoryByName(String name) {
    final searchTerm = name.toLowerCase().trim();
    for (final category in _categoryStore.getAll()) {
      if (category.name.toLowerCase() == searchTerm) {
        return category;
      }
    }
    return null;
  }

  List<Category> searchCategories(String name) {
    final searchTerm = name.toLowerCase().trim();
    return _categoryStore.where((category) {
      return category.name.toLowerCase().contains(searchTerm);
    });
  }

  List<Category> getAllCategories() {
    return _categoryStore.getAll();
  }

  int get categoryCount => _categoryStore.count;

  void addAllCategories(List<Category> categories) {
    _categoryStore.addAll(categories);
  }

  // ============================================================
  // VALIDATION & UTILITIES
  // ============================================================

  bool categoryExists(int id) {
    return _categoryStore.exists(id);
  }

  bool productExists(int id) {
    return _productStore.exists(id);
  }

  bool isCategoryUsed(int categoryId) {
    return searchByCategory(categoryId).isNotEmpty;
  }

  void clearProducts() {
    _productStore.clear();
  }

  void clearCategories() {
    _categoryStore.clear();
  }

  void clear() {
    clearProducts();
    clearCategories();
  }
}