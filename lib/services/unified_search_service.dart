import 'dart:developer';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/data/services/product_cache_service.dart';

/// Unified Search Service
/// 
/// Provides consistent search functionality across the entire app.
/// Handles product search, suggestions, and search history.
class UnifiedSearchService extends GetxController {
  static UnifiedSearchService get instance => Get.find();

  final ProductCacheService _cacheService = ProductCacheService.instance;

  // Search history (limited to 10 recent searches)
  final RxList<String> searchHistory = <String>[].obs;
  static const int maxHistoryItems = 10;

  @override
  void onInit() {
    super.onInit();
    _loadSearchHistory();
  }

  /// Main search method - searches products with relevance ranking
  Future<List<ProductModel>> searchProducts(String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (query.trim().isEmpty) return [];

      final lowerQuery = query.toLowerCase().trim();
      log('🔍 UnifiedSearch: Searching for "$lowerQuery"', name: 'UnifiedSearch');

      // Use cache service for local search (much faster)
      final allResults = await _cacheService.searchProducts(lowerQuery);
      
      // Apply relevance scoring and sorting
      final scoredResults = allResults.map((product) {
        final score = _calculateRelevanceScore(product, lowerQuery);
        return _ScoredProduct(product, score);
      }).where((scored) => scored.score > 0).toList();

      // Sort by relevance score (highest first)
      scoredResults.sort((a, b) => b.score.compareTo(a.score));

      // Apply pagination
      final startIndex = offset;
      final endIndex = (startIndex + limit).clamp(0, scoredResults.length);
      final paginatedResults = scoredResults
          .sublist(
            startIndex.clamp(0, scoredResults.length),
            endIndex,
          )
          .map((scored) => scored.product)
          .toList();

      log('✅ UnifiedSearch: Found ${paginatedResults.length} results', name: 'UnifiedSearch');
      return paginatedResults;
    } catch (e) {
      log('❌ UnifiedSearch: Search error: $e', name: 'UnifiedSearch');
      return [];
    }
  }

  /// Get smart suggestions based on query
  Future<List<String>> getSuggestions(String query) async {
    try {
      if (query.trim().isEmpty) {
        // Return popular/recent searches when no query
        return _getPopularSuggestions();
      }

      final lowerQuery = query.toLowerCase().trim();
      log('💡 UnifiedSearch: Getting suggestions for "$lowerQuery"', name: 'UnifiedSearch');

      // Search products to generate suggestions
      final products = await _cacheService.searchProducts(lowerQuery);
      
      if (products.isEmpty) {
        // Return related suggestions if no products found
        return _getRelatedSuggestions(lowerQuery);
      }

      // Generate suggestions from actual product data
      final suggestions = <String>{};
      
      for (final product in products.take(20)) {
        final name = product.name.toLowerCase();
        
        // Add exact product name if it matches well
        if (name.contains(lowerQuery)) {
          suggestions.add(product.name);
        }
        
        // Add category if it matches
        if (product.categoryId.toLowerCase().contains(lowerQuery)) {
          suggestions.add(product.categoryId);
        }
        
        // Add subcategory if it matches
        if (product.subcategoryId.isNotEmpty &&
            product.subcategoryId.toLowerCase().contains(lowerQuery)) {
          suggestions.add(product.subcategoryId);
        }

        // Extract meaningful keywords from product name
        final words = product.name.split(' ');
        for (final word in words) {
          if (word.toLowerCase().contains(lowerQuery) && word.length > 2) {
            suggestions.add(word);
          }
        }
      }

      // Prioritize suggestions that start with the query
      final suggestionList = suggestions.toList();
      suggestionList.sort((a, b) {
        final aLower = a.toLowerCase();
        final bLower = b.toLowerCase();
        
        // Exact match first
        if (aLower == lowerQuery && bLower != lowerQuery) return -1;
        if (bLower == lowerQuery && aLower != lowerQuery) return 1;
        
        // Starts with query second
        if (aLower.startsWith(lowerQuery) && !bLower.startsWith(lowerQuery)) return -1;
        if (bLower.startsWith(lowerQuery) && !aLower.startsWith(lowerQuery)) return 1;
        
        // Shorter first
        return a.length.compareTo(b.length);
      });

      final topSuggestions = suggestionList.take(8).toList();
      log('💡 UnifiedSearch: Generated ${topSuggestions.length} suggestions', name: 'UnifiedSearch');
      
      return topSuggestions;
    } catch (e) {
      log('❌ UnifiedSearch: Suggestions error: $e', name: 'UnifiedSearch');
      return _getPopularSuggestions();
    }
  }

  /// Calculate relevance score for a product based on query
  int _calculateRelevanceScore(ProductModel product, String query) {
    int score = 0;
    final lowerName = product.name.toLowerCase();
    final lowerCategory = product.categoryId.toLowerCase();
    final lowerSubcategory = product.subcategoryId.toLowerCase();
    final lowerDescription = (product.description ?? '').toLowerCase();

    // Exact name match (highest priority)
    if (lowerName == query) {
      score += 1000;
    }
    // Name starts with query
    else if (lowerName.startsWith(query)) {
      score += 500;
    }
    // Name contains query
    else if (lowerName.contains(query)) {
      score += 300;
      // Bonus for word boundary match
      final words = lowerName.split(' ');
      if (words.any((word) => word.startsWith(query))) {
        score += 100;
      }
    }

    // Category matches
    if (lowerCategory == query) {
      score += 200;
    } else if (lowerCategory.contains(query)) {
      score += 100;
    }

    // Subcategory matches
    if (lowerSubcategory == query) {
      score += 150;
    } else if (lowerSubcategory.contains(query)) {
      score += 75;
    }

    // Description contains query
    if (lowerDescription.contains(query)) {
      score += 50;
    }

    // Tag matches
    for (final tag in product.tags) {
      final lowerTag = tag.toLowerCase();
      if (lowerTag == query) {
        score += 100;
      } else if (lowerTag.contains(query)) {
        score += 30;
      }
    }

    // Bonus for popular/discounted products
    if (product.discount > 0) {
      score += 20;
    }

    return score;
  }

  /// Get popular search suggestions when query is empty
  List<String> _getPopularSuggestions() {
    // Combine search history with popular terms
    final suggestions = <String>[
      ...searchHistory.take(5),
      'Pen',
      'Notebook',
      'Pencil',
      'Calculator',
      'Eraser',
      'Ruler',
      'Stapler',
      'Marker',
    ];

    // Remove duplicates while preserving order
    final seen = <String>{};
    return suggestions.where((item) => seen.add(item.toLowerCase())).take(8).toList();
  }

  /// Get related suggestions when no products found
  List<String> _getRelatedSuggestions(String query) {
    final related = <String>[];
    
    // Category-based suggestions
    if (query.contains('pen') || query.contains('pencil')) {
      related.addAll(['Pen', 'Pencil', 'Marker', 'Colors']);
    } else if (query.contains('book') || query.contains('notebook')) {
      related.addAll(['Notebook', 'Diary', 'Register', 'Copy']);
    } else if (query.contains('calculator')) {
      related.addAll(['Calculator', 'Scientific Calculator', 'Basic Calculator']);
    } else if (query.contains('bag') || query.contains('backpack')) {
      related.addAll(['School Bag', 'Backpack', 'Laptop Bag']);
    } else if (query.contains('geometry') || query.contains('set')) {
      related.addAll(['Geometry Box', 'Mathematical Set', 'Ruler']);
    } else if (query.contains('color') || query.contains('crayon')) {
      related.addAll(['Pencil Colors', 'Crayons', 'Sketch Pens']);
    } else {
      // Generic fallback
      related.addAll(['Pen', 'Notebook', 'Pencil', 'Eraser', 'Ruler', 'Stapler']);
    }

    return related.take(6).toList();
  }

  /// Add search to history
  void addToHistory(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();
    
    // Remove if already exists (to move it to top)
    searchHistory.remove(trimmedQuery);
    
    // Add to beginning
    searchHistory.insert(0, trimmedQuery);
    
    // Limit to max items
    if (searchHistory.length > maxHistoryItems) {
      searchHistory.removeRange(maxHistoryItems, searchHistory.length);
    }
    
    _saveSearchHistory();
  }

  /// Clear search history
  void clearHistory() {
    searchHistory.clear();
    _saveSearchHistory();
  }

  /// Remove specific item from history
  void removeFromHistory(String query) {
    searchHistory.remove(query);
    _saveSearchHistory();
  }

  /// Load search history from storage
  Future<void> _loadSearchHistory() async {
    try {
      final storage = GetStorage();
      final history = storage.read<List>('search_history');
      if (history != null) {
        searchHistory.value = history.cast<String>();
      }
    } catch (e) {
      log('⚠️ UnifiedSearch: Failed to load history: $e', name: 'UnifiedSearch');
    }
  }

  /// Save search history to storage
  Future<void> _saveSearchHistory() async {
    try {
      final storage = GetStorage();
      await storage.write('search_history', searchHistory.toList());
    } catch (e) {
      log('⚠️ UnifiedSearch: Failed to save history: $e', name: 'UnifiedSearch');
    }
  }
}

/// Helper class to store product with relevance score
class _ScoredProduct {
  final ProductModel product;
  final int score;

  _ScoredProduct(this.product, this.score);
}

