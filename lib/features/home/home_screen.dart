import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/animations/micro_animations.dart';

import 'components/banner_carousel.dart';
import 'components/home_sections_list.dart';
import 'controllers/category_controller.dart';
import 'controllers/home_section_controller.dart';
import 'controllers/subcategory_filter_controller.dart';
import 'components/subcategory_filter_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CategoryController _categoryController;
  late HomeSectionController _homeSectionController;
  late SubcategoryFilterController _subcategoryFilterController;
  late TextEditingController _searchTextController;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen: Initializing home screen...');
    
    _categoryController = Get.put(CategoryController());
    print('📂 HomeScreen: Category controller initialized');
    
    // Use Get.put to ensure controller is created if not already exists
    _homeSectionController = Get.put(HomeSectionController());
    print('🏠 HomeScreen: Home section controller initialized');
    
    _subcategoryFilterController = Get.put(SubcategoryFilterController());
    print('🏷️ HomeScreen: Subcategory filter controller initialized');
    
    _searchTextController = TextEditingController();
    print('⌨️ HomeScreen: Search UI components initialized');
    
    print('✅ HomeScreen: Initialization completed successfully');
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ HomeScreen: Building home screen UI...');
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main content with scroll view
          CustomScrollView(
            slivers: [
          // Sticky Search Bar Header
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 120,
            collapsedHeight: 70,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Check if collapsed based on the actual height
                final isCollapsed = constraints.biggest.height <= 70 + MediaQuery.of(context).padding.top;
                
                return Container(
                  padding: EdgeInsets.fromLTRB(
                    16, 
                    MediaQuery.of(context).padding.top + (isCollapsed ? 8 : 16), 
                    16, 
                    isCollapsed ? 8 : 16
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: isCollapsed 
                    ? // Collapsed state - only search bar
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to search screen
                            Get.toNamed(Routes.search);
                          },
                          child: AbsorbPointer(
                            child: ThemeAwareSearchBar(
                              hint: 'Search for stationery, books, supplies...',
                              controller: _searchTextController,
                              onChanged: (query) {},
                              onSubmitted: (query) {},
                              onFilterTap: () {
                                // Show filter options
                              },
                            ),
                          ),
                        ),
                      )
                    : // Expanded state - header + search bar
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with app name/logo and notification icon
                          Flexible(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // App Logo/Icon
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/logo/stationery_icon.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // App Name
                                    Text(
                                      'RPS',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    Get.toNamed(Routes.notification);
                                  },
                                  icon: Icon(
                                    Iconsax.notification,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search bar
                          Flexible(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to search screen
                                Get.toNamed(Routes.search);
                              },
                              child: AbsorbPointer(
                                child: ThemeAwareSearchBar(
                                  hint: 'Search for stationery, books, supplies...',
                                  controller: _searchTextController,
                                  onChanged: (query) {},
                                  onSubmitted: (query) {},
                                  onFilterTap: () {
                                    // Show filter options
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),

          // Fixed Banner Carousel - Pinned below search bar
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 0,
            collapsedHeight: 160, // Adjusted height for better banner display
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate 0.5% margin from screen width
                final screenWidth = MediaQuery.of(context).size.width;
                final margin = screenWidth * 0.005; // 0.5% margin
                
                return Container(
                  padding: EdgeInsets.all(margin), // 0.5% margin from all sides
                  child: const Center(
                    child: BannerCarousel(),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Subcategory Filter Row
          const SliverToBoxAdapter(
            child: SubcategoryFilterRow(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 1)),

          // Home Sections (Global, sorted by rank)
          const SliverToBoxAdapter(
            child: HomeSectionsList(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ],
      ),
    );
  }
}
