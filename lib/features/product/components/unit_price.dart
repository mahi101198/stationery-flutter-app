import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

import '../../../../constants.dart';

class UnitPrice extends StatelessWidget {
  const UnitPrice({super.key, required this.price, this.priceAfterDiscount});

  final double price;
  final double? priceAfterDiscount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Unit price", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: defaultPadding / 1),
        Row(
          children: [
            // Selling Price with gradient
            ShaderMask(
              shaderCallback: (bounds) =>
                  ComponentStyles.getPriceGradient(isDark).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                "₹ ${price.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // MRP (crossed out) - only show if there's a discount
            if (priceAfterDiscount != null)
              Text(
                "₹ ${priceAfterDiscount!.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
