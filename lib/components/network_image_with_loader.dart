import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

import '../constants.dart';
import '../utils/helpers/firebase_storage_helper.dart';
import 'skleton/skelton.dart';

class NetworkImageWithLoader extends StatefulWidget {
  final BoxFit fit;

  const NetworkImageWithLoader(
    this.src, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = defaultPadding,
  });

  final String src;
  final double radius;

  @override
  State<NetworkImageWithLoader> createState() => _NetworkImageWithLoaderState();
}

class _NetworkImageWithLoaderState extends State<NetworkImageWithLoader> {
  String? _currentUrl;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.src;
  }

  @override
  void didUpdateWidget(NetworkImageWithLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _currentUrl = widget.src;
      _isRetrying = false;
    }
  }

  Future<void> _handleImageError(Object error) async {
    log('Image loading error for URL: $_currentUrl. Error: $error');
    
    // If it's a Firebase Storage URL and we haven't retried yet, try to get fresh URL
    if (!_isRetrying && 
        _currentUrl != null && 
        FirebaseStorageHelper.isFirebaseStorageUrl(_currentUrl!)) {
      
      log('Attempting to refresh Firebase Storage URL...');
      
      if (mounted) {
        setState(() {
          _isRetrying = true;
        });
      }
      
      try {
        final freshUrl = await FirebaseStorageHelper.refreshFirebaseStorageUrl(_currentUrl!);
        if (freshUrl != null && freshUrl != _currentUrl && mounted) {
          log('Refreshed Firebase Storage URL: $freshUrl');
          setState(() {
            _currentUrl = freshUrl;
          });
        } else {
          log('Could not refresh Firebase Storage URL');
        }
      } catch (e) {
        log('Error refreshing Firebase Storage URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
      child: Container(
        color: Colors.white,
        child: CachedNetworkImage(
          fit: widget.fit,
          imageUrl: _currentUrl ?? widget.src,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: widget.fit),
            ),
          ),
          placeholder: (context, url) => const Skeleton(),
          errorWidget: (context, url, error) {
            // Handle the error asynchronously to avoid setState during build
            if (!_isRetrying) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _handleImageError(error);
                }
              });
            }
            
            return Container(
              color: const Color(0xFFF5F5F5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isRetrying ? Icons.refresh : Icons.image_not_supported,
                    color: const Color(0xFFBDBDBD),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRetrying ? 'Retrying...' : 'Image unavailable',
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          // Optimize caching for performance
          memCacheHeight: 400, // Limit memory cache size
          memCacheWidth: 400,
          maxHeightDiskCache: 800, // Limit disk cache size  
          maxWidthDiskCache: 800,
          fadeInDuration: const Duration(milliseconds: 200), // Faster fade in
          fadeOutDuration: const Duration(milliseconds: 100), // Faster fade out
        ),
      ),
    );
  }
}
