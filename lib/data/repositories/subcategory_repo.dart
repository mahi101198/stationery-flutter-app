import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

/// Model for subcategory data
class SubCategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String image;
  final bool isActive;
  final int rank;

  const SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.isActive,
    required this.rank,
  });

  factory SubCategoryModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        print('⚠️ SubCategoryRepo: Document ${doc.id} has null data');
        throw Exception('Document data is null');
      }
      
      // Log the raw data for debugging
      print('📝 SubCategoryRepo: Raw data for ${doc.id}: $data');
      
      return SubCategoryModel(
        id: doc.id,
        categoryId: data['category_id'] as String? ?? data['categoryId'] as String? ?? '',
        name: data['name'] as String? ?? 'Unknown',
        image: data['image'] as String? ?? '',
        isActive: data['is_active'] as bool? ?? data['isActive'] as bool? ?? false,
        rank: (data['rank'] as num?)?.toInt() ?? 0,
      );
    } catch (e, stackTrace) {
      print('❌ SubCategoryRepo: Error parsing subcategory ${doc.id}: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  String toString() => 'SubCategoryModel(id: $id, name: $name, categoryId: $categoryId)';
}

class SubCategoryRepo extends GetxController {
  static SubCategoryRepo get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all subcategories from the subcategories collection
  Future<List<SubCategoryModel>> fetchAllSubCategories() async {
    try {
      print('📂 SubCategoryRepo: Fetching all subcategories...');
      final snapshot = await _db.collection('subcategories').get();
      print('📊 SubCategoryRepo: Found ${snapshot.docs.length} subcategory documents');

      final List<SubCategoryModel> subcategories = snapshot.docs.map((doc) {
        print('🔍 SubCategoryRepo: Processing subcategory: ${doc.id}');
        return SubCategoryModel.fromFirestore(doc);
      }).toList();

      print('✅ SubCategoryRepo: Successfully loaded ${subcategories.length} subcategories');
      return subcategories;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong while fetching subcategories. Please try again. $e';
    }
  }

  /// Fetch subcategories grouped by category
  Future<Map<String, List<SubCategoryModel>>> fetchSubCategoriesGroupedByCategory() async {
    try {
      print('📂 SubCategoryRepo: Fetching subcategories grouped by category...');
      final subcategories = await fetchAllSubCategories();
      
      // Group subcategories by categoryId
      final Map<String, List<SubCategoryModel>> groupedSubcategories = {};
      
      for (final subcategory in subcategories) {
        if (!groupedSubcategories.containsKey(subcategory.categoryId)) {
          groupedSubcategories[subcategory.categoryId] = [];
        }
        groupedSubcategories[subcategory.categoryId]!.add(subcategory);
      }

      // Sort subcategories within each category by rank
      for (final categoryId in groupedSubcategories.keys) {
        groupedSubcategories[categoryId]!.sort((a, b) => a.rank.compareTo(b.rank));
      }

      print('✅ SubCategoryRepo: Successfully grouped subcategories by ${groupedSubcategories.length} categories');
      for (final entry in groupedSubcategories.entries) {
        print('  📋 Category ${entry.key}: ${entry.value.length} subcategories');
      }
      
      return groupedSubcategories;
    } catch (e) {
      print('❌ SubCategoryRepo: Error grouping subcategories: $e');
      rethrow;
    }
  }

  /// Fetch subcategories for a specific category
  Future<List<SubCategoryModel>> fetchSubCategoriesByCategory(String categoryId) async {
    try {
      print('📂 SubCategoryRepo: Fetching subcategories for category: $categoryId');
      final snapshot = await _db
          .collection('subcategories')
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('rank')
          .get();

      final List<SubCategoryModel> subcategories = snapshot.docs.map((doc) {
        return SubCategoryModel.fromFirestore(doc);
      }).toList();

      print('✅ SubCategoryRepo: Found ${subcategories.length} subcategories for category $categoryId');
      return subcategories;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong while fetching subcategories for category $categoryId. Please try again. $e';
    }
  }
}
