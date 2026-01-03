import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../skelton.dart';

class OptimizedProductsSkelton extends StatelessWidget {
  const OptimizedProductsSkelton({
    super.key,
    this.itemCount = 3,
    this.isHorizontal = true,
    this.itemHeight = 188,
    this.itemWidth = 140,
  });

  final int itemCount;
  final bool isHorizontal;
  final double itemHeight;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return SizedBox(
        height: itemHeight,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              left: defaultPadding,
              right: index == itemCount - 1 ? defaultPadding : 0,
            ),
            child: OptimizedProductCardSkelton(
              height: itemHeight,
              width: itemWidth,
            ),
          ),
        ),
      );
    } else {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: itemWidth / itemHeight,
          crossAxisSpacing: defaultPadding,
          mainAxisSpacing: defaultPadding,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => OptimizedProductCardSkelton(
          height: itemHeight,
          width: itemWidth,
        ),
      );
    }
  }
}

class OptimizedProductCardSkelton extends StatelessWidget {
  const OptimizedProductCardSkelton({
    super.key,
    this.height = 188,
    this.width = 140,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            AspectRatio(
              aspectRatio: 1.15,
              child: Skeleton(
                radius: defaultPadding,
              ),
            ),
            const Spacer(flex: 2),
            // Category skeleton
            Skeleton(height: 12, width: 64),
            const Spacer(flex: 2),
            // Product name skeleton (2 lines)
            Skeleton(),
            const SizedBox(height: 4),
            Skeleton(),
            const Spacer(),
            // Price skeleton
            Skeleton(height: 12, width: 80),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
