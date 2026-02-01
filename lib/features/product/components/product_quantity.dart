import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:iconsax/iconsax.dart';


class ProductQuantity extends StatefulWidget {
  const ProductQuantity({
    super.key,
    required this.quantity,
    required this.onQuantityChange,
    this.maxQuantity = 999,
    this.maxQuantityPerUser,
    this.showLimitMessage = true,
  });

  final int quantity;
  final void Function(int) onQuantityChange;
  final int maxQuantity;
  final int? maxQuantityPerUser;
  final bool showLimitMessage;

  @override
  State<ProductQuantity> createState() => _ProductQuantityState();
}

class _ProductQuantityState extends State<ProductQuantity> 
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      // When focus is lost (like back button press), validate and submit
      _validateAndUpdateQuantity(_controller.text);
    }
  }

  @override
  void didUpdateWidget(covariant ProductQuantity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _validateAndUpdateQuantity(String value) {
    final newQuantity = int.tryParse(value);
    if (newQuantity == null) {
      _controller.text = widget.quantity.toString();
      return;
    }

    if (newQuantity < 1) {
      TLoaders.customToast(message: "Quantity cannot be less than 1");
      _controller.text = widget.quantity.toString();
      return;
    }

    final effectiveMaxQuantity = _getEffectiveMaxQuantity();
    if (newQuantity > effectiveMaxQuantity) {
      final limitType = _getLimitingFactor();
      TLoaders.customToast(
        message: limitType == 'user' 
          ? "Maximum ${widget.maxQuantityPerUser} items allowed per user"
          : "Only $effectiveMaxQuantity items available in stock"
      );
      _controller.text = widget.quantity.toString();
      return;
    }

    if (newQuantity != widget.quantity) {
      widget.onQuantityChange(newQuantity);
    }
  }

  int _getEffectiveMaxQuantity() {
    if (widget.maxQuantityPerUser != null && widget.maxQuantityPerUser! > 0) {
      return widget.maxQuantity < widget.maxQuantityPerUser! 
        ? widget.maxQuantity 
        : widget.maxQuantityPerUser!;
    }
    return widget.maxQuantity;
  }

  String _getLimitingFactor() {
    if (widget.maxQuantityPerUser != null && widget.maxQuantityPerUser! > 0) {
      return widget.maxQuantity < widget.maxQuantityPerUser! ? 'stock' : 'user';
    }
    return 'stock';
  }

  void _animateButton() {
    _scaleController.forward().then((_) => _scaleController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMaxQuantity = _getEffectiveMaxQuantity();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.box,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              "Quantity",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (widget.showLimitMessage && widget.maxQuantityPerUser != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  "Max ${widget.maxQuantityPerUser} per user",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2),
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
              // Minus button
              SizedBox(
                height: 48,
                width: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.quantity > 1
                        ? () {
                            _animateButton();
                            widget.onQuantityChange(widget.quantity - 1);
                          }
                        : null,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Icon(
                        Iconsax.minus,
                        color: widget.quantity > 1
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Quantity display/input
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onTap: () {
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                  },
                  onEditingComplete: () {
                    _validateAndUpdateQuantity(_controller.text);
                    _focusNode.unfocus();
                  },
                  onSubmitted: _validateAndUpdateQuantity,
                ),
              ),
              
              // Plus button
              SizedBox(
                height: 48,
                width: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.quantity < effectiveMaxQuantity
                        ? () {
                            _animateButton();
                            widget.onQuantityChange(widget.quantity + 1);
                          }
                        : () {
                            // Show gentle warning when at limit
                            TLoaders.customToast(
                              message: "Maximum $effectiveMaxQuantity units per order",
                            );
                          },
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Icon(
                        Iconsax.add,
                        color: widget.quantity < effectiveMaxQuantity
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
