import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'secondary_product_skeleton.dart';

class SecondaryProductsSkeleton extends StatelessWidget {
  const SecondaryProductsSkeleton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 114,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            left: defaultPadding,
            right: index == 2 ? defaultPadding : 0,
          ),
          child: const SecondaryProductSkeleton(),
        ),
      ),
    );
  }
}
