import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/product/horizontal_product_item.dart';
import 'package:rps_stationery/components/product/product_card.dart';
import 'package:rps_stationery/constants.dart';
import 'package:rps_stationery/data/models/product_model.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/services/unified_search_service.dart';

class OptimizedSearchScreen extends StatefulWidget {
  const OptimizedSearchScreen({super.key});

  @override
  State<OptimizedSearchScreen> createState() => _OptimizedSearchScreenState();
}

class _OptimizedSearchScreenState extends State<OptimizedSearchScreen> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  
  final _searchService = UnifiedSearchService.instance;
  
  List<ProductModel> _searchResults = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _showSuggestions = true;
  String _currentQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 20;
  
  // View mode: list or grid
  bool _isGridView = false;
  
  // Debounce timer for search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    // Get initial query from navigation arguments
    final arguments = Get.arguments;
    String initialQuery = '';
    if (arguments != null && arguments is Map && arguments.containsKey('query')) {
      initialQuery = arguments['query'] ?? '';
    }
    
    _searchController = TextEditingController(text: initialQuery);
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    
    // Auto focus and load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialQuery.isNotEmpty) {
        // Perform search for initial query
        _currentQuery = initialQuery;
        _performSearch(initialQuery);
      } else {
        // Load suggestions
        _focusNode.requestFocus();
        _loadSuggestions();
      }
    });

    // Listen to scroll for infinite loading
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreResults();
    }
  }

  /// Load suggestions (popular searches or query-based)
  Future<void> _loadSuggestions([String? query]) async {
      setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final suggestions = await _searchService.getSuggestions(query ?? '');
      
      if (mounted) {
          setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      print('Error loading suggestions: $e');
      if (mounted) {
    setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  /// Perform product search
  Future<void> _performSearch(String query, {bool loadMore = false}) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentQuery = '';
        _currentPage = 0;
        _hasMoreData = true;
        _showSuggestions = true;
      });
      await _loadSuggestions();
      return;
    }

    if (loadMore && (_isLoadingMore || !_hasMoreData)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isSearching = true;
        _currentQuery = query;
        _currentPage = 0;
        _hasMoreData = true;
        _searchResults.clear();
        _showSuggestions = false;
      }
    });

    try {
      final results = await _searchService.searchProducts(
        query,
        limit: _pageSize,
        offset: loadMore ? _currentPage * _pageSize : 0,
      );

      if (mounted) {
        setState(() {
      if (loadMore) {
        _searchResults.addAll(results);
        _currentPage++;
      } else {
        _searchResults = results;
        _currentPage = 1;
            // Add to search history
            _searchService.addToHistory(query);
            
        // Debug: Log product images AND pricing
        print('🖼️ Search Results Debug:');
        print('   Total products: ${results.length}');
        if (results.isNotEmpty) {
          for (var i = 0; i < results.take(3).length; i++) {
            final p = results[i];
            print('   Product $i: ${p.name}');
            print('   - Image field: "${p.image}"');
            print('   - DisplayImage: "${p.displayImage}"');
            print('   - Has image: ${p.displayImage.isNotEmpty}');
            print('   💰 MRP: ${p.mrp}, Price: ${p.price}, Discount: ${p.discount}%');
            print('   💰 HasDiscount: ${p.hasDiscount}');
          }
        }
      }

      if (results.length < _pageSize) {
        _hasMoreData = false;
      }
        });
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      if (mounted) {
      setState(() {
        _isSearching = false;
        _isLoadingMore = false;
      });
      }
    }
  }

  /// Load more results (infinite scroll)
  Future<void> _loadMoreResults() async {
    if (_currentQuery.isNotEmpty && !_isLoadingMore && _hasMoreData) {
      await _performSearch(_currentQuery, loadMore: true);
    }
  }

  /// Handle search text changes
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _showSuggestions = true;
        _searchResults.clear();
        _currentQuery = '';
      });
      _loadSuggestions();
    } else if (query.length >= 2) {
      setState(() {
        _showSuggestions = true;
      });
      
      // Debounce the suggestion loading
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _loadSuggestions(query);
      });
    } else {
      setState(() {
        _showSuggestions = false;
        _searchResults.clear();
      });
    }
  }

  /// Handle suggestion tap
  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _focusNode.unfocus();
    _performSearch(suggestion);
  }

  /// Clear current search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _currentQuery = '';
      _showSuggestions = true;
    });
    _loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _showSuggestions
          ? _buildSuggestions(context)
          : _buildSearchResults(context),
    );
  }

  /// Build AppBar with search field
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
        height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
            border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
          style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Iconsax.search_normal,
              color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Iconsax.close_circle,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
              vertical: 10,
            ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                _performSearch(query);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
    );
  }

  /// Build suggestions list
  Widget _buildSuggestions(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(defaultPadding),
      children: [
        // Search History Section (if any)
        Obx(() {
          if (_searchService.searchHistory.isEmpty || _currentQuery.isNotEmpty) {
            return const SizedBox.shrink();
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _searchService.clearHistory();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._searchService.searchHistory.take(5).map((query) =>
                ListTile(
                  leading: Icon(
                    Iconsax.clock,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    query,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Iconsax.close_circle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchService.removeFromHistory(query);
                    },
                  ),
                  onTap: () => _onSuggestionTap(query),
                )
              ).toList(),
              const Divider(height: 32),
            ],
          );
        }),
        
        // Suggestions Section
        Row(
          children: [
            Icon(
              _currentQuery.isEmpty ? Iconsax.trend_up : Iconsax.search_normal_1,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
        Text(
              _currentQuery.isEmpty ? 'Popular Searches' : 'Suggestions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
            if (_isLoadingSuggestions) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        if (_suggestions.isEmpty && !_isLoadingSuggestions)
          Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                  Iconsax.search_status,
                    size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No suggestions available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
            ),
          )
        else
          ..._suggestions.map((suggestion) => ListTile(
            leading: Icon(
              Iconsax.search_normal,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            title: Text(
              suggestion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Icon(
              Iconsax.arrow_up_3,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 16,
            ),
            onTap: () => _onSuggestionTap(suggestion),
          )),
      ],
    );
  }

  /// Build search results
  Widget _buildSearchResults(BuildContext context) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.search_status,
                size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No results found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'for "$_currentQuery"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Try different keywords or check spelling',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showSuggestions = true;
                  });
                  _loadSuggestions();
                },
                    icon: const Icon(Iconsax.search_normal, size: 18),
                    label: const Text('View Suggestions'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Results header with count and view toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'} found',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              // Grid/List view toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.element_3,
                        color: _isGridView
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _isGridView = true;
                        });
                      },
                      tooltip: 'Grid View',
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: Icon(
                        Iconsax.menu,
                        color: !_isGridView
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _isGridView = false;
                        });
                      },
                      tooltip: 'List View',
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Results list/grid
        Expanded(
          child: RefreshIndicator(
      onRefresh: () => _performSearch(_currentQuery),
            child: _isGridView
                ? _buildGridResults(context)
                : _buildListResults(context),
          ),
        ),
      ],
    );
  }

  /// Build grid view results
  Widget _buildGridResults(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= _searchResults.length) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final product = _searchResults[index];
        return ProductCard(
          product: product,
          press: () {
            Get.toNamed(
              Routes.productDetail,
              arguments: product.productId,
            );
          },
        );
      },
    );
  }

  /// Build list view results
  Widget _buildListResults(BuildContext context) {
    return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final product = _searchResults[index];
          return HorizontalProductItem(
            product: product,
            onTap: () {
              Get.toNamed(
                Routes.productDetail,
                arguments: product.productId,
              );
            },
          );
        },
    );
  }
}
