import 'package:flutter/material.dart';

/// A safe network image widget that handles errors gracefully without causing widget build issues
class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Widget? placeholderWidget;

  const SafeNetworkImage(
    this.imageUrl, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderWidget,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  late ImageProvider _imageProvider;
  ImageConfiguration? _config;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void didUpdateWidget(SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initializeImage();
    }
  }

  void _initializeImage() {
    _imageProvider = NetworkImage(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Image(
          image: _imageProvider,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null;

            return Container(
              color: const Color(0xFFF3F4F6),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: const Color(0xFF00BCD4),
                    value: progress,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ SafeNetworkImage error for: ${widget.imageUrl}');
            debugPrint('   Error: $error');

            // Wrap in Directionality to ensure text direction context
            return Directionality(
              textDirection: TextDirection.ltr,
              child: widget.placeholderWidget ??
                  Container(
                    color: const Color(0xFFF3F4F6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Image unavailable',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }
}
