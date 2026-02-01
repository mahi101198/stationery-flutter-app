import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

/// Product service following enterprise schema
class ProductService extends GetxController {
  static ProductService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('product_details');
  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  // PRODUCT METHODS

  /// Get all products with optional filters
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    ProductStatus? status,
    String? searchQuery,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _productsCollection;

      // Apply filters
      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      // Search by name (case-insensitive)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThan: '${searchQuery}z');
      }

      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      log('❌ Error fetching products: $e');
      throw 'Failed to fetch products. Please try again.';
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      return await getProducts(
        categoryId: categoryId,
        status: ProductStatus.active,
      );
    } catch (e) {
      log('❌ Error fetching products by category: $e');
      throw 'Failed to fetch products. Please try again.';
    }
  }

  /// Get featured products
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    try {
      final query = await _productsCollection
          .where('status', isEqualTo: ProductStatus.active.name)
          .where('discount', isGreaterThan: 0)
          .orderBy('discount', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      log('❌ Error fetching featured products: $e');
      throw 'Failed to fetch featured products. Please try again.';
    }
  }

  /// Search products
  Future<List<ProductModel>> searchProducts(String searchQuery) async {
    try {
      if (searchQuery.isEmpty) return [];

      // Search in both name and tags
      final nameQuery = await _productsCollection
          .where('status', isEqualTo: ProductStatus.active.name)
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThan: '${searchQuery}z')
          .limit(20)
          .get();

      final tagsQuery = await _productsCollection
          .where('status', isEqualTo: ProductStatus.active.name)
          .where('tags', arrayContains: searchQuery.toLowerCase())
          .limit(20)
          .get();

      // Combine and deduplicate results
      final Set<String> seenIds = {};
      final List<ProductModel> results = [];

      for (final doc in [...nameQuery.docs, ...tagsQuery.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          results.add(ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>));
        }
      }

      return results;
    } catch (e) {
      log('❌ Error searching products: $e');
      throw 'Failed to search products. Please try again.';
    }
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      log('❌ Error fetching product: $e');
      throw 'Failed to fetch product. Please try again.';
    }
  }

  /// Get products by IDs
  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];

      // Firestore 'in' query has a limit of 10 items
      final List<ProductModel> products = [];
      
      for (int i = 0; i < productIds.length; i += 10) {
        final chunk = productIds.skip(i).take(10).toList();
        
        final query = await _productsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        
        products.addAll(
          query.docs.map((doc) => ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList(),
        );
      }

      return products;
    } catch (e) {
      log('❌ Error fetching products by IDs: $e');
      throw 'Failed to fetch products. Please try again.';
    }
  }

  /// Create product (admin only)
  Future<String> createProduct(ProductModel product) async {
    try {
      final docRef = await _productsCollection.add(product.toFirestore());
      log('✅ Product created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('❌ Error creating product: $e');
      throw 'Failed to create product. Please try again.';
    }
  }

  /// Update product (admin only)
  Future<void> updateProduct(ProductModel product) async {
    try {
      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _productsCollection.doc(product.productId).update(updatedProduct.toFirestore());
      log('✅ Product updated successfully: ${product.productId}');
    } catch (e) {
      log('❌ Error updating product: $e');
      throw 'Failed to update product. Please try again.';
    }
  }

  /// Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _productsCollection.doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'status': newStock > 0 ? ProductStatus.active.name : ProductStatus.out_of_stock.name,
      });
      log('✅ Product stock updated: $productId -> $newStock');
    } catch (e) {
      log('❌ Error updating product stock: $e');
      throw 'Failed to update product stock. Please try again.';
    }
  }

  /// Delete product (admin only)
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
      log('✅ Product deleted successfully: $productId');
    } catch (e) {
      log('❌ Error deleting product: $e');
      throw 'Failed to delete product. Please try again.';
    }
  }

  /// Get products stream for real-time updates
  Stream<List<ProductModel>> getProductsStream({
    String? categoryId,
    ProductStatus? status,
    int? limit,
  }) {
    try {
      Query query = _productsCollection;

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => ProductModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList(),
      );
    } catch (e) {
      log('❌ Error creating products stream: $e');
      return Stream.value([]);
    }
  }

  // CATEGORY METHODS

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final query = await _categoriesCollection
          .orderBy('createdAt', descending: false)
          .get();

      return query.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('❌ Error fetching categories: $e');
      throw 'Failed to fetch categories. Please try again.';
    }
  }

  /// Get parent categories (no parent category)
  Future<List<CategoryModel>> getParentCategories() async {
    try {
      final query = await _categoriesCollection
          .where('parentCategoryId', isNull: true)
          .orderBy('createdAt', descending: false)
          .get();

      return query.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('❌ Error fetching parent categories: $e');
      throw 'Failed to fetch categories. Please try again.';
    }
  }

  /// Get subcategories by parent ID
  Future<List<CategoryModel>> getSubcategories(String parentCategoryId) async {
    try {
      final query = await _categoriesCollection
          .where('parentCategoryId', isEqualTo: parentCategoryId)
          .orderBy('createdAt', descending: false)
          .get();

      return query.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('❌ Error fetching subcategories: $e');
      throw 'Failed to fetch subcategories. Please try again.';
    }
  }

  /// Get category by ID
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await _categoriesCollection.doc(categoryId).get();
      
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      log('❌ Error fetching category: $e');
      throw 'Failed to fetch category. Please try again.';
    }
  }

  /// Create category (admin only)
  Future<String> createCategory(CategoryModel category) async {
    try {
      final docRef = await _categoriesCollection.add(category.toFirestore());
      log('✅ Category created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('❌ Error creating category: $e');
      throw 'Failed to create category. Please try again.';
    }
  }

  /// Update category (admin only)
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoriesCollection.doc(category.id).update(category.toFirestore());
      log('✅ Category updated successfully: ${category.id}');
    } catch (e) {
      log('❌ Error updating category: $e');
      throw 'Failed to update category. Please try again.';
    }
  }

  /// Delete category (admin only)
  Future<void> deleteCategory(String categoryId) async {
    try {
      // Check if category has products
      final productsQuery = await _productsCollection
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();

      if (productsQuery.docs.isNotEmpty) {
        throw 'Cannot delete category. It has products associated with it.';
      }

      // Check if category has subcategories
      final subcategoriesQuery = await _categoriesCollection
          .where('parentCategoryId', isEqualTo: categoryId)
          .limit(1)
          .get();

      if (subcategoriesQuery.docs.isNotEmpty) {
        throw 'Cannot delete category. It has subcategories associated with it.';
      }

      await _categoriesCollection.doc(categoryId).delete();
      log('✅ Category deleted successfully: $categoryId');
    } catch (e) {
      log('❌ Error deleting category: $e');
      throw e is String ? e : 'Failed to delete category. Please try again.';
    }
  }

  /// Get categories stream for real-time updates
  Stream<List<CategoryModel>> getCategoriesStream() {
    try {
      return _categoriesCollection
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => 
            snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      log('❌ Error creating categories stream: $e');
      return Stream.value([]);
    }
  }

  // SKU-BASED METHODS FOR CART INTEGRATION

  /// Get product by SKU ID from product_details collection
  /// Returns the product containing the specified SKU
  Future<ProductModel?> getProductBySKUId(String skuId) async {
    try {
      if (skuId.isEmpty) return null;

      log('🔍 Fetching product for SKU: $skuId');

      // Query product_details collection
      // Note: This queries all products and filters in-memory
      // For better performance, consider adding a SKU index in Firestore
      final querySnapshot = await _firestore
          .collection('product_details')
          .get();

      for (final doc in querySnapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        
        // Check if this product contains the SKU
        final hasSKU = product.productSkus.any((sku) => sku.skuId == skuId);
        
        if (hasSKU) {
          log('✅ Found product for SKU $skuId: ${product.productId}');
          log('   ├─ Title: ${product.title}');
          log('   ├─ Main Image URL: ${product.media.mainImage}');
          log('   ├─ Display Image: ${product.displayImage}');
          log('   └─ Image Empty: ${product.displayImage.isEmpty}');
          return product;
        }
      }

      log('⚠️ No product found for SKU: $skuId');
      return null;
    } catch (e) {
      log('❌ Error fetching product by SKU ID: $e');
      return null;
    }
  }

  /// Get products by multiple SKU IDs from product_details collection
  /// Returns list of products containing the specified SKUs
  /// Note: productId field in cart items now stores SKU IDs
  Future<List<ProductModel>> getProductsBySKUIds(List<String> skuIds) async {
    try {
      if (skuIds.isEmpty) return [];

      log('🔍 Fetching products for ${skuIds.length} SKUs');

      final List<ProductModel> products = [];
      final Set<String> seenProductIds = {};

      // Fetch products for each SKU
      for (final skuId in skuIds) {
        final product = await getProductBySKUId(skuId);
        
        if (product != null && !seenProductIds.contains(product.productId)) {
          products.add(product);
          seenProductIds.add(product.productId);
        }
      }

      log('✅ Fetched ${products.length} unique products for ${skuIds.length} SKUs');
      return products;
    } catch (e) {
      log('❌ Error fetching products by SKU IDs: $e');
      return [];
    }
  }

  /// Get product details from product_details collection
  /// This is the new primary method for fetching product details
  Future<ProductModel?> getProductDetails(String productId) async {
    try {
      if (productId.isEmpty) return null;

      log('🔍 Fetching product details: $productId');

      final doc = await _firestore
          .collection('product_details')
          .doc(productId)
          .get();

      if (doc.exists) {
        final product = ProductModel.fromFirestore(doc);
        log('✅ Product details fetched: ${product.title}');
        return product;
      }

      log('⚠️ Product not found: $productId');
      return null;
    } catch (e) {
      log('❌ Error fetching product details: $e');
      return null;
    }
  }

  @override
  void onReady() {
    super.onReady();
    log('ProductService initialized with enterprise schema');
  }
}
