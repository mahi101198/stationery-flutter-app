import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/constants/app_spacing.dart';

/// Consistent gap spacing throughout the app
class AppGaps {
  AppGaps._();
  
  // Horizontal gaps
  static SizedBox get horizontalXs => SizedBox(width: AppSpacing.xs);
  static SizedBox get horizontalSm => SizedBox(width: AppSpacing.sm);
  static SizedBox get horizontalMd => SizedBox(width: AppSpacing.md);
  static SizedBox get horizontalLg => SizedBox(width: AppSpacing.lg);
  static SizedBox get horizontalXl => SizedBox(width: AppSpacing.xl);
  static SizedBox get horizontalXxl => SizedBox(width: AppSpacing.xxl);
  
  // Vertical gaps
  static SizedBox get xs => SizedBox(height: AppSpacing.xs);
  static SizedBox get sm => SizedBox(height: AppSpacing.sm);
  static SizedBox get md => SizedBox(height: AppSpacing.md);
  static SizedBox get lg => SizedBox(height: AppSpacing.lg);
  static SizedBox get xl => SizedBox(height: AppSpacing.xl);
  static SizedBox get xxl => SizedBox(height: AppSpacing.xxl);
  
  // Semantic gaps
  static SizedBox get elementGap => SizedBox(height: AppSpacing.elementSpacing);
  static SizedBox get sectionGap => SizedBox(height: AppSpacing.sectionSpacing);
  
  // Custom gap sizes
  static SizedBox vertical(double height) => SizedBox(height: height);
  static SizedBox horizontal(double width) => SizedBox(width: width);
  static SizedBox square(double size) => SizedBox(width: size, height: size);
}
