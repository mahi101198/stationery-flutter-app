import 'package:flutter/material.dart';

/// Minimal Product Image Carousel following Material 3 design
class MinimalProductCarousel extends StatefulWidget {
  final List<String> images;

  const MinimalProductCarousel({
    super.key,
    required this.images,
  });

  @override
  State<MinimalProductCarousel> createState() => _MinimalProductCarouselState();
}

class _MinimalProductCarouselState extends State<MinimalProductCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildImageItem(String imageUrl) {
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: _buildImageWithErrorHandling(imageUrl, context),
        ),
      ),
    );
  }

  Widget _buildImageWithErrorHandling(String imageUrl, BuildContext context) {
    // Check for invalid URLs or example.com placeholders
    if (imageUrl.isEmpty || imageUrl.contains('example.com')) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Preview unavailable',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      cacheWidth: 800,
      cacheHeight: 800,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        
        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null;
        
        return Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFF00BCD4),
              value: progress,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Log error but don't throw
        debugPrint('❌ Image load error for URL: $imageUrl');
        debugPrint('   Error: $error');
        
        // Wrap in Directionality to ensure text direction context
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.0, // Square aspect ratio
          child: Stack(
            children: [
              // Image PageView
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return _buildImageItem(widget.images[index]);
                },
              ),

              // Pagination Dots
              if (widget.images.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == index ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFF00BCD4)
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

