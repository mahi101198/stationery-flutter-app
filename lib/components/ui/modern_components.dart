import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

/// Modern animated button with micro-interactions
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final Widget? child;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.fullWidth = false,
    this.child,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: DesignSystem.animations.fast,
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: DesignSystem.animations.normal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: DesignSystem.animations.easeInOut),
    );
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: DesignSystem.animations.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.forward();
      _rippleController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.reverse();
      _rippleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.reverse();
      _rippleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEffectivelyDisabled = widget.isDisabled || widget.isLoading;
    final buttonTheme = _getButtonTheme();
    final sizeTheme = _getSizeTheme();

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _rippleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: isEffectivelyDisabled ? null : widget.onPressed,
            child: AnimatedContainer(
              duration: DesignSystem.animations.fast,
              width: widget.fullWidth ? double.infinity : null,
              height: sizeTheme.height,
              padding: sizeTheme.padding,
              decoration: BoxDecoration(
                color: isEffectivelyDisabled 
                    ? buttonTheme.disabledBackgroundColor 
                    : buttonTheme.backgroundColor,
                borderRadius: DesignSystem.borders.lg,
                border: buttonTheme.border,
                boxShadow: isEffectivelyDisabled 
                    ? null 
                    : buttonTheme.shadows,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ripple effect
                  if (!isEffectivelyDisabled)
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: buttonTheme.rippleColor.withValues(alpha: 
                              _rippleAnimation.value * 0.2,
                            ),
                            borderRadius: DesignSystem.borders.lg,
                          ),
                        );
                      },
                    ),
                  // Content
                  AnimatedOpacity(
                    opacity: widget.isLoading ? 0.0 : 1.0,
                    duration: DesignSystem.animations.fast,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: sizeTheme.iconSize,
                            color: isEffectivelyDisabled
                                ? buttonTheme.disabledTextColor
                                : buttonTheme.textColor,
                          ),
                          SizedBox(width: DesignSystem.spacing.sm),
                        ],
                        widget.child ?? Text(
                          widget.text,
                          style: sizeTheme.textStyle.copyWith(
                            color: isEffectivelyDisabled
                                ? buttonTheme.disabledTextColor
                                : buttonTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Loading indicator
                  if (widget.isLoading)
                    SizedBox(
                      width: sizeTheme.iconSize,
                      height: sizeTheme.iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          buttonTheme.textColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _ButtonTheme _getButtonTheme() {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return _ButtonTheme(
          backgroundColor: TColors.primary,
          textColor: Colors.white,
          disabledBackgroundColor: TColors.grey,
          disabledTextColor: TColors.textSecondary,
          rippleColor: Colors.white,
          shadows: DesignSystem.shadows.primaryShadow(0.3),
        );
      case ButtonVariant.secondary:
        return _ButtonTheme(
          backgroundColor: Colors.transparent,
          textColor: TColors.primary,
          disabledBackgroundColor: Colors.transparent,
          disabledTextColor: TColors.grey,
          rippleColor: TColors.primary,
          border: Border.all(color: TColors.primary),
          shadows: DesignSystem.shadows.elevation1,
        );
      case ButtonVariant.ghost:
        return _ButtonTheme(
          backgroundColor: Colors.transparent,
          textColor: TColors.textPrimary,
          disabledBackgroundColor: Colors.transparent,
          disabledTextColor: TColors.grey,
          rippleColor: TColors.textPrimary,
        );
      case ButtonVariant.success:
        return _ButtonTheme(
          backgroundColor: TColors.success,
          textColor: Colors.white,
          disabledBackgroundColor: TColors.grey,
          disabledTextColor: TColors.textSecondary,
          rippleColor: Colors.white,
          shadows: DesignSystem.shadows.successShadow(0.3),
        );
      case ButtonVariant.error:
        return _ButtonTheme(
          backgroundColor: TColors.error,
          textColor: Colors.white,
          disabledBackgroundColor: TColors.grey,
          disabledTextColor: TColors.textSecondary,
          rippleColor: Colors.white,
          shadows: DesignSystem.shadows.errorShadow(0.3),
        );
      case ButtonVariant.danger:
        return _ButtonTheme(
          backgroundColor: TColors.error,
          textColor: Colors.white,
          disabledBackgroundColor: TColors.grey,
          disabledTextColor: TColors.textSecondary,
          rippleColor: Colors.white,
          shadows: DesignSystem.shadows.errorShadow(0.3),
        );
    }
  }

  _ButtonSizeTheme _getSizeTheme() {
    switch (widget.size) {
      case ButtonSize.small:
        return _ButtonSizeTheme(
          height: 32,
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing.md,
            vertical: DesignSystem.spacing.xs,
          ),
          textStyle: DesignSystem.typography.labelMedium,
          iconSize: 14,
        );
      case ButtonSize.medium:
        return _ButtonSizeTheme(
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing.lg,
            vertical: DesignSystem.spacing.md,
          ),
          textStyle: DesignSystem.typography.labelLarge,
          iconSize: 16,
        );
      case ButtonSize.large:
        return _ButtonSizeTheme(
          height: 52,
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing.xl,
            vertical: DesignSystem.spacing.lg,
          ),
          textStyle: DesignSystem.typography.titleMedium,
          iconSize: 18,
        );
    }
  }
}

/// Modern animated card with hover and tap effects
class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool isInteractive;
  final double? elevation;
  final Color? backgroundColor;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.isInteractive = true,
    this.elevation,
    this.backgroundColor,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: DesignSystem.animations.normal,
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: DesignSystem.animations.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: DesignSystem.animations.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              if (widget.isInteractive) {
                _hoverController.forward();
              }
            },
            onExit: (_) {
              if (widget.isInteractive) {
                _hoverController.reverse();
              }
            },
            child: GestureDetector(
              onTap: widget.onTap,
              onTapDown: (_) {
                if (widget.isInteractive) {
                  HapticFeedback.lightImpact();
                }
              },
              child: Container(
                padding: widget.padding ?? EdgeInsets.all(DesignSystem.spacing.md),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.white,
                  borderRadius: DesignSystem.borders.lg,
                  boxShadow: _getElevationShadows(),
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }

  List<BoxShadow> _getElevationShadows() {
    final baseElevation = widget.elevation ?? 2;
    final currentElevation = baseElevation + (_elevationAnimation.value * 4);
    
    if (currentElevation <= 1) return DesignSystem.shadows.elevation1;
    if (currentElevation <= 2) return DesignSystem.shadows.elevation2;
    if (currentElevation <= 3) return DesignSystem.shadows.elevation3;
    return DesignSystem.shadows.elevation4;
  }
}

/// Modern skeleton loader for loading states
class ModernSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final Widget? child;

  const ModernSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isLoading = true,
    this.child,
  });

  factory ModernSkeleton.text({
    Key? key,
    required double width,
    double height = 16,
    bool isLoading = true,
    Widget? child,
  }) {
    return ModernSkeleton(
      key: key,
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(4),
      isLoading: isLoading,
      child: child,
    );
  }

  factory ModernSkeleton.circle({
    Key? key,
    required double size,
    bool isLoading = true,
    Widget? child,
  }) {
    return ModernSkeleton(
      key: key,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      isLoading: isLoading,
      child: child,
    );
  }

  @override
  State<ModernSkeleton> createState() => _ModernSkeletonState();
}

class _ModernSkeletonState extends State<ModernSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    
    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(ModernSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading && widget.child != null) {
      return widget.child!;
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? DesignSystem.borders.sm,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: [
                TColors.grey.withValues(alpha: 0.1),
                TColors.grey.withValues(alpha: 0.3),
                TColors.grey.withValues(alpha: 0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Modern progress indicator
class ModernProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;

  const ModernProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 4,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: DesignSystem.typography.labelSmall,
          ),
          SizedBox(height: DesignSystem.spacing.xs),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? TColors.grey.withValues(alpha: 0.2),
            borderRadius: DesignSystem.borders.full,
          ),
          child: AnimatedContainer(
            duration: DesignSystem.animations.normal,
            curve: DesignSystem.animations.easeOut,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: color ?? TColors.primary,
                  borderRadius: DesignSystem.borders.full,
                  boxShadow: DesignSystem.shadows.primaryShadow(0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Supporting classes and enums
enum ButtonVariant { primary, secondary, ghost, success, error, danger }
enum ButtonSize { small, medium, large }

class _ButtonTheme {
  final Color backgroundColor;
  final Color textColor;
  final Color disabledBackgroundColor;
  final Color disabledTextColor;
  final Color rippleColor;
  final Border? border;
  final List<BoxShadow>? shadows;

  _ButtonTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.disabledBackgroundColor,
    required this.disabledTextColor,
    required this.rippleColor,
    this.border,
    this.shadows,
  });
}

class _ButtonSizeTheme {
  final double height;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final double iconSize;

  _ButtonSizeTheme({
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
  });
}
