import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';
import 'package:rps_stationery/data/services/product_service.dart';

/// Helper class to store section product metadata
class _SectionProductRef {
  final String productId;
  final int rank;
  final double? priceOverride;

  const _SectionProductRef({
    required this.productId,
    required this.rank,
    this.priceOverride,
  });
}

class HomeSectionRepo extends GetxController {
  static HomeSectionRepo get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch home sections for a specific category
  Future<List<HomeSectionData>> fetchHomeSectionsForCategory(String categoryId) async {
    try {
      print('🏠 HomeSectionRepo: Fetching home sections for category: $categoryId');
      
      final docRef = _db.collection('home_sections').doc(categoryId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        print('⚠️ HomeSectionRepo: No home sections found for category: $categoryId');
        return [];
      }
      
      final data = docSnapshot.data()!;
      print('📊 HomeSectionRepo: Retrieved home section document for $categoryId');
      
      List<HomeSectionData> sections = [];
      
      // Get sections metadata
      final sectionsList = data['sections'] as List<dynamic>? ?? [];
      print('📋 HomeSectionRepo: Found ${sectionsList.length} section types');
      
      for (var sectionData in sectionsList) {
        final sectionId = sectionData['sectionId'] as String;
        final sectionType = sectionData['type'] as String;
        final title = sectionData['title'] as String;
        
        print('🔍 HomeSectionRepo: Processing section: $sectionId ($sectionType)');
        
        // Fetch products for this section from subcollection
        final products = await _fetchSectionProducts(categoryId, sectionId);
        
        sections.add(HomeSectionData(
          sectionId: sectionId,
          title: title,
          type: sectionType,
          products: products,
          categoryId: categoryId,
        ));
        
        print('✅ HomeSectionRepo: Added section $sectionId with ${products.length} products');
      }
      
      print('🎉 HomeSectionRepo: Successfully loaded ${sections.length} sections for $categoryId');
      return sections;
      
    } catch (e, stackTrace) {
      print('❌ HomeSectionRepo: Error fetching home sections for $categoryId: $e');
      print('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Resolve products using cache-first, Firestore-fallback strategy
  Future<List<ProductModel>> _resolveProducts(List<_SectionProductRef> productRefs) async {
    if (productRefs.isEmpty) return [];

    final productIds = productRefs.map((ref) => ref.productId).toList();
    print('🔍 HomeSectionRepo: Resolving ${productIds.length} products with cache-first strategy');

    List<ProductModel> resolvedProducts = [];

    try {
      // Try ProductCacheService first (cache-first approach)
      if (Get.isRegistered<ProductCacheService>()) {
        print('📱 HomeSectionRepo: Attempting cache-first resolution via ProductCacheService');
        try {
          resolvedProducts = await ProductCacheService.instance.getProductsByIds(productIds);
          print('✅ HomeSectionRepo: Cache resolved ${resolvedProducts.length}/${productIds.length} products');
        } catch (e) {
          print('⚠️ HomeSectionRepo: ProductCacheService failed: $e');
        }
      }

      // If cache didn't resolve all products, try ProductService (batched Firestore)
      if (resolvedProducts.length < productIds.length) {
        final resolvedIds = resolvedProducts.map((p) => p.productId).toSet();
        final missingIds = productIds.where((id) => !resolvedIds.contains(id)).toList();
        
        if (missingIds.isNotEmpty) {
          print('🌐 HomeSectionRepo: Fetching ${missingIds.length} missing products via ProductService');
          try {
            final additionalProducts = await ProductService.instance.getProductsByIds(missingIds);
            resolvedProducts.addAll(additionalProducts);
            print('✅ HomeSectionRepo: ProductService resolved ${additionalProducts.length} additional products');
          } catch (e) {
            print('⚠️ HomeSectionRepo: ProductService failed: $e');
          }
        }
      }

      // Create a map for quick lookup and preserve order
      final productMap = <String, ProductModel>{};
      for (final product in resolvedProducts) {
        productMap[product.productId] = product;
      }

      // Build final list in original order with price overrides applied
      final List<ProductModel> finalProducts = [];
      for (final ref in productRefs) {
        final product = productMap[ref.productId];
        if (product != null) {
          // Apply price override if present
          final finalProduct = ref.priceOverride != null
              ? product.copyWith(price: ref.priceOverride!)
              : product;
          
          finalProducts.add(finalProduct);
          
          if (ref.priceOverride != null) {
            print('💰 HomeSectionRepo: Applied price override ${ref.priceOverride} for ${product.name}');
          }
        } else {
          print('⚠️ HomeSectionRepo: Product not found: ${ref.productId}');
        }
      }

      print('🎉 HomeSectionRepo: Successfully resolved ${finalProducts.length}/${productRefs.length} products');
      return finalProducts;

    } catch (e, stackTrace) {
      print('❌ HomeSectionRepo: Error in _resolveProducts: $e');
      print('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch products for a specific section from subcollection
  /// Optimized version: fetches only product IDs and ranks, then uses batched resolution
  Future<List<ProductModel>> _fetchSectionProducts(String categoryId, String sectionId) async {
    try {
      print('📦 HomeSectionRepo: Fetching product references for section: $categoryId/$sectionId');
      
      final querySnapshot = await _db
          .collection('home_sections')
          .doc(categoryId)
          .collection(sectionId)
          .orderBy('rank')
          .get();
      
      print('📊 HomeSectionRepo: Retrieved ${querySnapshot.docs.length} product references');
      
      // Extract product references with metadata
      final List<_SectionProductRef> productRefs = [];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final productId = data['productId'] as String?;
          final rank = data['rank'] as int? ?? 0;
          final priceOverride = data['priceOverride'] as num?;
          
          if (productId == null || productId.isEmpty) {
            print('⚠️ HomeSectionRepo: Product ID missing for document ${doc.id}');
            continue;
          }
          
          productRefs.add(_SectionProductRef(
            productId: productId,
            rank: rank,
            priceOverride: priceOverride?.toDouble(),
          ));
          
        } catch (e) {
          print('❌ HomeSectionRepo: Error processing product reference ${doc.id}: $e');
        }
      }
      
      print('🔍 HomeSectionRepo: Extracted ${productRefs.length} valid product references');
      
      // Use batched resolution to get all products at once
      final products = await _resolveProducts(productRefs);
      
      print('🎉 HomeSectionRepo: Successfully resolved ${products.length} products for section $sectionId');
      return products;
      
    } catch (e, stackTrace) {
      print('❌ HomeSectionRepo: Error fetching products for section $sectionId: $e');
      print('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch all home sections for all categories
  Future<Map<String, List<HomeSectionData>>> fetchAllHomeSections() async {
    try {
      print('🏠 HomeSectionRepo: Fetching all home sections...');
      
      final querySnapshot = await _db.collection('home_sections').get();
      print('📊 HomeSectionRepo: Found ${querySnapshot.docs.length} category documents');
      
      Map<String, List<HomeSectionData>> allSections = {};
      
      for (var doc in querySnapshot.docs) {
        final categoryId = doc.id;
        print('🔍 HomeSectionRepo: Processing category: $categoryId');
        
        final sections = await fetchHomeSectionsForCategory(categoryId);
        allSections[categoryId] = sections;
        
        print('✅ HomeSectionRepo: Loaded ${sections.length} sections for $categoryId');
      }
      
      print('🎉 HomeSectionRepo: Successfully loaded home sections for ${allSections.length} categories');
      return allSections;
      
    } catch (e, stackTrace) {
      print('❌ HomeSectionRepo: Error fetching all home sections: $e');
      print('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return {};
    }
  }

  /// Fetch specific section type for a category (e.g., flashSale for stationery)
  Future<List<ProductModel>> fetchSectionProducts(String categoryId, String sectionType) async {
    try {
      print('🎯 HomeSectionRepo: Fetching $sectionType products for $categoryId');
      
      final products = await _fetchSectionProducts(categoryId, sectionType);
      print('✅ HomeSectionRepo: Retrieved ${products.length} products for $categoryId/$sectionType');
      
      return products;
      
    } catch (e, stackTrace) {
      print('❌ HomeSectionRepo: Error fetching $sectionType products for $categoryId: $e');
      print('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }
}

/// Data model for home section
class HomeSectionData {
  final String sectionId;
  final String title;
  final String type;
  final List<ProductModel> products;
  final String categoryId;

  HomeSectionData({
    required this.sectionId,
    required this.title,
    required this.type,
    required this.products,
    required this.categoryId,
  });

  @override
  String toString() {
    return 'HomeSectionData(sectionId: $sectionId, title: $title, type: $type, products: ${products.length}, categoryId: $categoryId)';
  }
}
