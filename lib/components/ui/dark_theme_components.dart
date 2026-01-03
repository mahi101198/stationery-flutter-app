import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/utils/constants/dark_theme_colors.dart';

/// =====================================================
/// DARK THEME UI COMPONENTS
/// Following the comprehensive design guide
/// =====================================================

/// Dark Theme Button Component
class DarkThemeButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool isLoading;
  final bool isDisabled;

  const DarkThemeButton({
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
  State<DarkThemeButton> createState() => _DarkThemeButtonState();
}

class _DarkThemeButtonState extends State<DarkThemeButton>
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
    // Button styling based on variant
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
        height = 36;
        fontSize = 12;
        horizontalPadding = 16;
        break;
      case ButtonSize.medium:
        height = 48;
        fontSize = 14;
        horizontalPadding = 20;
        break;
      case ButtonSize.large:
        height = 56;
        fontSize = 16;
        horizontalPadding = 24;
        break;
    }

    // Variant configuration
    if (widget.isDisabled) {
      backgroundColor = DarkThemeColors.buttonDisabled;
      textColor = DarkThemeColors.buttonDisabledText;
    } else {
      switch (widget.variant) {
        case ButtonVariant.primary:
          backgroundColor = Colors.transparent;
          textColor = DarkThemeColors.buttonPrimaryText;
          decoration = BoxDecoration(
            gradient: DarkThemeColors.primaryButtonGradient,
            borderRadius: BorderRadius.circular(DarkThemeColors.radiusPill),
            boxShadow: DarkThemeColors.elevation2,
          );
          break;
        case ButtonVariant.secondary:
          backgroundColor = DarkThemeColors.buttonSecondary;
          textColor = DarkThemeColors.buttonSecondaryText;
          borderColor = DarkThemeColors.buttonSecondaryBorder;
          decoration = BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(DarkThemeColors.radiusPill),
          );
          break;
        case ButtonVariant.ghost:
          backgroundColor = Colors.transparent;
          textColor = DarkThemeColors.buttonSecondaryText;
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
                    borderRadius:
                        BorderRadius.circular(DarkThemeColors.radiusPill),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 1)
                        : null,
                  ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isDisabled || widget.isLoading
                      ? null
                      : widget.onPressed,
                  borderRadius: BorderRadius.circular(DarkThemeColors.radiusPill),
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
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: textColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
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
  }
}

/// Dark Theme Card Component
class DarkThemeCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool hasGradientBorder;
  final List<BoxShadow>? boxShadow;

  const DarkThemeCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.hasGradientBorder = false,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(DarkThemeColors.spacingMD),
      decoration: BoxDecoration(
        color: DarkThemeColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? DarkThemeColors.elevation1,
        border: hasGradientBorder
            ? null
            : Border.all(
                color: DarkThemeColors.cardBorder,
                width: 1,
              ),
      ),
      child: child,
    );

    if (hasGradientBorder) {
      cardContent = Container(
        decoration: BoxDecoration(
          gradient: DarkThemeColors.cardHighlightGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.all(1), // Border width
        child: Container(
          decoration: BoxDecoration(
            color: DarkThemeColors.cardBackground,
            borderRadius: BorderRadius.circular(borderRadius - 1),
          ),
          padding: padding ?? const EdgeInsets.all(DarkThemeColors.spacingMD),
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

    if (margin != null) {
      return Container(
        margin: margin,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Dark Theme Text Field Component
class DarkThemeTextField extends StatefulWidget {
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

  const DarkThemeTextField({
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
  State<DarkThemeTextField> createState() => _DarkThemeTextFieldState();
}

class _DarkThemeTextFieldState extends State<DarkThemeTextField> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              color: DarkThemeColors.formFieldLabel,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
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
          style: const TextStyle(
            color: DarkThemeColors.formFieldText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: DarkThemeColors.formFieldPlaceholder,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused
                        ? DarkThemeColors.formFieldBorderFocused
                        : DarkThemeColors.formFieldPlaceholder,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      widget.suffixIcon,
                      color: _isFocused
                          ? DarkThemeColors.formFieldBorderFocused
                          : DarkThemeColors.formFieldPlaceholder,
                      size: 20,
                    ),
                    onPressed: widget.onSuffixIconPressed,
                  )
                : null,
            filled: true,
            fillColor: DarkThemeColors.formFieldBackground,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkThemeColors.radiusMedium),
              borderSide: const BorderSide(
                color: DarkThemeColors.formFieldBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkThemeColors.radiusMedium),
              borderSide: const BorderSide(
                color: DarkThemeColors.formFieldBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkThemeColors.radiusMedium),
              borderSide: const BorderSide(
                color: DarkThemeColors.formFieldBorderFocused,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkThemeColors.radiusMedium),
              borderSide: const BorderSide(
                color: DarkThemeColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkThemeColors.radiusMedium),
              borderSide: const BorderSide(
                color: DarkThemeColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DarkThemeColors.radiusMedium),
              borderSide: const BorderSide(
                color: DarkThemeColors.borderPrimary,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark Theme Search Bar Component
class DarkThemeSearchBar extends StatefulWidget {
  final String hint;
  final Function(String) onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool showFilter;

  const DarkThemeSearchBar({
    super.key,
    this.hint = "Search products...",
    required this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.showFilter = false,
  });

  @override
  State<DarkThemeSearchBar> createState() => _DarkThemeSearchBarState();
}

class _DarkThemeSearchBarState extends State<DarkThemeSearchBar> {
  final TextEditingController _controller = TextEditingController();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DarkThemeColors.searchBarBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused
              ? DarkThemeColors.formFieldBorderFocused
              : DarkThemeColors.borderPrimary,
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
              onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
              style: const TextStyle(
                color: DarkThemeColors.searchBarText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: DarkThemeColors.searchBarPlaceholder,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color: _isFocused
                      ? DarkThemeColors.searchBarIcon
                      : DarkThemeColors.searchBarPlaceholder,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Iconsax.close_circle,
                          color: DarkThemeColors.searchBarPlaceholder,
                          size: 20,
                        ),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (widget.showFilter && widget.onFilterTap != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(
                  Iconsax.filter,
                  color: DarkThemeColors.searchBarIcon,
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

/// Dark Theme App Bar Component
class DarkThemeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool hasBackButton;
  final VoidCallback? onBackPressed;

  const DarkThemeAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.hasBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DarkThemeColors.appBarBackground,
        border: Border(
          bottom: BorderSide(
            color: DarkThemeColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,
        leading: leading ??
            (hasBackButton
                ? IconButton(
                    icon: const Icon(
                      Iconsax.arrow_left,
                      color: DarkThemeColors.appBarIconInactive,
                    ),
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                  )
                : null),
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(
                  color: DarkThemeColors.appBarText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        actions: actions,
        iconTheme: const IconThemeData(
          color: DarkThemeColors.appBarIconInactive,
        ),
      ),
    );
  }
}

/// Button variants enum
enum ButtonVariant { primary, secondary, ghost }

/// Button sizes enum
enum ButtonSize { small, medium, large }

/// Dark Theme Bottom Navigation Bar Component
class DarkThemeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<DarkThemeNavItem> items;

  const DarkThemeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DarkThemeColors.bottomNavBackground,
        border: Border(
          top: BorderSide(
            color: DarkThemeColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = index == currentIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? DarkThemeColors.bottomNavActiveIcon
                                : DarkThemeColors.bottomNavInactiveIcon,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? DarkThemeColors.bottomNavActiveText
                                  : DarkThemeColors.bottomNavInactiveText,
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Dark Theme Navigation Item
class DarkThemeNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const DarkThemeNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
