import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/services/banner_analytics_service.dart';

/// Service for handling URL navigation in the app
/// Supports both internal app navigation and external browser navigation
class UrlNavigationService {
  /// Navigate to a URL - handles both internal and external links
  /// Optionally tracks analytics for banner clicks
  static Future<void> navigateToUrl(
    String? url, {
    String? bannerId,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    if (url == null || url.isEmpty) {
      print('⚠️ UrlNavigationService: No URL provided for navigation');
      return;
    }

    try {
      print('🔗 UrlNavigationService: Navigating to URL: $url');
      
      // Track analytics if bannerId is provided
      if (bannerId != null && bannerId.isNotEmpty) {
        print('📊 UrlNavigationService: Tracking analytics for banner: $bannerId');
        await BannerAnalyticsService.trackBannerClick(
          bannerId: bannerId,
          clickUrl: url,
          source: source,
          metadata: metadata,
        );
      }
      
      // Check if it's an internal app route
      if (isInternalRoute(url)) {
        await _navigateToInternalRoute(url);
      } else {
        await _navigateToExternalUrl(url);
      }
    } catch (e) {
      print('❌ UrlNavigationService: Error navigating to URL: $e');
      TLoaders.errorSnackBar(title: 'Navigation Error', message: 'Could not open the link');
    }
  }

  /// Check if the URL is an internal app route
  static bool isInternalRoute(String url) {
    // Remove protocol and check if it's an internal route
    final cleanUrl = url.replaceAll(RegExp(r'^https?://'), '').toLowerCase();
    
    // Check for common internal route patterns
    final internalPatterns = [
      'rpsstationery.com', // Your app domain
      'localhost',
      '127.0.0.1',
      '/products/', // Product routes
      '/category/', // Category routes
      '/profile', // Profile routes
      '/orders', // Order routes
      '/cart', // Cart routes
    ];

    return internalPatterns.any((pattern) => cleanUrl.contains(pattern)) ||
           url.startsWith('/') || // Relative paths
           !url.contains('.'); // URLs without dots are likely internal
  }

  /// Navigate to internal app route
  static Future<void> _navigateToInternalRoute(String url) async {
    print('🏠 UrlNavigationService: Navigating to internal route: $url');
    
    try {
      // Handle different internal route patterns
      if (url.contains('/products/')) {
        // Extract product ID from URL
        final productId = _extractProductId(url);
        if (productId != null) {
          Get.toNamed('/product-details', arguments: {'productId': productId});
          return;
        }
      }
      
      if (url.contains('/category/')) {
        // Extract category ID from URL
        final categoryId = _extractCategoryId(url);
        if (categoryId != null) {
          Get.toNamed('/category-products', arguments: {'categoryId': categoryId});
          return;
        }
      }
      
      if (url.contains('/profile')) {
        Get.toNamed('/profile');
        return;
      }
      
      if (url.contains('/orders')) {
        Get.toNamed('/orders');
        return;
      }
      
      if (url.contains('/cart')) {
        Get.toNamed('/cart');
        return;
      }
      
      // Default fallback - try to navigate using GetX
      if (url.startsWith('/')) {
        Get.toNamed(url);
      } else {
        // If it's a full URL but determined to be internal, open in external browser
        await _navigateToExternalUrl(url);
      }
    } catch (e) {
      print('❌ UrlNavigationService: Error with internal navigation: $e');
      // Fallback to external navigation
      await _navigateToExternalUrl(url);
    }
  }

  /// Navigate to external URL in browser
  static Future<void> _navigateToExternalUrl(String url) async {
    print('🌐 UrlNavigationService: Opening external URL: $url');
    
    try {
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ UrlNavigationService: Successfully opened external URL');
      } else {
        throw 'Cannot launch URL: $url';
      }
    } catch (e) {
      print('❌ UrlNavigationService: Error launching external URL: $e');
      rethrow;
    }
  }

  /// Extract product ID from URL
  static String? _extractProductId(String url) {
    final regex = RegExp(r'/products/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Extract category ID from URL
  static String? _extractCategoryId(String url) {
    final regex = RegExp(r'/category/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Check if URL is valid
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get URL type (internal or external)
  static String getUrlType(String url) {
    return isInternalRoute(url) ? 'internal' : 'external';
  }
}
