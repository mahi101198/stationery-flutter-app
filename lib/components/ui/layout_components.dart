import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

/// Modern app bar with gradient and smooth animations
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: DesignSystem.typography.titleLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      elevation: elevation ?? 0,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? TColors.primary,
              backgroundColor?.withValues(alpha: 0.8) ?? TColors.primary.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: elevation != 0 ? DesignSystem.shadows.elevation2 : null,
        ),
      ),
    );
  }
}

/// Modern bottom navigation with smooth transitions
class ModernBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final double? elevation;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.elevation,
  });

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: DesignSystem.animations.normal,
        vsync: this,
      ),
    );
    _animations = _controllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: DesignSystem.animations.easeOut),
            ))
        .toList();

    // Animate current tab
    if (widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(ModernBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      // Reset all animations
      for (var controller in _controllers) {
        controller.reverse();
      }
      // Animate new tab
      if (widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        boxShadow: widget.elevation != 0 ? DesignSystem.shadows.elevation3 : null,
        borderRadius: BorderRadius.vertical(top: DesignSystem.borders.lg.topLeft),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isSelected = index == widget.currentIndex;

              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onTap(index);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing.md,
                        vertical: DesignSystem.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? TColors.primary.withValues(alpha: 0.1 * _animations[index].value)
                            : Colors.transparent,
                        borderRadius: DesignSystem.borders.full,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: 1.0 + (0.2 * _animations[index].value),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: Color.lerp(
                                TColors.textSecondary,
                                TColors.primary,
                                _animations[index].value,
                              ),
                              size: 24,
                            ),
                          ),
                          SizedBox(height: 4),
                          Transform.scale(
                            scale: 1.0 + (0.1 * _animations[index].value),
                            child: Text(
                              item.label,
                              style: DesignSystem.typography.labelSmall.copyWith(
                                color: Color.lerp(
                                  TColors.textSecondary,
                                  TColors.primary,
                                  _animations[index].value,
                                ),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Modern floating action button with animation
class ModernFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;

  const ModernFAB({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
  });

  @override
  State<ModernFAB> createState() => _ModernFABState();
}

class _ModernFABState extends State<ModernFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignSystem.animations.normal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: DesignSystem.animations.easeOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: DesignSystem.animations.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton(
              onPressed: widget.onPressed == null ? null : () {
                HapticFeedback.mediumImpact();
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                widget.onPressed!();
              },
              tooltip: widget.tooltip,
              backgroundColor: widget.backgroundColor ?? TColors.primary,
              foregroundColor: widget.foregroundColor ?? Colors.white,
              elevation: 8,
              child: widget.isExtended && widget.label != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon),
                        SizedBox(width: DesignSystem.spacing.sm),
                        Text(
                          widget.label!,
                          style: DesignSystem.typography.labelMedium.copyWith(
                            color: widget.foregroundColor ?? Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Icon(widget.icon),
            ),
          ),
        );
      },
    );
  }
}

/// Modern drawer with smooth animations
class ModernDrawer extends StatelessWidget {
  final Widget? header;
  final List<DrawerItem> items;
  final ValueChanged<int>? onItemTap;
  final int? selectedIndex;

  const ModernDrawer({
    super.key,
    this.header,
    required this.items,
    this.onItemTap,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              TColors.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (header != null) header!,
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = selectedIndex == index;

              return AnimatedContainer(
                duration: DesignSystem.animations.fast,
                margin: EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacing.md,
                  vertical: DesignSystem.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? TColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: DesignSystem.borders.lg,
                ),
                child: ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? TColors.primary : TColors.textSecondary,
                  ),
                  title: Text(
                    item.title,
                    style: DesignSystem.typography.bodyMedium.copyWith(
                      color: isSelected ? TColors.primary : TColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onItemTap?.call(index);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Modern tab bar with smooth indicators
class ModernTabBar extends StatefulWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? indicatorColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  const ModernTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.indicatorColor,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  State<ModernTabBar> createState() => _ModernTabBarState();
}

class _ModernTabBarState extends State<ModernTabBar>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: DesignSystem.animations.normal,
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(
      CurvedAnimation(parent: _indicatorController, curve: DesignSystem.animations.easeOut),
    );
  }

  @override
  void didUpdateWidget(ModernTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _indicatorAnimation = Tween<double>(
        begin: _indicatorAnimation.value,
        end: widget.currentIndex.toDouble(),
      ).animate(
        CurvedAnimation(parent: _indicatorController, curve: DesignSystem.animations.easeOut),
      );
      _indicatorController.reset();
      _indicatorController.forward();
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: DesignSystem.shadows.elevation1,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: widget.tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = index == widget.currentIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onTap(index);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: DesignSystem.animations.fast,
                        style: DesignSystem.typography.labelLarge.copyWith(
                          color: isSelected 
                              ? widget.selectedColor ?? TColors.primary
                              : widget.unselectedColor ?? TColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        child: Text(tab),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 3,
            child: AnimatedBuilder(
              animation: _indicatorAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      left: _indicatorAnimation.value * MediaQuery.of(context).size.width / widget.tabs.length,
                      child: Container(
                        width: MediaQuery.of(context).size.width / widget.tabs.length,
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.indicatorColor ?? TColors.primary,
                          borderRadius: DesignSystem.borders.full,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern page transition builder
class ModernPageTransition extends PageRouteBuilder {
  final Widget child;
  final TransitionType transitionType;

  ModernPageTransition({
    required this.child,
    this.transitionType = TransitionType.slideFromRight,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: DesignSystem.animations.normal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case TransitionType.slideFromRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: DesignSystem.animations.easeOut,
                  )),
                  child: child,
                );
              case TransitionType.slideFromLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: DesignSystem.animations.easeOut,
                  )),
                  child: child,
                );
              case TransitionType.slideFromBottom:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: DesignSystem.animations.easeOut,
                  )),
                  child: child,
                );
              case TransitionType.fade:
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              case TransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.8,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: DesignSystem.animations.easeOut,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
            }
          },
        );
}

/// Supporting models and enums
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class DrawerItem {
  final IconData icon;
  final String title;

  DrawerItem({
    required this.icon,
    required this.title,
  });
}

enum TransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  fade,
  scale,
}
