import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';

class SpacingStyle {
  SpacingStyle._();

  static const EdgeInsetsGeometry paddingWithAppBar = EdgeInsets.only(
    top: AppSizes.appBarHeight,
    left: AppSizes.defaultSpace,
    right: AppSizes.defaultSpace,
    bottom: AppSizes.defaultSpace,
  );
}
