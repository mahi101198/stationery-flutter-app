import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/modern_components.dart' show ButtonVariant, ButtonSize;
import 'package:rps_stationery/utils/animations/micro_animations.dart';
import 'package:rps_stationery/utils/constants/app_spacing.dart';
import 'package:rps_stationery/utils/helpers/overflow_helpers.dart';

/// =====================================================
/// THEME-AWARE UI COMPONENTS
/// Works with both light and dark themes using the existing theme system
/// =====================================================

/// Theme-aware Button Component
class ThemeAwareButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool isLoading;
  final bool isDisabled;

  const ThemeAwareButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.fullWidth = false,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<ThemeAwareButton> createState() => _ThemeAwareButtonState();
}

class _ThemeAwareButtonState extends State<ThemeAwareButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Button styling based on variant and theme
    Color backgroundColor;
    Color textColor;
    Color? borderColor;
    Decoration? decoration;

    double height;
    double fontSize;
    double horizontalPadding;

    // Size configuration
    switch (widget.size) {
      case ButtonSize.small:
        height = AppSpacing.custom(4.5); // 36dp
        fontSize = 12;
        horizontalPadding = AppSpacing.md;
        break;
      case ButtonSize.medium:
        height = AppSpacing.custom(6); // 48dp
        fontSize = 14;
        horizontalPadding = AppSpacing.lg;
        break;
      case ButtonSize.large:
        height = AppSpacing.custom(7); // 56dp
        fontSize = 16;
        horizontalPadding = AppSpacing.xl;
        break;
    }

    // Variant configuration using theme colors
    if (widget.isDisabled) {
      backgroundColor = theme.disabledColor;
      textColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else {
      switch (widget.variant) {
        case ButtonVariant.primary:
          backgroundColor = Colors.transparent;
          textColor = colorScheme.onPrimary;
          decoration = BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          );
          break;
        case ButtonVariant.secondary:
          backgroundColor = Colors.transparent;
          textColor = colorScheme.primary;
          borderColor = colorScheme.primary;
          decoration = BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(25),
          );
          break;
        case ButtonVariant.ghost:
          backgroundColor = Colors.transparent;
          textColor = colorScheme.primary;
          break;
        case ButtonVariant.success:
          backgroundColor = Colors.transparent;
          textColor = colorScheme.onPrimary;
          decoration = BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.withValues(alpha: 0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          );
          break;
        case ButtonVariant.error:
        case ButtonVariant.danger:
          backgroundColor = Colors.transparent;
          textColor = colorScheme.onError;
          decoration = BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.error, colorScheme.error.withValues(alpha: 0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: colorScheme.error.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          );
          break;
      }
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              height: height,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: decoration ??
                  BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(25),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 1.5)
                        : null,
                  ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isDisabled || widget.isLoading
                      ? null
                      : widget.onPressed,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(textColor),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate available space for content
                              final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
                              final hasIcon = widget.icon != null;
                              final iconSize = hasIcon ? 18.0 : 0.0;
                              final spacingSize = hasIcon ? AppSpacing.sm : 0.0;
                              final textAvailableWidth = availableWidth - iconSize - spacingSize;
                              
                              // If not enough space, show icon only or adapt layout
                              if (availableWidth < 60 && hasIcon) {
                                return Icon(
                                  widget.icon,
                                  color: textColor,
                                  size: 18,
                                );
                              }
                              
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasIcon && textAvailableWidth > 40) ...[
                                    Icon(
                                      widget.icon,
                                      color: textColor,
                                      size: 18,
                                    ),
                    SizedBox(width: AppSpacing.sm),
                                  ],
                                  Flexible(
                                    child: OverflowHelpers.safeText(
                                      widget.text,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Theme-aware Card Component
class ThemeAwareCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool hasGradientBorder;
  final List<BoxShadow>? boxShadow;
  final double elevation;

  const ThemeAwareCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.hasGradientBorder = false,
    this.boxShadow,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Widget cardContent = Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation * 0.5),
            spreadRadius: elevation * 0.2,
          ),
        ],
        border: hasGradientBorder
            ? null
            : Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
      ),
      child: child,
    );

    if (hasGradientBorder) {
      cardContent = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.3),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.all(1.5), // Border width
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(borderRadius - 1.5),
          ),
          padding: padding ?? EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      );
    }

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    Widget result = cardContent;
    if (margin != null) {
      result = Container(
        margin: margin,
        child: result,
      );
    }

    return MicroAnimations.fadeSlideIn(
      duration: MicroAnimations.normal,
      slideOffset: 10.0,
      child: result,
    );
  }
}

/// Theme-aware Text Field Component
class ThemeAwareTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isPassword;
  final bool isEnabled;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final EdgeInsetsGeometry? contentPadding;

  const ThemeAwareTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isPassword = false,
    this.isEnabled = true,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.contentPadding,
  });

  @override
  State<ThemeAwareTextField> createState() => _ThemeAwareTextFieldState();
}

class _ThemeAwareTextFieldState extends State<ThemeAwareTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword,
          enabled: widget.isEnabled,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      widget.suffixIcon,
                      color: _isFocused
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: widget.onSuffixIconPressed,
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2, // 14dp
            ),
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Theme-aware Search Bar Component
class ThemeAwareSearchBar extends StatefulWidget {
  final String hint;
  final Function(String) onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool showFilter;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const ThemeAwareSearchBar({
    super.key,
    this.hint = "Search products...",
    required this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.showFilter = false,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<ThemeAwareSearchBar> createState() => _ThemeAwareSearchBarState();
}

class _ThemeAwareSearchBarState extends State<ThemeAwareSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _controllerOwned = false;
  bool _focusNodeOwned = false;

  @override
  void initState() {
    super.initState();
    
    // Use provided controller or create new one
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _controllerOwned = true;
    }
    
    // Use provided focus node or create new one
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _focusNodeOwned = true;
    }
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    
    // Auto focus if requested
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (_focusNodeOwned) {
      _focusNode.dispose();
    }
    if (_controllerOwned) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.searchBarRadius),
        border: Border.all(
          color: _isFocused
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.5),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Iconsax.close_circle,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md - 4, // 12dp
                ),
              ),
            ),
          ),
          if (widget.showFilter && widget.onFilterTap != null)
            Container(
              margin: EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: Icon(
                  Iconsax.filter,
                  color: colorScheme.primary,
                  size: 20,
                ),
                onPressed: widget.onFilterTap,
              ),
            ),
        ],
      ),
    );
  }
}


