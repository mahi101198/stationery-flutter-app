import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/cart/cart_screen.dart';
import 'package:rps_stationery/features/home/home_screen.dart';
import 'package:rps_stationery/features/personalization/screens/profile_screen.dart';
import 'package:rps_stationery/features/wishlist/wishlist_screen.dart';
import 'package:rps_stationery/features/category/optimized_category_screen.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';

class BottomNavigationMenu extends StatefulWidget {
  const BottomNavigationMenu({super.key});

  @override
  State<BottomNavigationMenu> createState() => _BottomNavigationMenuState();
}

class _BottomNavigationMenuState extends State<BottomNavigationMenu> {
  final labels = ["Home", "Category", "Cart", "Wishlist", "Profile"];
  final List<Widget> _pages = const [
    HomeScreen(),
    OptimizedCategoryScreen(),
    CartScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg != null) {
      if (arg == 'cart') {
        _currentIndex = 2; // Cart is now at index 2
      } else if (arg == 'home') {
        _currentIndex = 0;
      } else if (arg == 'category') {
        _currentIndex = 1;
      } else if (arg == 'wishlist') {
        _currentIndex = 3;
      } else if (arg == 'profile') {
        _currentIndex = 4;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => const _ExitConfirmationDialog(),
          );
          return shouldExit ?? false;
        }
      },
      child: Scaffold(
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: SafeArea(
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    // Special handling for cart icon (index 2) to show badge
                    if (index == 2) {
                      return Obx(() {
                        final cartController = CartController.instance;
                        final cartCount = cartController.totalItemsCount;
                        return _ModernNavItem(
                          icon: _getIcon(index, false),
                          activeIcon: _getIcon(index, true),
                          label: labels[index],
                          isSelected: _currentIndex == index,
                          badgeCount: cartCount,
                          onTap: () {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                        );
                      });
                    }
                    return _ModernNavItem(
                      icon: _getIcon(index, false),
                      activeIcon: _getIcon(index, true),
                      label: labels[index],
                      isSelected: _currentIndex == index,
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        body: _pages[_currentIndex],
      ),
    );
  }

  IconData _getIcon(int index, bool isActive) {
    switch (index) {
      case 0:
        return isActive ? Iconsax.home_15 : Iconsax.home;
      case 1:
        return isActive ? Iconsax.category_25 : Iconsax.category;
      case 2:
        return isActive ? Iconsax.shopping_cart5 : Iconsax.shopping_cart;
      case 3:
        return isActive ? Iconsax.heart5 : Iconsax.heart;
      case 4:
        return isActive ? Iconsax.profile_circle5 : Iconsax.profile_circle;
      default:
        return Iconsax.home;
    }
  }
}

// Modern navigation item with smooth animations
class _ModernNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _ModernNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_ModernNavItem> createState() => _ModernNavItemState();
}

class _ModernNavItemState extends State<_ModernNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_ModernNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon container with background
                  SizedBox(
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated background
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: widget.isSelected ? 48 : 0,
                          height: 28,
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? primaryColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        // Icon
                        Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Icon(
                            widget.isSelected ? widget.activeIcon : widget.icon,
                            size: 22,
                            color: widget.badgeCount > 0
                                ? primaryColor
                                : widget.isSelected
                                    ? primaryColor
                                    : onSurfaceColor.withValues(alpha: 0.6),
                          ),
                        ),
                        // Badge
                        if (widget.badgeCount > 0)
                          Positioned(
                            top: -2,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                widget.badgeCount > 99 
                                    ? '99+' 
                                    : widget.badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: widget.badgeCount > 0 || widget.isSelected
                          ? primaryColor
                          : onSurfaceColor.withValues(alpha: 0.6),
                      fontWeight: widget.badgeCount > 0 || widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExitConfirmationDialog extends StatelessWidget {
  const _ExitConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.logout,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Exit App',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to exit?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AnimatedExitButton(
                    text: 'No',
                    onTap: () => Navigator.of(context).pop(false),
                    isPrimary: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedExitButton(
                    text: 'Yes',
                    onTap: () => Navigator.of(context).pop(true),
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedExitButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;

  const _AnimatedExitButton({
    required this.text,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  State<_AnimatedExitButton> createState() => _AnimatedExitButtonState();
}

class _AnimatedExitButtonState extends State<_AnimatedExitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? Colors.red
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: widget.isPrimary
                  ? null
                  : Border.all(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
              boxShadow: widget.isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.isPrimary
                      ? Colors.white
                      : theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
