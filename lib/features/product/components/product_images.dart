import 'package:flutter/material.dart';
import '/components/network_image_with_loader.dart';

import '../../../../constants.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({super.key, required this.images});

  final List<String> images;

  @override
  State<ProductImages> createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages> 
    with SingleTickerProviderStateMixin {
  late PageController _controller;
  late AnimationController _scaleController;
  
  int _currentPage = 0;

  @override
  void initState() {
    _controller = PageController(
      viewportFraction: 0.92,
      initialPage: _currentPage,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Image carousel with modern design
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  onPageChanged: (pageNum) {
                    if (mounted) {
                      setState(() {
                        _currentPage = pageNum;
                      });
                      // Reset and replay scale animation
                      _scaleController.reset();
                      _scaleController.forward();
                    }
                  },
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    final isActive = index == _currentPage;
                    
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_controller.position.haveDimensions) {
                          value = _controller.page! - index;
                          value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                        }
                        
                        return Center(
                          child: Transform.scale(
                            scale: value,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Hero(
                          tag: 'product_image_${widget.images[index]}',
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: isActive ? 0.3 : 0.1),
                                  blurRadius: isActive ? 24 : 12,
                                  spreadRadius: isActive ? 2 : 0,
                                  offset: Offset(0, isActive ? 8 : 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image
                                  NetworkImageWithLoader(
                                    widget.images[index],
                                    fit: BoxFit.cover,
                                  ),
                                  
                                  // Subtle gradient overlay at bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.1),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Modern page indicator
                if (widget.images.length > 1)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            widget.images.length,
                            (index) {
                              final isActive = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: EdgeInsets.only(
                                  right: index == (widget.images.length - 1) ? 0 : 8,
                                ),
                                width: isActive ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Image counter with modern design
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentPage + 1} / ${widget.images.length}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
