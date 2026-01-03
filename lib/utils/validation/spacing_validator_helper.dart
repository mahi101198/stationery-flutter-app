import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/constants/app_spacing.dart';

/// Helper utility to validate and fix spacing issues across the app
class SpacingValidatorHelper {
  static final List<SpacingIssue> _spacingIssues = [];
  static bool _validationEnabled = kDebugMode;
  
  /// Enable or disable spacing validation
  static void setValidationEnabled(bool enabled) {
    _validationEnabled = enabled && kDebugMode;
  }
  
  /// Check if validation is enabled
  static bool get isValidationEnabled => _validationEnabled;
  
  /// Get all spacing issues found
  static List<SpacingIssue> get spacingIssues => List.unmodifiable(_spacingIssues);
  
  /// Clear all spacing issues
  static void clearIssues() {
    _spacingIssues.clear();
  }
  
  /// Validate EdgeInsets and report issues
  static EdgeInsets validatePadding(
    EdgeInsets padding, {
    required String componentName,
    String? location,
    bool autoFix = true,
  }) {
    if (!_validationEnabled) return padding;
    
    final issues = <String>[];
    EdgeInsets fixedPadding = padding;
    
    // Check each side for 8dp grid compliance
    if (!SpacingValidator.isValidSpacing(padding.top)) {
      issues.add('top: ${padding.top}dp not on 8dp grid');
      if (autoFix) {
        fixedPadding = fixedPadding.copyWith(
          top: SpacingValidator.suggestValidSpacing(padding.top),
        );
      }
    }
    
    if (!SpacingValidator.isValidSpacing(padding.right)) {
      issues.add('right: ${padding.right}dp not on 8dp grid');
      if (autoFix) {
        fixedPadding = fixedPadding.copyWith(
          right: SpacingValidator.suggestValidSpacing(padding.right),
        );
      }
    }
    
    if (!SpacingValidator.isValidSpacing(padding.bottom)) {
      issues.add('bottom: ${padding.bottom}dp not on 8dp grid');
      if (autoFix) {
        fixedPadding = fixedPadding.copyWith(
          bottom: SpacingValidator.suggestValidSpacing(padding.bottom),
        );
      }
    }
    
    if (!SpacingValidator.isValidSpacing(padding.left)) {
      issues.add('left: ${padding.left}dp not on 8dp grid');
      if (autoFix) {
        fixedPadding = fixedPadding.copyWith(
          left: SpacingValidator.suggestValidSpacing(padding.left),
        );
      }
    }
    
    // Report issues if found
    if (issues.isNotEmpty) {
      _spacingIssues.add(SpacingIssue(
        componentName: componentName,
        location: location,
        issueType: SpacingIssueType.padding,
        originalPadding: padding,
        suggestedPadding: fixedPadding,
        issues: issues,
      ));
      
      debugPrint('🔧 SPACING ISSUE in $componentName ${location ?? ''}:');
      for (final issue in issues) {
        debugPrint('   - $issue');
      }
      if (autoFix) {
        debugPrint('   💡 Auto-fixed to: $fixedPadding');
      }
    }
    
    return autoFix ? fixedPadding : padding;
  }
  
  /// Validate individual spacing value
  static double validateSpacing(
    double value, {
    required String name,
    required String componentName,
    String? location,
    bool autoFix = true,
  }) {
    if (!_validationEnabled) return value;
    
    if (!SpacingValidator.isValidSpacing(value)) {
      final suggestedValue = SpacingValidator.suggestValidSpacing(value);
      
      _spacingIssues.add(SpacingIssue(
        componentName: componentName,
        location: location,
        issueType: SpacingIssueType.value,
        originalValue: value,
        suggestedValue: suggestedValue,
        issues: ['$name: ${value}dp not on 8dp grid'],
      ));
      
      debugPrint('🔧 SPACING ISSUE in $componentName ${location ?? ''}: $name: ${value}dp not on 8dp grid');
      if (autoFix) {
        debugPrint('   💡 Auto-fixed to: ${suggestedValue}dp');
        return suggestedValue;
      }
    }
    
    return value;
  }
  
  /// Get spacing suggestions for common use cases
  static Map<String, double> getSpacingSuggestions() {
    return {
      'Tiny spacing (4dp)': AppSpacing.xs,
      'Small spacing (8dp)': AppSpacing.sm,
      'Medium spacing (16dp)': AppSpacing.md,
      'Large spacing (24dp)': AppSpacing.lg,
      'Extra large spacing (32dp)': AppSpacing.xl,
      'Huge spacing (48dp)': AppSpacing.xxl,
      'Card padding': AppSpacing.cardPadding,
      'Screen padding': AppSpacing.screenPadding,
      'Section spacing': AppSpacing.sectionSpacing,
      'Element spacing': AppSpacing.elementSpacing,
    };
  }
  
  /// Generate a report of all spacing issues found
  static String generateReport() {
    if (_spacingIssues.isEmpty) {
      return '✅ No spacing issues found! All spacing follows the 8dp grid system.';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('📊 SPACING VALIDATION REPORT');
    buffer.writeln('Found ${_spacingIssues.length} spacing issues:\n');
    
    // Group by component
    final groupedIssues = <String, List<SpacingIssue>>{};
    for (final issue in _spacingIssues) {
      groupedIssues.putIfAbsent(issue.componentName, () => []).add(issue);
    }
    
    for (final entry in groupedIssues.entries) {
      buffer.writeln('🔸 ${entry.key}:');
      for (final issue in entry.value) {
        buffer.writeln('   ${issue.location ?? ''}');
        for (final issueDesc in issue.issues) {
          buffer.writeln('   - $issueDesc');
        }
        if (issue.suggestedPadding != null) {
          buffer.writeln('   💡 Suggested: ${issue.suggestedPadding}');
        }
        if (issue.suggestedValue != null) {
          buffer.writeln('   💡 Suggested: ${issue.suggestedValue}dp');
        }
        buffer.writeln();
      }
    }
    
    // Add recommendations
    buffer.writeln('\n📋 RECOMMENDATIONS:');
    buffer.writeln('• Use AppSpacing constants instead of hardcoded values');
    buffer.writeln('• Follow the 8dp grid system for consistency');
    buffer.writeln('• Use semantic spacing names (cardPadding, screenPadding, etc.)');
    buffer.writeln('• Consider responsive spacing for different screen sizes');
    
    return buffer.toString();
  }
  
  /// Create a debug overlay showing spacing issues
  static Widget createSpacingOverlay(BuildContext context) {
    if (!_validationEnabled || _spacingIssues.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      right: 10,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rule, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_spacingIssues.length} Spacing Issues',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: clearIssues,
                  child: const Icon(Icons.clear, color: Colors.white, size: 14),
                ),
              ],
            ),
            if (_spacingIssues.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...(_spacingIssues.take(3).map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${issue.componentName}${issue.location != null ? ' (${issue.location})' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ))),
              if (_spacingIssues.length > 3)
                Text(
                  '+${_spacingIssues.length - 3} more...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Represents a spacing validation issue
class SpacingIssue {
  final String componentName;
  final String? location;
  final SpacingIssueType issueType;
  final EdgeInsets? originalPadding;
  final EdgeInsets? suggestedPadding;
  final double? originalValue;
  final double? suggestedValue;
  final List<String> issues;
  final DateTime timestamp;
  
  SpacingIssue({
    required this.componentName,
    this.location,
    required this.issueType,
    this.originalPadding,
    this.suggestedPadding,
    this.originalValue,
    this.suggestedValue,
    required this.issues,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'SpacingIssue($componentName: ${issues.join(', ')})';
  }
}

/// Types of spacing issues
enum SpacingIssueType {
  padding,
  margin,
  value,
}

/// Extension to easily validate spacing in widgets
extension SpacingValidation on EdgeInsets {
  /// Validate this EdgeInsets and return a corrected version if needed
  EdgeInsets validate({
    required String componentName,
    String? location,
    bool autoFix = true,
  }) {
    return SpacingValidatorHelper.validatePadding(
      this,
      componentName: componentName,
      location: location,
      autoFix: autoFix,
    );
  }
}

/// Extension for validating spacing values
extension SpacingValueValidation on double {
  /// Validate this spacing value and return a corrected version if needed
  double validateSpacing({
    required String name,
    required String componentName,
    String? location,
    bool autoFix = true,
  }) {
    return SpacingValidatorHelper.validateSpacing(
      this,
      name: name,
      componentName: componentName,
      location: location,
      autoFix: autoFix,
    );
  }
  
  /// Check if this value follows the 8dp grid system
  bool get isValidSpacing => SpacingValidator.isValidSpacing(this);
  
  /// Get the nearest valid spacing value
  double get nearestValidSpacing => SpacingValidator.suggestValidSpacing(this);
}

/// Widget wrapper that validates spacing
class SpacingValidatedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String componentName;
  final String? location;
  final bool autoFixSpacing;
  
  const SpacingValidatedContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    required this.componentName,
    this.location,
    this.autoFixSpacing = true,
  });
  
  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry? validatedPadding = padding;
    EdgeInsetsGeometry? validatedMargin = margin;
    
    // Validate padding if provided
    if (padding is EdgeInsets) {
      validatedPadding = SpacingValidatorHelper.validatePadding(
        padding as EdgeInsets,
        componentName: componentName,
        location: location,
        autoFix: autoFixSpacing,
      );
    }
    
    // Validate margin if provided
    if (margin is EdgeInsets) {
      validatedMargin = SpacingValidatorHelper.validatePadding(
        margin as EdgeInsets,
        componentName: '$componentName (margin)',
        location: location,
        autoFix: autoFixSpacing,
      );
    }
    
    return Container(
      padding: validatedPadding,
      margin: validatedMargin,
      child: child,
    );
  }
}

/// Debug overlay that shows all spacing issues
class SpacingDebugOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  
  const SpacingDebugOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!SpacingValidatorHelper.isValidationEnabled || !showOverlay) {
      return child;
    }
    
    return Stack(
      alignment: Alignment.topCenter, // Use non-directional alignment
      children: [
        child,
        SpacingValidatorHelper.createSpacingOverlay(context),
      ],
    );
  }
}
