import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Development utility for detecting and highlighting overflow issues
class OverflowDetector {
  static bool _isEnabled = kDebugMode;
  static final List<OverflowInfo> _overflowReports = [];
  
  /// Enable or disable overflow detection
  static void setEnabled(bool enabled) {
    _isEnabled = enabled && kDebugMode;
  }
  
  /// Check if overflow detection is enabled
  static bool get isEnabled => _isEnabled;
  
  /// Get all overflow reports
  static List<OverflowInfo> get overflowReports => List.unmodifiable(_overflowReports);
  
  /// Clear overflow reports
  static void clearReports() {
    _overflowReports.clear();
  }
  
  /// Report an overflow issue
  static void reportOverflow(OverflowInfo info) {
    if (!_isEnabled) return;
    
    _overflowReports.add(info);
    
    // Log to console in debug mode
    debugPrint('🔥 OVERFLOW DETECTED: ${info.widgetType} at ${info.location}');
    debugPrint('   Overflow: ${info.overflowPixels}px on ${info.direction}');
    debugPrint('   Size: ${info.size}');
    debugPrint('   Constraints: ${info.constraints}');
    if (info.suggestion.isNotEmpty) {
      debugPrint('   💡 Suggestion: ${info.suggestion}');
    }
  }
  
  /// Wrap a widget with overflow detection
  static Widget wrapWithDetection({
    required Widget child,
    required String identifier,
    String? location,
  }) {
    if (!_isEnabled) return child;
    
    return _OverflowDetectorWrapper(
      identifier: identifier,
      location: location,
      child: child,
    );
  }
  
  /// Create a development overlay showing overflow issues
  static Widget createOverflowOverlay(BuildContext context) {
    if (!_isEnabled || _overflowReports.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_overflowReports.length} Overflows',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: clearReports,
                  child: const Icon(Icons.clear, color: Colors.white, size: 14),
                ),
              ],
            ),
            if (_overflowReports.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...(_overflowReports.take(3).map((report) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${report.widgetType}: ${report.overflowPixels}px',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ))),
              if (_overflowReports.length > 3)
                Text(
                  '+${_overflowReports.length - 3} more...',
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

/// Information about an overflow issue
class OverflowInfo {
  final String widgetType;
  final String? location;
  final double overflowPixels;
  final String direction;
  final Size size;
  final BoxConstraints constraints;
  final String suggestion;
  final DateTime timestamp;
  
  OverflowInfo({
    required this.widgetType,
    this.location,
    required this.overflowPixels,
    required this.direction,
    required this.size,
    required this.constraints,
    this.suggestion = '',
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'OverflowInfo(type: $widgetType, pixels: ${overflowPixels}px, direction: $direction)';
  }
}

/// Internal wrapper widget for detecting overflow
class _OverflowDetectorWrapper extends SingleChildRenderObjectWidget {
  final String identifier;
  final String? location;
  
  const _OverflowDetectorWrapper({
    required this.identifier,
    this.location,
    required Widget child,
  }) : super(child: child);
  
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverflowDetector(
      identifier: identifier,
      location: location,
    );
  }
  
  @override
  void updateRenderObject(BuildContext context, _RenderOverflowDetector renderObject) {
    renderObject
      ..identifier = identifier
      ..location = location;
  }
}

/// Custom render object that detects overflow
class _RenderOverflowDetector extends RenderProxyBox {
  String identifier;
  String? location;
  
  _RenderOverflowDetector({
    required this.identifier,
    this.location,
  });
  
  @override
  void performLayout() {
    super.performLayout();
    
    if (child case final RenderBox child) {
      final childSize = child.size;
      final availableSize = constraints.biggest;
      
      // Check for overflow
      double overflowWidth = 0;
      double overflowHeight = 0;
      
      if (childSize.width > availableSize.width) {
        overflowWidth = childSize.width - availableSize.width;
      }
      
      if (childSize.height > availableSize.height) {
        overflowHeight = childSize.height - availableSize.height;
      }
      
      // Report overflow if detected
      if (overflowWidth > 0) {
        OverflowDetector.reportOverflow(OverflowInfo(
          widgetType: identifier,
          location: location,
          overflowPixels: overflowWidth,
          direction: 'horizontal',
          size: childSize,
          constraints: constraints,
          suggestion: _getSuggestionForOverflow('horizontal', overflowWidth),
        ));
      }
      
      if (overflowHeight > 0) {
        OverflowDetector.reportOverflow(OverflowInfo(
          widgetType: identifier,
          location: location,
          overflowPixels: overflowHeight,
          direction: 'vertical',
          size: childSize,
          constraints: constraints,
          suggestion: _getSuggestionForOverflow('vertical', overflowHeight),
        ));
      }
    }
  }
  
  String _getSuggestionForOverflow(String direction, double pixels) {
    if (direction == 'horizontal') {
      if (pixels < 10) {
        return 'Try reducing padding or using AppSpacing constants';
      } else if (pixels < 50) {
        return 'Consider using Flexible or Expanded widgets';
      } else {
        return 'Use ListView or SingleChildScrollView for scrollable content';
      }
    } else {
      if (pixels < 20) {
        return 'Reduce vertical spacing or font sizes';
      } else {
        return 'Use scrollable widgets like ListView or Column with scroll';
      }
    }
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    
    // Draw overflow indicators in debug mode
    if (OverflowDetector.isEnabled && child != null) {
      final childSize = child!.size;
      final availableSize = constraints.biggest;
      
      if (childSize.width > availableSize.width || childSize.height > availableSize.height) {
        final paint = Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        
        // Highlight overflow areas
        final overflowRect = Rect.fromLTWH(
          offset.dx + availableSize.width,
          offset.dy,
          (childSize.width - availableSize.width).clamp(0.0, double.infinity),
          childSize.height,
        );
        
        if (overflowRect.width > 0) {
          context.canvas.drawRect(overflowRect, paint);
        }
      }
    }
  }
}

/// Extension to easily wrap widgets with overflow detection
extension OverflowDetection on Widget {
  /// Wrap this widget with overflow detection
  Widget detectOverflow({
    required String identifier,
    String? location,
  }) {
    return OverflowDetector.wrapWithDetection(
      child: this,
      identifier: identifier,
      location: location,
    );
  }
}

/// Debug overlay widget that shows overflow issues
class OverflowDebugOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  
  const OverflowDebugOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!OverflowDetector.isEnabled || !showOverlay) {
      return child;
    }
    
    return Stack(
      children: [
        child,
        OverflowDetector.createOverflowOverlay(context),
      ],
    );
  }
}

/// Mixin for widgets to easily report overflow issues
mixin OverflowReporting<T extends StatefulWidget> on State<T> {
  void reportOverflow({
    required String widgetType,
    required double pixels,
    required String direction,
    required Size size,
    required BoxConstraints constraints,
    String? suggestion,
  }) {
    OverflowDetector.reportOverflow(OverflowInfo(
      widgetType: widgetType,
      location: widget.runtimeType.toString(),
      overflowPixels: pixels,
      direction: direction,
      size: size,
      constraints: constraints,
      suggestion: suggestion ?? '',
    ));
  }
}
