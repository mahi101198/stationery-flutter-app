import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/features/home/controllers/category_controller.dart';
import 'package:rps_stationery/data/models/category_model.dart';
import 'package:rps_stationery/components/skleton/category_skeleton.dart';


class CategoryCards extends StatelessWidget {
  const CategoryCards({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ CategoryCards: Building category cards widget...');
    
    // Use Get.find instead of Get.put to avoid multiple instances
    CategoryController? controller;
    try {
      controller = Get.find<CategoryController>();
      print('🏗️ CategoryCards: Category controller found');
    } catch (e) {
      print('🏗️ CategoryCards: Category controller not found, creating new instance');
      controller = Get.put(CategoryController());
    }
    print('🏗️ CategoryCards: Category controller obtained');

    return Obx(
      () {
        print('🔄 CategoryCards: Reactive build triggered');
        print('🔄 CategoryCards: Controller state - Loading: ${controller?.isLoading.value ?? true}, Error: ${controller?.hasError.value ?? false}, HasCategories: ${controller?.hasCategories ?? false}');
        
        if (controller == null || controller.isLoading.value) {
          print('⏳ CategoryCards: Showing skeleton loader');
          return const CategorySkeleton();
        } else if (controller.hasError.value) {
          print('❌ CategoryCards: Showing error state');
          return _buildErrorState(context, controller);
        } else if (controller.hasCategories) {
          print('✅ CategoryCards: Showing category grid with ${controller.categories.length} categories');
          return _buildCategoryGrid(context, controller);
        } else {
          print('⚠️ CategoryCards: Showing empty state');
          return _buildEmptyState(context);
        }
      },
    );
  }

  Widget _buildCategoryGrid(BuildContext context, CategoryController controller) {
    print('🏗️ CategoryCards: Building category grid...');
    
    final categories = controller.getCategoriesForHome(limit: 6);
    print('🏗️ CategoryCards: Retrieved ${categories.length} categories for home display');
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        print('🏗️ CategoryCards: Building category card $index: ${category.name}');
        
        return CategoryCard(
          category: category,
          index: index,
          onTap: () {
            print('👆 CategoryCards: Category tapped: ${category.name} (${category.id})');
            // Add safety check to prevent navigation during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                Get.toNamed(
                  Routes.category,
                  arguments: {'categoryName': category.name, 'categoryId': category.id},
                );
              } catch (e) {
                print('❌ CategoryCards: Navigation error: $e');
              }
            });
          },
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, CategoryController controller) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load categories',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => controller.refreshCategories(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No categories available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.index,
  });

  final CategoryModel category;
  final VoidCallback onTap;
  final int index;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Modern gradient colors based on index
  List<Color> _getGradientColors(BuildContext context, int index) {
    final colors = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo to Purple
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)], // Pink to Rose
      [const Color(0xFF10B981), const Color(0xFF06B6D4)], // Green to Cyan
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)], // Amber to Red
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)], // Purple to Pink
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)], // Cyan to Blue
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors(context, widget.index);
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Pattern overlay
                  Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: _DotPatternPainter(),
                    ),
                  ),
                  
                  // Category Image (if available)
                  if (widget.category.image.isNotEmpty)
                    Opacity(
                      opacity: 0.3,
                      child: Image.network(
                        widget.category.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox.shrink();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Silent failure - just don't show the image
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

// Custom painter for dot pattern
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 12.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
