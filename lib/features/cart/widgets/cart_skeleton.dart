import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rps_stationery/constants.dart';

class CartSkeleton extends StatelessWidget {
  const CartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).splashColor.withValues(alpha: 0.4),
        highlightColor: Theme.of(context).splashColor.withValues(alpha: 0.6),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: defaultPadding),
                // Title skeleton
                Container(
                  height: 24,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: defaultPadding),

                // Cart items skeleton
                ...List.generate(
                  3,
                  (index) => CartItemSkeleton(isLast: index == 2),
                ),

                const SizedBox(height: defaultPadding),

                // Order summary skeleton
                const OrderSummarySkeleton(),

                const SizedBox(height: defaultPadding * 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key, this.isLast = false});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Image skeleton
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(defaultBorderRadious),
              ),
            ),
            const SizedBox(width: defaultPadding / 4),

            // Product details skeleton
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category skeleton
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: defaultPadding / 2),

                    // Product name skeleton
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: defaultPadding / 4),

                    // Price and quantity skeleton
                    Row(
                      children: [
                        Container(
                          height: 16,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 16,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: defaultPadding / 4),

            // Delete button skeleton
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
        const SizedBox(height: defaultPadding / 2),
        if (!isLast)
          Container(height: 1, width: double.infinity, color: Colors.white),
      ],
    );
  }
}

class OrderSummarySkeleton extends StatelessWidget {
  const OrderSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
      ),
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary title skeleton
          Container(
            height: 20,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: defaultPadding),

          // Subtotal row skeleton
          Row(
            children: [
              Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 16,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding / 2),

          // Removed tax row skeleton (tax already included in product prices)

          // Divider skeleton
          Container(height: 1, width: double.infinity, color: Colors.white),
          const SizedBox(height: defaultPadding / 2),

          // Total row skeleton
          Row(
            children: [
              Container(
                height: 18,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 18,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
