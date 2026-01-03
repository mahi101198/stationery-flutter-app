import 'package:flutter/material.dart';

/// Helper class for responsive layout management
class ResponsiveHelper {
  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return baseFontSize * 0.85; // Small screens
    } else if (screenWidth < 400) {
      return baseFontSize * 0.9; // Medium-small screens
    } else if (screenWidth > 600) {
      return baseFontSize * 1.1; // Large screens
    }
    
    return baseFontSize; // Default size
  }

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return EdgeInsets.all(basePadding.left * 0.8);
    } else if (screenWidth > 600) {
      return EdgeInsets.all(basePadding.left * 1.2);
    }
    
    return basePadding;
  }

  /// Get responsive width for cards
  static double getCardWidth(BuildContext context, {double baseWidth = 160}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Account for padding
    
    if (screenWidth < 360) {
      return (availableWidth - 16) / 2; // 2 cards per row
    } else if (screenWidth < 600) {
      return baseWidth;
    } else {
      return baseWidth * 1.1; // Larger cards on tablets
    }
  }

  /// Check if text will overflow
  static bool willTextOverflow(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }

  /// Get safe text with ellipsis if needed
  static String getSafeText(String text, TextStyle style, double maxWidth) {
    if (willTextOverflow(text, style, maxWidth)) {
      // Find a good breaking point
      final words = text.split(' ');
      String result = '';
      
      for (final word in words) {
        final testText = result.isEmpty ? word : '$result $word';
        if (willTextOverflow(testText, style, maxWidth)) {
          break;
        }
        result = testText;
      }
      
      return result.isEmpty ? text : '$result...';
    }
    return text;
  }

  /// Get responsive grid count
  static int getGridCount(BuildContext context, {int baseCount = 2}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return 2; // Always 2 on very small screens
    } else if (screenWidth < 600) {
      return baseCount;
    } else {
      return (baseCount * 1.5).round(); // More items on larger screens
    }
  }

  /// Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return baseSpacing * 0.8;
    } else if (screenWidth > 600) {
      return baseSpacing * 1.2;
    }
    
    return baseSpacing;
  }
}
