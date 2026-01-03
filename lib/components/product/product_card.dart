import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/product_model.dart';

import '../network_image_with_loader.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.press,
    this.width = 140,
    this.isCompact = false,
  });

  final ProductModel product;
  final VoidCallback press;
  final double width;
  final bool isCompact;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.press();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final discountPercent =
        widget.product.hasDiscount ? widget.product.discount.round() : null;
    
    // Build layout to determine actual width for responsive design
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use actual constraint width, or widget.width if specified
        final actualWidth = constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : widget.width;
        
        // Determine if this is a very small card (category grid)
        final isVerySmall = actualWidth < 100;
        final borderRadius = isVerySmall ? 12.0 : 16.0;
        final horizontalMargin = isVerySmall ? 2.0 : 4.0;
        final verticalMargin = isVerySmall ? 2.0 : 4.0;

        return GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: constraints.maxWidth.isFinite ? null : widget.width,
                  margin: EdgeInsets.symmetric(
                    horizontal: horizontalMargin,
                    vertical: verticalMargin,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      // Primary shadow
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : theme.colorScheme.primary.withValues(alpha: 
                                0.08 + (_elevationAnimation.value * 0.12)),
                        blurRadius: (isVerySmall ? 8 : 12) + (_elevationAnimation.value * 6),
                        offset: Offset(0, (isVerySmall ? 2 : 4) + (_elevationAnimation.value * 3)),
                        spreadRadius: 0,
                      ),
                      // Secondary shadow for depth
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 
                                0.04 + (_elevationAnimation.value * 0.06)),
                        blurRadius: (isVerySmall ? 4 : 6) + (_elevationAnimation.value * 3),
                        offset: Offset(0, (isVerySmall ? 1 : 2) + (_elevationAnimation.value * 1.5)),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.surface.withValues(alpha: 0.95),
                                  theme.colorScheme.surface.withValues(alpha: 0.85),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.98),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : theme.colorScheme.primary.withValues(alpha: 
                                  0.05 + (_elevationAnimation.value * 0.1)),
                          width: isVerySmall ? 0.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Product Image with enhanced styling
                            _buildProductImage(context, isDark, discountPercent, isVerySmall, borderRadius, actualWidth),

                            // Product Details Section
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                isVerySmall ? 4 : 8,
                                isVerySmall ? 3 : 5,
                                isVerySmall ? 4 : 8,
                                isVerySmall ? 4 : 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Name
                                  _buildProductName(theme, isDark, isVerySmall),

                                  SizedBox(height: isVerySmall ? 2 : 3),

                                  // Price Section
                                  _buildPriceSection(theme, isDark, isVerySmall),
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
            },
          ),
        );
      },
    );
  }

  Widget _buildProductImage(
      BuildContext context, bool isDark, int? discountPercent, bool isVerySmall, double borderRadius, double actualWidth) {
    final theme = Theme.of(context);
    final imageHeight = actualWidth * (isVerySmall ? 0.68 : 0.75);

    return Stack(
      children: [
        // Main Image Container
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                    ]
                  : [
                      theme.colorScheme.primary.withValues(alpha: 0.03),
                      theme.colorScheme.primary.withValues(alpha: 0.01),
                    ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            child: widget.product.displayImage.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageWithLoader(
                        widget.product.displayImage,
                        radius: 0,
                      ),
                      // Subtle gradient overlay for better text readability (skip for very small)
                      if (!isVerySmall)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.08),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : _buildNoImagePlaceholder(theme, isDark, isVerySmall),
          ),
        ),

        // Discount badge with modern design
        if (discountPercent != null) _buildDiscountBadge(discountPercent, isDark, isVerySmall),

        // Shimmer effect on hover (optional decorative element, skip for very small)
        if (_isPressed && !isVerySmall)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoImagePlaceholder(ThemeData theme, bool isDark, bool isVerySmall) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHigh,
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(isVerySmall ? 12 : 16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmall ? 4 : 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_outlined,
              size: isVerySmall ? 14 : 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          SizedBox(height: isVerySmall ? 3 : 6),
          if (!isVerySmall)
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(int discountPercent, bool isDark, bool isVerySmall) {
    return Positioned(
      top: isVerySmall ? 3 : 6,
      right: isVerySmall ? 3 : 6,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmall ? 4 : 6,
                vertical: isVerySmall ? 2 : 3,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFEE5A6F),
                  ],
                ),
                borderRadius: BorderRadius.circular(isVerySmall ? 4 : 6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                    blurRadius: isVerySmall ? 4 : 6,
                    offset: Offset(0, isVerySmall ? 1 : 2),
                  ),
                ],
              ),
              child: isVerySmall
                  ? Text(
                      "$discountPercent%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "$discountPercent% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductName(ThemeData theme, bool isDark, bool isVerySmall) {
    return Text(
      widget.product.name,
      maxLines: isVerySmall ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isVerySmall ? 9 : (widget.isCompact ? 11 : 11),
        fontWeight: FontWeight.w600,
        height: isVerySmall ? 1.15 : 1.2,
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.95)
            : theme.colorScheme.onSurface,
        letterSpacing: isVerySmall ? 0.1 : 0.15,
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme, bool isDark, bool isVerySmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MRP (crossed out) - only show if there's a discount and not very small
        if (widget.product.hasDiscount && !isVerySmall) ...[
          Text(
            "₹${widget.product.mrp.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: widget.isCompact ? 10 : 10,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              decoration: TextDecoration.lineThrough,
              decorationColor: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              decorationThickness: 1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
        ],
        // Selling Price with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDark
                ? [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ]
                : [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
          ).createShader(bounds),
          child: Text(
            "₹${widget.product.price.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isVerySmall ? 11 : (widget.isCompact ? 14 : 14),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: isVerySmall ? 0.15 : 0.2,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
