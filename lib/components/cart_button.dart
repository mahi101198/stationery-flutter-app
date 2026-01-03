import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/helpers/helper_functions.dart';

import '../constants.dart';

class CartButton extends StatelessWidget {
  const CartButton({
    super.key,
    required this.price,
    required this.quantity,
    required this.goToCart,
    required this.addToCart,
    this.cartQuantity,
    this.isCartUpdating = false,
  });

  final double price;
  final int quantity;
  final int? cartQuantity;
  final VoidCallback addToCart;
  final VoidCallback goToCart;
  final bool isCartUpdating;

  @override
  Widget build(BuildContext context) {
    final isUpdating = cartQuantity != 0 && cartQuantity != quantity;
    final message =
        cartQuantity == 0
            ? "Add to cart"
            : isUpdating
            ? "Update cart"
            : "Go to cart";
    final press = cartQuantity == 0 || isUpdating ? addToCart : goToCart;
    final totalPrice = price * quantity;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: defaultBorderRadious / 2,
        ),
        child: SizedBox(
          height: 64,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            clipBehavior: Clip.hardEdge,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(defaultBorderRadious),
              ),
            ),
            child: InkWell(
              onTap: press,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹ ${HelperFunctions.formatCurrency(totalPrice)}",
                            style: Theme.of(context).textTheme.titleSmall!
                                .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          Text(
                            "Total price",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      alignment: Alignment.center,
                      height: double.infinity,
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child:
                            isCartUpdating
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      message,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(color: Theme.of(context).colorScheme.onPrimary),
                                    ),
                                    if (message == "Go to cart") ...[
                                      const SizedBox(width: 8),
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ),
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(value * 4 - 2, 0),
                                            child: Opacity(
                                              opacity: 0.7 + (value * 0.3),
                                              child: Icon(
                                                Icons.arrow_forward,
                                                color: Theme.of(context).colorScheme.onPrimary,
                                                size: 18,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
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
  }
}
