import 'package:flutter/material.dart';

/// ==========================
/// DESIGN TOKENS
/// ==========================
class AppColors {
  // Light Mode
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightPrimary = Color(0xFF1976D2);
  static const Color lightSecondary = Color(0xFF424242);
  static const Color lightText = Colors.black87;
  static const Color lightOnBackground = Colors.black87;
  static const Color lightOnSurfaceVariant = Colors.black54;
  static const Color lightError = Colors.red;

  // Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF90CAF9);
  static const Color darkSecondary = Color(0xFFBDBDBD);
  static const Color darkText = Colors.white70;
  static const Color darkOnBackground = Colors.white70;
  static const Color darkOnSurfaceVariant = Colors.white54;
  static const Color darkError = Colors.redAccent;
}

/// ==========================
/// TYPOGRAPHY
/// ==========================
class AppTypography {
  // Body Styles
  static const TextStyle lightBodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.lightText,
  );
  
  static const TextStyle lightBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.lightText,
  );

  static const TextStyle darkBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkText,
  );
  
  // Headline Styles
  static const TextStyle lightHeadlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.lightText,
  );
  
  static const TextStyle lightHeadlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.lightText,
  );
  
  // Label Styles
  static const TextStyle lightLabelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
  );
  
  static const TextStyle lightLabelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.lightText,
  );
}

/// Extension for quick access to modified text styles
extension TextThemeX on TextTheme {
  TextStyle get bodyMediumBold => bodyMedium?.copyWith(fontWeight: FontWeight.w600) ?? const TextStyle();
  TextStyle get bodyMediumMuted => bodyMedium?.copyWith(color: Colors.grey) ?? const TextStyle();
}

/// ==========================
/// ENHANCED BUTTON
/// ==========================
enum EnhancedButtonVariant { primary, secondary, ghost, danger }
enum EnhancedButtonSize { small, medium, large }

class EnhancedButton extends StatefulWidget {
  final String label;
  final String? text; // Added for compatibility
  final VoidCallback onPressed;
  final bool isPrimary;
  final EnhancedButtonVariant? variant;
  final EnhancedButtonSize? size;
  final bool fullWidth;
  final IconData? icon;
  final bool isDisabled;
  final String? tooltip;
  final double minWidth;

  const EnhancedButton({
    super.key,
    this.label = '',
    this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.variant,
    this.size,
    this.fullWidth = false,
    this.icon,
    this.isDisabled = false,
    this.tooltip,
    this.minWidth = 120,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine button styling based on variant
    final effectiveVariant = widget.variant ?? (widget.isPrimary ? EnhancedButtonVariant.primary : EnhancedButtonVariant.secondary);
    final effectiveSize = widget.size ?? EnhancedButtonSize.medium;
    
    Color bgColor;
    Color textColor;
    
    switch (effectiveVariant) {
      case EnhancedButtonVariant.primary:
        bgColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        textColor = Colors.white;
        break;
      case EnhancedButtonVariant.secondary:
        bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
        textColor = isDark ? AppColors.darkText : AppColors.lightText;
        break;
      case EnhancedButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
        break;
      case EnhancedButtonVariant.danger:
        bgColor = isDark ? AppColors.darkError : AppColors.lightError;
        textColor = Colors.white;
        break;
    }
    
    // Size-based dimensions
    double fontSize;
    double height;
    double horizontalPadding;
    
    switch (effectiveSize) {
      case EnhancedButtonSize.small:
        fontSize = 12;
        height = 36;
        horizontalPadding = 12;
        break;
      case EnhancedButtonSize.medium:
        fontSize = 14;
        height = 48;
        horizontalPadding = 16;
        break;
      case EnhancedButtonSize.large:
        fontSize = 16;
        height = 56;
        horizontalPadding = 20;
        break;
    }

    final displayText = widget.text ?? widget.label;
    
    return Semantics(
      button: true,
      label: displayText,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final elevation = (_elevationAnimation.value).clamp(0.0, 8.0).toDouble();
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                elevation: elevation,
                borderRadius: BorderRadius.circular(12),
                color: widget.isDisabled ? Colors.grey.shade400 : bgColor,
                child: InkWell(
                  onTap: widget.isDisabled ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: widget.fullWidth ? double.infinity : widget.minWidth,
                      minHeight: height,
                    ),
                    width: widget.fullWidth ? double.infinity : null,
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null)
                          Icon(widget.icon, color: textColor, size: 20),
                        if (widget.icon != null) const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            displayText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ==========================
/// ENHANCED CARD
/// ==========================
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;
  final bool isGradient;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const EnhancedCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 4,
    this.isGradient = false,
    this.gradientColors,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardWidget = Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: isGradient
                ? null
                : backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
            gradient: isGradient
                ? LinearGradient(
              colors: gradientColors ??
                  [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: padding != null ? Padding(
            padding: padding!,
            child: child,
          ) : child,
        ),
      ),
    );
    
    if (margin != null) {
      return Container(
        margin: margin,
        child: cardWidget,
      );
    }
    
    return cardWidget;
  }
}

/// ==========================
/// ENHANCED TEXT FIELD
/// ==========================
class EnhancedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final String? errorText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      decoration: InputDecoration(
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

/// ==========================
/// ENHANCED SEARCH BAR
/// ==========================
class EnhancedSearchBar extends StatefulWidget {
  final String hintText;
  final String? hint; // Added for compatibility
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final VoidCallback? onFilterTap;

  const EnhancedSearchBar({
    super.key,
    this.hintText = '',
    this.hint,
    required this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.onFilterTap,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayHint = widget.hint ?? widget.hintText;

    return Semantics(
      textField: true,
      hint: displayHint,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          return TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: displayHint,
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onClear?.call();
                },
              )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// ==========================
/// ENHANCED LOADING INDICATOR
/// ==========================
class EnhancedLoadingIndicator extends StatelessWidget {
  final String? message;

  const EnhancedLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
