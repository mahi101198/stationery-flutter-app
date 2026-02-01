import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../skelton.dart';

class ProductCardSkelton extends StatelessWidget {
  final double? width;
  final double height;

  const ProductCardSkelton({
    super.key,
    this.width,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? 140,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Skeleton(),
            ),
            Spacer(flex: 2),
            Skeleton(height: 12, width: 64),
            Spacer(flex: 2),
            Skeleton(),
            Spacer(),
            Skeleton(),
            Spacer(flex: 2),
            Skeleton(height: 12, width: 80),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
