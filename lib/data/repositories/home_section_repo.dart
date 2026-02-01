import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/home_section_model.dart';
import 'package:rps_stationery/data/models/home_section_item_model.dart';

/// Home Section Repository - Handles fetching home sections and items
/// New schema: home_sections/{section_id}/items/{sku_id}
class HomeSectionRepo extends GetxController {
  static HomeSectionRepo get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all active sections sorted by rank
  /// Only returns sections that are currently live (active status + within time range)
  Future<List<HomeSectionModel>> fetchActiveSections() async {
    try {
      log('🏠 HomeSectionRepo: Fetching active sections...');
      
      final querySnapshot = await _db
          .collection('home_sections')
          .where('status', isEqualTo: 'active')
          .orderBy('rank')
          .get();
      
      log('📊 HomeSectionRepo: Retrieved ${querySnapshot.docs.length} active sections');
      
      final sections = <HomeSectionModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final section = HomeSectionModel.fromFirestore(doc);
          
          // Only include sections that are currently live
          if (section.isLive) {
            sections.add(section);
            log('✅ HomeSectionRepo: Added live section: ${section.sectionId} (${section.title})');
          } else {
            log('⏰ HomeSectionRepo: Skipped section ${section.sectionId} - not live yet');
          }
        } catch (e) {
          log('❌ HomeSectionRepo: Error parsing section ${doc.id}: $e');
        }
      }
      
      log('🎉 HomeSectionRepo: Successfully loaded ${sections.length} live sections');
      return sections;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching active sections: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch all sections (including inactive) sorted by rank
  Future<List<HomeSectionModel>> fetchAllSections() async {
    try {
      log('🏠 HomeSectionRepo: Fetching all sections...');
      
      final querySnapshot = await _db
          .collection('home_sections')
          .orderBy('rank')
          .get();
      
      log('📊 HomeSectionRepo: Retrieved ${querySnapshot.docs.length} sections');
      
      final sections = <HomeSectionModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final section = HomeSectionModel.fromFirestore(doc);
          sections.add(section);
        } catch (e) {
          log('❌ HomeSectionRepo: Error parsing section ${doc.id}: $e');
        }
      }
      
      log('🎉 HomeSectionRepo: Successfully loaded ${sections.length} sections');
      return sections;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching all sections: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch a specific section by ID
  Future<HomeSectionModel?> fetchSectionById(String sectionId) async {
    try {
      log('🔍 HomeSectionRepo: Fetching section: $sectionId');
      
      final doc = await _db
          .collection('home_sections')
          .doc(sectionId)
          .get();
      
      if (!doc.exists) {
        log('⚠️ HomeSectionRepo: Section not found: $sectionId');
        return null;
      }
      
      final section = HomeSectionModel.fromFirestore(doc);
      log('✅ HomeSectionRepo: Retrieved section: ${section.title}');
      
      return section;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching section $sectionId: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch sections by type (e.g., flash_sale, popular, etc.)
  Future<List<HomeSectionModel>> fetchSectionsByType(String type) async {
    try {
      log('🎯 HomeSectionRepo: Fetching sections of type: $type');
      
      final querySnapshot = await _db
          .collection('home_sections')
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: 'active')
          .orderBy('rank')
          .get();
      
      log('📊 HomeSectionRepo: Retrieved ${querySnapshot.docs.length} sections of type $type');
      
      final sections = <HomeSectionModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final section = HomeSectionModel.fromFirestore(doc);
          if (section.isLive) {
            sections.add(section);
          }
        } catch (e) {
          log('❌ HomeSectionRepo: Error parsing section ${doc.id}: $e');
        }
      }
      
      log('🎉 HomeSectionRepo: Successfully loaded ${sections.length} live sections of type $type');
      return sections;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching sections by type $type: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch items for a specific section
  /// Returns items sorted by rank, respecting maxItems limit if set
  Future<List<HomeSectionItemModel>> fetchSectionItems(String sectionId, {int? limit}) async {
    try {
      log('📦 HomeSectionRepo: Fetching items for section: $sectionId');
      
      // Build query
      Query<Map<String, dynamic>> query = _db
          .collection('home_sections')
          .doc(sectionId)
          .collection('items')
          .where('is_active', isEqualTo: true)
          .orderBy('rank');
      
      // Apply limit if provided
      if (limit != null && limit > 0) {
        query = query.limit(limit);
        log('📊 HomeSectionRepo: Applying limit: $limit');
      }
      
      final querySnapshot = await query.get();
      
      log('📊 HomeSectionRepo: Retrieved ${querySnapshot.docs.length} items');
      
      final items = <HomeSectionItemModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final item = HomeSectionItemModel.fromFirestore(doc);
          items.add(item);
        } catch (e) {
          log('❌ HomeSectionRepo: Error parsing item ${doc.id}: $e');
        }
      }
      
      log('🎉 HomeSectionRepo: Successfully loaded ${items.length} items for section $sectionId');
      return items;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching items for section $sectionId: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch items for a section with automatic limit from section config
  Future<List<HomeSectionItemModel>> fetchSectionItemsWithConfig(HomeSectionModel section) async {
    return fetchSectionItems(section.sectionId, limit: section.maxItems);
  }

  /// Fetch all sections with their items
  /// Returns a map of section ID to items list
  Future<Map<String, List<HomeSectionItemModel>>> fetchAllSectionsWithItems() async {
    try {
      log('🏠 HomeSectionRepo: Fetching all sections with items...');
      
      final sections = await fetchActiveSections();
      final Map<String, List<HomeSectionItemModel>> sectionsWithItems = {};
      
      for (var section in sections) {
        final items = await fetchSectionItemsWithConfig(section);
        sectionsWithItems[section.sectionId] = items;
        log('✅ HomeSectionRepo: Loaded ${items.length} items for ${section.sectionId}');
      }
      
      log('🎉 HomeSectionRepo: Successfully loaded ${sectionsWithItems.length} sections with items');
      return sectionsWithItems;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching all sections with items: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return {};
    }
  }

  /// Stream active sections (real-time updates)
  Stream<List<HomeSectionModel>> streamActiveSections() {
    try {
      log('📡 HomeSectionRepo: Starting stream for active sections');
      
      return _db
          .collection('home_sections')
          .where('status', isEqualTo: 'active')
          .orderBy('rank')
          .snapshots()
          .map((snapshot) {
            final sections = <HomeSectionModel>[];
            
            for (var doc in snapshot.docs) {
              try {
                final section = HomeSectionModel.fromFirestore(doc);
                if (section.isLive) {
                  sections.add(section);
                }
              } catch (e) {
                log('❌ HomeSectionRepo: Error parsing section ${doc.id} in stream: $e');
              }
            }
            
            log('📡 HomeSectionRepo: Stream update - ${sections.length} live sections');
            return sections;
          });
          
    } catch (e) {
      log('❌ HomeSectionRepo: Error creating stream: $e');
      return Stream.value([]);
    }
  }

  /// Stream items for a specific section (real-time updates)
  Stream<List<HomeSectionItemModel>> streamSectionItems(String sectionId, {int? limit}) {
    try {
      log('📡 HomeSectionRepo: Starting stream for section items: $sectionId');
      
      Query<Map<String, dynamic>> query = _db
          .collection('home_sections')
          .doc(sectionId)
          .collection('items')
          .where('is_active', isEqualTo: true)
          .orderBy('rank');
      
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      
      return query.snapshots().map((snapshot) {
        final items = <HomeSectionItemModel>[];
        
        for (var doc in snapshot.docs) {
          try {
            final item = HomeSectionItemModel.fromFirestore(doc);
            items.add(item);
          } catch (e) {
            log('❌ HomeSectionRepo: Error parsing item ${doc.id} in stream: $e');
          }
        }
        
        log('📡 HomeSectionRepo: Stream update - ${items.length} items for $sectionId');
        return items;
      });
      
    } catch (e) {
      log('❌ HomeSectionRepo: Error creating items stream: $e');
      return Stream.value([]);
    }
  }

  /// Fetch section items with pagination support
  /// Returns paginated items for a section, ordered by rank
  Future<List<HomeSectionItemModel>> fetchSectionItemsPaginated(
    String sectionId, {
    int page = 0,
    int limit = 8,
  }) async {
    try {
      log('📦 HomeSectionRepo: Fetching paginated items for section: $sectionId (page: $page, limit: $limit)');
      
      final offset = page * limit;
      
      Query<Map<String, dynamic>> query = _db
          .collection('home_sections')
          .doc(sectionId)
          .collection('items')
          .where('is_active', isEqualTo: true)
          .orderBy('rank')
          .limit(limit);
      
      // For offset, we need to fetch more documents and skip
      if (offset > 0) {
        final allDocs = await _db
            .collection('home_sections')
            .doc(sectionId)
            .collection('items')
            .where('is_active', isEqualTo: true)
            .orderBy('rank')
            .get();
        
        final itemList = <HomeSectionItemModel>[];
        final docsToProcess = allDocs.docs.skip(offset).take(limit);
        
        for (var doc in docsToProcess) {
          try {
            final item = HomeSectionItemModel.fromFirestore(doc);
            itemList.add(item);
          } catch (e) {
            log('❌ HomeSectionRepo: Error parsing item ${doc.id}: $e');
          }
        }
        
        log('📊 HomeSectionRepo: Retrieved ${itemList.length} paginated items (offset: $offset)');
        return itemList;
      }
      
      final querySnapshot = await query.get();
      
      log('📊 HomeSectionRepo: Retrieved ${querySnapshot.docs.length} items for page $page');
      
      final items = <HomeSectionItemModel>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final item = HomeSectionItemModel.fromFirestore(doc);
          items.add(item);
        } catch (e) {
          log('❌ HomeSectionRepo: Error parsing item ${doc.id}: $e');
        }
      }
      
      log('🎉 HomeSectionRepo: Successfully loaded ${items.length} items for section $sectionId (page: $page)');
      return items;
      
    } catch (e, stackTrace) {
      log('❌ HomeSectionRepo: Error fetching paginated items for section $sectionId: $e');
      log('❌ HomeSectionRepo: Stack trace: $stackTrace');
      return [];
    }
  }
}
