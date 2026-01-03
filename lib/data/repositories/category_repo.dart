import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/category_model.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class CategoryRepo extends GetxController {
  static CategoryRepo get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  Future<T> safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log("CategoryRepo unexpected error -> $e", error: e);
      throw 'Something went wrong. Please try again';
    }
  }

  /// Fetch all active categories
  Future<List<CategoryModel>> fetchAllCategories() async {
    return safeCall(() async {
      log('🔄 CategoryRepo: Starting Firestore query for active categories', name: 'CategoryRepo');
      
      final categories = await _db
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('rank')
          .get();
          
      log('📊 CategoryRepo: Query returned ${categories.docs.length} documents', name: 'CategoryRepo');
      
      if (categories.docs.isEmpty) {
        log('⚠️ CategoryRepo: No active categories found in Firestore!', name: 'CategoryRepo');
        return [];
      }
      
      final categoryList = categories.docs
          .map((snapshot) {
            try {
              final category = CategoryModel.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
              log('✅ CategoryRepo: Successfully parsed category: ${category.name}', name: 'CategoryRepo');
              return category;
            } catch (e) {
              log('❌ CategoryRepo: Failed to parse category ${snapshot.id}: $e', name: 'CategoryRepo');
              rethrow;
            }
          })
          .toList();
          
      log('✅ CategoryRepo: Successfully processed ${categoryList.length} categories', name: 'CategoryRepo');
      return categoryList;
    });
  }

  /// Fetch categories with pagination
  Future<List<CategoryModel>> fetchCategories({
    int limit = 20,
    int offset = 0,
    String? lastDocumentId,
  }) async {
    return safeCall(() async {
      log('🔄 CategoryRepo: Fetching categories with pagination (limit: $limit, offset: $offset)', name: 'CategoryRepo');
      
      Query query = _db
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('rank')
          .limit(limit);

      // Add offset using cursor-based pagination if lastDocumentId is provided
      if (lastDocumentId != null) {
        final lastDoc = await _db.collection('categories').doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      } else if (offset > 0) {
        // For simple offset-based pagination (less efficient but simpler)
        query = query.limit(offset + limit);
      }

      final categories = await query.get();
      
      log('📊 CategoryRepo: Paginated query returned ${categories.docs.length} documents', name: 'CategoryRepo');
      
      if (categories.docs.isEmpty) {
        log('⚠️ CategoryRepo: No more categories found', name: 'CategoryRepo');
        return [];
      }

      // Apply offset if not using cursor-based pagination
      final docsToProcess = lastDocumentId == null && offset > 0 
          ? categories.docs.skip(offset).toList()
          : categories.docs;
      
      final categoryList = docsToProcess
          .map((snapshot) {
            try {
              final category = CategoryModel.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
              return category;
            } catch (e) {
              log('❌ CategoryRepo: Failed to parse category ${snapshot.id}: $e', name: 'CategoryRepo');
              return null;
            }
          })
          .where((category) => category != null)
          .cast<CategoryModel>()
          .toList();
          
      log('✅ CategoryRepo: Successfully processed ${categoryList.length} categories', name: 'CategoryRepo');
      return categoryList;
    });
  }

  /// Get category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    return safeCall(() async {
      final doc = await _db.collection('categories').doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return CategoryModel.fromFirestore(doc);
    });
  }

  /// Search categories by name
  Future<List<CategoryModel>> searchCategories(String query) async {
    return safeCall(() async {
      log('🔄 CategoryRepo: Searching categories with query: $query', name: 'CategoryRepo');
      
      Query searchQuery = _db
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query~')
          .orderBy('name')
          .limit(20);

      final categoriesSnapshot = await searchQuery.get();
      
      log('📊 CategoryRepo: Search query returned ${categoriesSnapshot.docs.length} documents', name: 'CategoryRepo');

      final categoryList = categoriesSnapshot.docs
          .map((doc) {
            try {
              return CategoryModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
            } catch (e) {
              log('❌ CategoryRepo: Failed to parse search result ${doc.id}: $e', name: 'CategoryRepo');
              return null;
            }
          })
          .where((category) => category != null)
          .cast<CategoryModel>()
          .toList();
          
      log('✅ CategoryRepo: Successfully processed ${categoryList.length} search results', name: 'CategoryRepo');
      return categoryList;
    });
  }
}
