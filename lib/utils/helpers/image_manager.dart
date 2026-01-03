import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:rps_stationery/utils/helpers/firebase_storage_helper.dart';
import 'package:rps_stationery/components/network_image_with_loader.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

/// Enhanced Image Manager for handling Firebase Storage and other image sources
/// Provides centralized image loading with error handling, caching, and fallbacks
class ImageManager {
  
  /// Cache for validated Firebase Storage URLs
  static final Map<String, String> _validatedUrls = {};
  
  /// Cache for failed URLs to avoid repeated checks
  static final Set<String> _failedUrls = {};
  
  /// Default placeholder image paths (can be local assets or Firebase Storage)
  static const String defaultProductImage = 'assets/images/placeholder_product.png';
  static const String defaultBannerImage = 'assets/images/placeholder_banner.png';
  static const String defaultAvatarImage = 'assets/images/placeholder_avatar.png';
  
  /// Validate and get a working Firebase Storage URL
  /// Returns the original URL if valid, a refreshed URL if expired, or null if invalid
  static Future<String?> validateFirebaseStorageUrl(String originalUrl) async {
    try {
      // Check if already validated and cached
      if (_validatedUrls.containsKey(originalUrl)) {
        return _validatedUrls[originalUrl]!;
      }
      
      // Check if previously failed
      if (_failedUrls.contains(originalUrl)) {
        return null;
      }
      
      // Test if it's a Firebase Storage URL
      if (!FirebaseStorageHelper.isFirebaseStorageUrl(originalUrl)) {
        // Regular URL, assume it works
        _validatedUrls[originalUrl] = originalUrl;
        return originalUrl;
      }
      
      // Try to refresh Firebase Storage URL
      final refreshedUrl = await FirebaseStorageHelper.refreshFirebaseStorageUrl(originalUrl);
      
      if (refreshedUrl != null && refreshedUrl.isNotEmpty) {
        _validatedUrls[originalUrl] = refreshedUrl;
        log('✅ Firebase Storage URL validated: ${originalUrl.substring(0, 50)}...');
        return refreshedUrl;
      } else {
        _failedUrls.add(originalUrl);
        log('❌ Firebase Storage URL validation failed: ${originalUrl.substring(0, 50)}...');
        return null;
      }
    } catch (e) {
      log('⚠️ Error validating Firebase Storage URL: $e');
      _failedUrls.add(originalUrl);
      return null;
    }
  }
  
  /// Build an optimized image widget with comprehensive error handling
  /// Supports Firebase Storage URLs, regular URLs, and local assets
  static Widget buildImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 0,
    String? fallbackAsset,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
  }) {
    return FutureBuilder<String?>(
      future: validateFirebaseStorageUrl(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(width, height, backgroundColor, showLoadingIndicator);
        }
        
        final validatedUrl = snapshot.data;
        
        if (validatedUrl != null && validatedUrl.isNotEmpty) {
          return _buildNetworkImage(
            validatedUrl,
            width: width,
            height: height,
            fit: fit,
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            fallbackAsset: fallbackAsset,
          );
        } else {
          return _buildFallbackWidget(
            width,
            height,
            borderRadius,
            backgroundColor,
            fallbackAsset,
          );
        }
      },
    );
  }
  
  /// Build network image with NetworkImageWithLoader
  static Widget _buildNetworkImage(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 0,
    Color? backgroundColor,
    String? fallbackAsset,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? TColors.softGrey,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: NetworkImageWithLoader(
        imageUrl,
        fit: fit,
        radius: borderRadius,
      ),
    );
  }
  
  /// Build loading widget
  static Widget _buildLoadingWidget(
    double? width,
    double? height,
    Color? backgroundColor,
    bool showLoadingIndicator,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? TColors.softGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: showLoadingIndicator
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
              ),
            )
          : const Icon(
              Icons.image,
              color: TColors.textSecondary,
              size: 24,
            ),
    );
  }
  
  /// Build fallback widget when image fails to load
  static Widget _buildFallbackWidget(
    double? width,
    double? height,
    double borderRadius,
    Color? backgroundColor,
    String? fallbackAsset,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? TColors.softGrey,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: fallbackAsset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.asset(
                fallbackAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
              ),
            )
          : _buildErrorIcon(),
    );
  }
  
  /// Build error icon
  static Widget _buildErrorIcon() {
    return const Icon(
      Icons.image_not_supported,
      color: TColors.textSecondary,
      size: 24,
    );
  }
  
  /// Preload and validate multiple images
  /// Useful for product galleries, banners, etc.
  static Future<Map<String, String?>> preloadImages(List<String> imageUrls) async {
    final Map<String, String?> results = {};
    
    for (final url in imageUrls) {
      try {
        results[url] = await validateFirebaseStorageUrl(url);
      } catch (e) {
        results[url] = null;
        log('Failed to preload image: $url - Error: $e');
      }
    }
    
    return results;
  }
  
  /// Clear cached URLs (useful for refreshing data)
  static void clearCache() {
    _validatedUrls.clear();
    _failedUrls.clear();
    log('🔄 Image URL cache cleared');
  }
  
  /// Clear only failed URLs cache (for retry scenarios)
  static void clearFailedCache() {
    _failedUrls.clear();
    log('🔄 Failed URLs cache cleared');
  }
  
  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'validated': _validatedUrls.length,
      'failed': _failedUrls.length,
    };
  }
  
  /// Test Firebase Storage connectivity and log results
  static Future<bool> testStorageConnectivity() async {
    try {
      final isConnected = await FirebaseStorageHelper.testStorageConnectivity();
      if (isConnected) {
        log('✅ Firebase Storage connectivity test: PASSED');
      } else {
        log('❌ Firebase Storage connectivity test: FAILED');
      }
      return isConnected;
    } catch (e) {
      log('⚠️ Firebase Storage connectivity test error: $e');
      return false;
    }
  }
  
  /// Audit all images in a list of image URLs and return report
  static Future<Map<String, dynamic>> auditImageUrls(List<String> imageUrls) async {
    final report = <String, dynamic>{
      'total': imageUrls.length,
      'valid': 0,
      'invalid': 0,
      'firebase_storage': 0,
      'regular_urls': 0,
      'invalid_urls': <String>[],
    };
    
    log('🔍 Starting image audit for ${imageUrls.length} URLs...');
    
    for (final url in imageUrls) {
      if (url.isEmpty) {
        report['invalid']++;
        continue;
      }
      
      if (FirebaseStorageHelper.isFirebaseStorageUrl(url)) {
        report['firebase_storage']++;
      } else {
        report['regular_urls']++;
      }
      
      final validatedUrl = await validateFirebaseStorageUrl(url);
      if (validatedUrl != null) {
        report['valid']++;
      } else {
        report['invalid']++;
        (report['invalid_urls'] as List<String>).add(url);
      }
    }
    
    log('📊 Image audit completed:');
    log('   Total: ${report['total']}');
    log('   Valid: ${report['valid']}');
    log('   Invalid: ${report['invalid']}');
    log('   Firebase Storage: ${report['firebase_storage']}');
    log('   Regular URLs: ${report['regular_urls']}');
    
    return report;
  }
}

/// Extension for easy image loading in widgets
extension ImageManagerExtension on Widget {
  /// Wrap widget with image preloading
  Widget withImagePreload(List<String> imageUrls) {
    return FutureBuilder<Map<String, String?>>(
      future: ImageManager.preloadImages(imageUrls),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return this;
      },
    );
  }
}
