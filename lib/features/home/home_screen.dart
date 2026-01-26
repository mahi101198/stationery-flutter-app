import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/animations/micro_animations.dart';

import 'components/banner_carousel.dart';
import 'components/category_cards.dart';
import 'components/category_home_sections.dart';
import 'controllers/category_controller.dart';
import 'controllers/home_section_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CategoryController _categoryController;
  late HomeSectionController _homeSectionController;
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
            collapsedHeight: 70, // Reduced to ensure proper collapse detection
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed = constraints.biggest.height <= 115;
                
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
                                      'RPS STATIONERY',
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
            collapsedHeight: 140, // Further reduced height for better image utilization
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2), // Minimized vertical padding
              child: const Center(
                child: BannerCarousel(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Categories Section - Minimalist Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Categories",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Get.toNamed(
                        Routes.category,
                        arguments: {'categoryName': 'All Products', 'categoryId': null},
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "View All",
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Iconsax.arrow_right_3,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MicroAnimations.fadeSlideIn(
                duration: MicroAnimations.normal,
                slideOffset: 30.0,
                child: const CategoryCards(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Dynamic Category-based Home Sections
          const SliverToBoxAdapter(
            child: CategoryHomeSections(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ],
      ),
    );
  }
}
