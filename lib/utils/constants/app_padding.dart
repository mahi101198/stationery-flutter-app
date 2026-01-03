import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/constants/app_spacing.dart';

/// Consistent padding values throughout the app
class AppPadding {
  AppPadding._();
  
  // Basic padding sizes
  static EdgeInsets get xs => EdgeInsets.all(AppSpacing.xs);
  static EdgeInsets get sm => EdgeInsets.all(AppSpacing.sm);
  static EdgeInsets get md => EdgeInsets.all(AppSpacing.md);
  static EdgeInsets get lg => EdgeInsets.all(AppSpacing.lg);
  static EdgeInsets get xl => EdgeInsets.all(AppSpacing.xl);
  static EdgeInsets get xxl => EdgeInsets.all(AppSpacing.xxl);
  
  // Symmetric padding
  static EdgeInsets symmetricXs({bool horizontal = true, bool vertical = true}) => EdgeInsets.symmetric(
    horizontal: horizontal ? AppSpacing.xs : 0,
    vertical: vertical ? AppSpacing.xs : 0,
  );
  
  static EdgeInsets symmetricSm({bool horizontal = true, bool vertical = true}) => EdgeInsets.symmetric(
    horizontal: horizontal ? AppSpacing.sm : 0,
    vertical: vertical ? AppSpacing.sm : 0,
  );
  
  static EdgeInsets symmetricMd({bool horizontal = true, bool vertical = true}) => EdgeInsets.symmetric(
    horizontal: horizontal ? AppSpacing.md : 0,
    vertical: vertical ? AppSpacing.md : 0,
  );
  
  static EdgeInsets symmetricLg({bool horizontal = true, bool vertical = true}) => EdgeInsets.symmetric(
    horizontal: horizontal ? AppSpacing.lg : 0,
    vertical: vertical ? AppSpacing.lg : 0,
  );
  
  // Directional padding
  static EdgeInsets get horizontalXs => EdgeInsets.symmetric(horizontal: AppSpacing.xs);
  static EdgeInsets get horizontalSm => EdgeInsets.symmetric(horizontal: AppSpacing.sm);
  static EdgeInsets get horizontalMd => EdgeInsets.symmetric(horizontal: AppSpacing.md);
  static EdgeInsets get horizontalLg => EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static EdgeInsets get horizontalXl => EdgeInsets.symmetric(horizontal: AppSpacing.xl);
  
  static EdgeInsets get verticalXs => EdgeInsets.symmetric(vertical: AppSpacing.xs);
  static EdgeInsets get verticalSm => EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static EdgeInsets get verticalMd => EdgeInsets.symmetric(vertical: AppSpacing.md);
  static EdgeInsets get verticalLg => EdgeInsets.symmetric(vertical: AppSpacing.lg);
  static EdgeInsets get verticalXl => EdgeInsets.symmetric(vertical: AppSpacing.xl);
  
  // Semantic padding
  static EdgeInsets get screen => EdgeInsets.all(AppSpacing.screenPadding);
  static EdgeInsets get card => EdgeInsets.all(AppSpacing.cardPadding);
  static EdgeInsets get element => EdgeInsets.all(AppSpacing.elementSpacing);
  static EdgeInsets get section => EdgeInsets.all(AppSpacing.sectionSpacing);
  
  // Button padding
  static EdgeInsets get buttonSmall => EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xs,
  );
  
  static EdgeInsets get buttonMedium => EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );
  
  static EdgeInsets get buttonLarge => EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );
  
  // Custom padding
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) => 
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
}
