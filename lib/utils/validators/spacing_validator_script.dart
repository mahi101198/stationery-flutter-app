import 'dart:io';

/// Script to validate consistent spacing across the Flutter app
/// Run this script to check for hardcoded spacing values that should use AppSpacing constants
void main() async {
  print('🔍 Starting spacing validation...\n');
  
  final libDir = Directory('lib');
  final issues = <String>[];
  
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      final violations = _checkSpacingViolations(entity.path, content);
      issues.addAll(violations);
    }
  }
  
  if (issues.isEmpty) {
    print('✅ No spacing violations found! All spacing appears to be consistent.\n');
  } else {
    print('⚠️  Found ${issues.length} spacing violations:\n');
    for (final issue in issues) {
      print(issue);
    }
    print('\n💡 Consider using AppSpacing constants for consistent spacing.');
  }
  
  print('\n📊 Spacing validation complete.');
}

List<String> _checkSpacingViolations(String filePath, String content) {
  final violations = <String>[];
  final lines = content.split('\n');
  
  final patterns = [
    // Check for hardcoded EdgeInsets
    RegExp(r'EdgeInsets\.all\((\d+(?:\.\d+)?)\)'),
    RegExp(r'EdgeInsets\.symmetric\(.*?(\d+(?:\.\d+)?).*?\)'),
    RegExp(r'EdgeInsets\.only\(.*?(\d+(?:\.\d+)?).*?\)'),
    
    // Check for hardcoded SizedBox
    RegExp(r'SizedBox\(height:\s*(\d+(?:\.\d+)?)\)'),
    RegExp(r'SizedBox\(width:\s*(\d+(?:\.\d+)?)\)'),
    
    // Check for hardcoded padding values
    RegExp(r'padding:\s*const\s+EdgeInsets\.all\((\d+(?:\.\d+)?)\)'),
    RegExp(r'margin:\s*const\s+EdgeInsets\.all\((\d+(?:\.\d+)?)\)'),
  ];
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    
    // Skip lines that already use AppSpacing or DesignSystem
    if (line.contains('AppSpacing.') || 
        line.contains('DesignSystem.') ||
        line.contains('AppGaps.') ||
        line.contains('AppPadding.')) {
      continue;
    }
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(line);
      for (final match in matches) {
        final value = double.tryParse(match.group(1) ?? '');
        if (value != null && _isCommonSpacingValue(value)) {
          violations.add(
            '📍 $filePath:${i + 1} - Hardcoded spacing: ${match.group(0)}'
          );
        }
      }
    }
  }
  
  return violations;
}

bool _isCommonSpacingValue(double value) {
  // Common spacing values that should use constants
  const commonValues = [4, 8, 12, 16, 20, 24, 28, 32, 40, 48, 56, 64, 72, 80];
  return commonValues.contains(value.toInt());
}

/// Additional validation functions

/// Check for consistent border radius usage
List<String> _checkBorderRadiusConsistency(String filePath, String content) {
  final violations = <String>[];
  final lines = content.split('\n');
  
  final borderRadiusPattern = RegExp(r'BorderRadius\.circular\((\d+(?:\.\d+)?)\)');
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    
    if (line.contains('AppBorderRadius.')) continue;
    
    final matches = borderRadiusPattern.allMatches(line);
    for (final match in matches) {
      final value = double.tryParse(match.group(1) ?? '');
      if (value != null && _isCommonBorderRadiusValue(value)) {
        violations.add(
          '📐 $filePath:${i + 1} - Hardcoded border radius: ${match.group(0)}'
        );
      }
    }
  }
  
  return violations;
}

bool _isCommonBorderRadiusValue(double value) {
  const commonValues = [4, 8, 12, 16, 20, 24, 25, 28, 32];
  return commonValues.contains(value.toInt());
}

/// Check for color consistency
List<String> _checkColorConsistency(String filePath, String content) {
  final violations = <String>[];
  final lines = content.split('\n');
  
  // Look for hardcoded color values
  final colorPatterns = [
    RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)'),
    RegExp(r'Colors\.(grey|gray)\[\d+\]'),
    RegExp(r'Colors\.(black|white)\d*'),
  ];
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    
    // Skip lines that use theme colors
    if (line.contains('Theme.of(context)') || 
        line.contains('colorScheme.') ||
        line.contains('AppColors.')) {
      continue;
    }
    
    for (final pattern in colorPatterns) {
      if (pattern.hasMatch(line)) {
        violations.add(
          '🎨 $filePath:${i + 1} - Hardcoded color: ${pattern.stringMatch(line)}'
        );
      }
    }
  }
  
  return violations;
}

/// Generate spacing usage report
void generateSpacingReport() {
  print('📈 Spacing Usage Report\n');
  print('Recommended spacing scale (8dp grid):');
  print('• xs (4dp) - Very tight spacing');
  print('• sm (8dp) - Tight spacing');
  print('• md (16dp) - Default spacing');
  print('• lg (24dp) - Loose spacing');
  print('• xl (32dp) - Very loose spacing');
  print('• xxl (48dp) - Section spacing');
  print('\nUsage guidelines:');
  print('• Use AppSpacing constants instead of hardcoded values');
  print('• Use AppGaps for SizedBox spacing');
  print('• Use AppPadding for EdgeInsets');
  print('• Use AppBorderRadius for consistent border radius\n');
}
