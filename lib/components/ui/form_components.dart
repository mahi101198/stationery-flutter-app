import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

/// Modern animated text field with validation
class ModernTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late FocusNode _focusNode;

  bool get _hasText => widget.controller?.text.isNotEmpty ?? false;
  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasError => widget.errorText != null;
  bool get _shouldFloatLabel => _isFocused || _hasText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      duration: DesignSystem.animations.normal,
      vsync: this,
    );

    _borderColorAnimation = ColorTween(
      begin: TColors.borderPrimary,
      end: TColors.primary,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: DesignSystem.animations.easeOut),
    );

    _focusNode.addListener(_onFocusChanged);
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
    if (_shouldFloatLabel) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: DesignSystem.borders.md,
                border: Border.all(
                  color: _hasError 
                      ? TColors.error
                      : _isFocused 
                          ? _borderColorAnimation.value ?? TColors.primary
                          : TColors.borderPrimary,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                color: widget.enabled 
                    ? Colors.white
                    : TColors.grey.withValues(alpha: 0.1),
                boxShadow: _isFocused 
                    ? DesignSystem.shadows.elevation2
                    : DesignSystem.shadows.elevation1,
              ),
              child: Stack(
                children: [
                  // Input field
                  Padding(
                    padding: EdgeInsets.only(
                      left: widget.prefixIcon != null ? 48 : 16,
                      right: widget.suffixIcon != null ? 48 : 16,
                      top: _shouldFloatLabel && widget.label != null ? 24 : 16,
                      bottom: 16,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      onTap: widget.onTap,
                      obscureText: widget.obscureText,
                      enabled: widget.enabled,
                      readOnly: widget.readOnly,
                      keyboardType: widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      maxLines: widget.maxLines,
                      maxLength: widget.maxLength,
                      textCapitalization: widget.textCapitalization,
                      style: DesignSystem.typography.bodyLarge,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: DesignSystem.typography.bodyLarge.copyWith(
                          color: TColors.textSecondary,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  
                  // Floating label
                  if (widget.label != null)
                    Positioned(
                      left: widget.prefixIcon != null ? 48 : 16,
                      top: _shouldFloatLabel ? 8 : 16,
                      child: AnimatedDefaultTextStyle(
                        duration: DesignSystem.animations.fast,
                        style: _shouldFloatLabel
                            ? DesignSystem.typography.labelMedium.copyWith(
                                color: _hasError 
                                    ? TColors.error
                                    : _isFocused 
                                        ? TColors.primary 
                                        : TColors.textSecondary,
                              )
                            : DesignSystem.typography.bodyLarge.copyWith(
                                color: TColors.textSecondary,
                              ),
                        child: Text(widget.label!),
                      ),
                    ),
                  
                  // Prefix icon
                  if (widget.prefixIcon != null)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          widget.prefixIcon,
                          color: _hasError 
                              ? TColors.error
                              : _isFocused 
                                  ? TColors.primary 
                                  : TColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  
                  // Suffix icon
                  if (widget.suffixIcon != null)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(child: widget.suffixIcon!),
                    ),
                ],
              ),
            );
          },
        ),
        
        // Helper/Error text
        if (widget.helperText != null || widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              top: DesignSystem.spacing.xs,
            ),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: DesignSystem.typography.labelSmall.copyWith(
                color: widget.errorText != null ? TColors.error : TColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Modern dropdown field with search and animations
class ModernDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool searchable;

  const ModernDropdown({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.searchable = false,
  });

  @override
  State<ModernDropdown<T>> createState() => _ModernDropdownState<T>();
}

class _ModernDropdownState<T> extends State<ModernDropdown<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<DropdownItem<T>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignSystem.animations.fast,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: DesignSystem.animations.easeOut),
    );
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _closeDropdown();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (!widget.enabled) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() {
      _isOpen = true;
    });
    HapticFeedback.lightImpact();
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _animationController.reverse();
    setState(() {
      _isOpen = false;
    });
    _searchController.clear();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.label.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 8,
            borderRadius: DesignSystem.borders.lg,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: DesignSystem.borders.lg,
                boxShadow: DesignSystem.shadows.elevation3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.searchable) ...[
                    Padding(
                      padding: EdgeInsets.all(DesignSystem.spacing.sm),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterItems,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: DesignSystem.borders.md,
                            borderSide: BorderSide(color: TColors.borderPrimary),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: DesignSystem.spacing.md,
                            vertical: DesignSystem.spacing.sm,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1),
                  ],
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing.xs),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.value == widget.value;
                        
                        return InkWell(
                          onTap: () {
                            widget.onChanged?.call(item.value);
                            _closeDropdown();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignSystem.spacing.md,
                              vertical: DesignSystem.spacing.sm,
                            ),
                            color: isSelected 
                                ? TColors.primary.withValues(alpha: 0.1)
                                : null,
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected ? TColors.primary : TColors.textSecondary,
                                  ),
                                  SizedBox(width: DesignSystem.spacing.sm),
                                ],
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: DesignSystem.typography.bodyMedium.copyWith(
                                      color: isSelected ? TColors.primary : TColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 20,
                                    color: TColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => DropdownItem(value: null, label: ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              padding: EdgeInsets.all(DesignSystem.spacing.md),
              decoration: BoxDecoration(
                borderRadius: DesignSystem.borders.md,
                border: Border.all(
                  color: hasError 
                      ? TColors.error
                      : _isOpen 
                          ? TColors.primary
                          : TColors.borderPrimary,
                  width: _isOpen ? 2.0 : 1.0,
                ),
                color: widget.enabled 
                    ? Colors.white
                    : TColors.grey.withValues(alpha: 0.1),
                boxShadow: _isOpen 
                    ? DesignSystem.shadows.elevation2
                    : DesignSystem.shadows.elevation1,
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(
                      widget.prefixIcon,
                      color: hasError 
                          ? TColors.error
                          : _isOpen 
                              ? TColors.primary 
                              : TColors.textSecondary,
                      size: 20,
                    ),
                    SizedBox(width: DesignSystem.spacing.sm),
                  ],
                  if (selectedItem.icon != null && widget.value != null) ...[
                    Icon(
                      selectedItem.icon,
                      size: 20,
                      color: TColors.textSecondary,
                    ),
                    SizedBox(width: DesignSystem.spacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      widget.value != null 
                          ? selectedItem.label
                          : widget.hint ?? widget.label ?? '',
                      style: DesignSystem.typography.bodyLarge.copyWith(
                        color: widget.value != null 
                            ? TColors.textPrimary
                            : TColors.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Icon(
                          Icons.expand_more,
                          color: hasError 
                              ? TColors.error
                              : _isOpen 
                                  ? TColors.primary 
                                  : TColors.textSecondary,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              top: DesignSystem.spacing.xs,
            ),
            child: Text(
              widget.errorText!,
              style: DesignSystem.typography.labelSmall.copyWith(
                color: TColors.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Modern checkbox with animations
class ModernCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final bool enabled;

  const ModernCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  State<ModernCheckbox> createState() => _ModernCheckboxState();
}

class _ModernCheckboxState extends State<ModernCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignSystem.animations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: DesignSystem.animations.easeOut),
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: TColors.primary,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: DesignSystem.animations.easeOut),
    );

    if (widget.value) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ModernCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled 
          ? () {
              HapticFeedback.lightImpact();
              widget.onChanged?.call(!widget.value);
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    border: Border.all(
                      color: widget.enabled 
                          ? (widget.value ? TColors.primary : TColors.borderPrimary)
                          : TColors.grey,
                      width: 2,
                    ),
                    borderRadius: DesignSystem.borders.sm,
                  ),
                  child: widget.value
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
          if (widget.label != null) ...[
            SizedBox(width: DesignSystem.spacing.sm),
            Flexible(
              child: Text(
                widget.label!,
                style: DesignSystem.typography.bodyMedium.copyWith(
                  color: widget.enabled ? TColors.textPrimary : TColors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dropdown item model
class DropdownItem<T> {
  final T? value;
  final String label;
  final IconData? icon;

  DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}
