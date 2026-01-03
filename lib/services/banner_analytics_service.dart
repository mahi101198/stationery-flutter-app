import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:rps_stationery/data/models/banner_analytics_model.dart';
import 'package:rps_stationery/utils/navigation/url_navigation_service.dart';

/// Service for tracking banner click analytics with location detection
/// Saves analytics data to banner subcollection for admin app usage
class BannerAnalyticsService {
  static const String _bannerCollectionName = 'banners';
  static const String _analyticsSubcollectionName = 'analytics';
  static const String _ipApiUrl = 'http://ip-api.com/json/';

  /// Track banner click with analytics
  static Future<void> trackBannerClick({
    required String bannerId,
    required String clickUrl,
    String? source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      dev.log('📊 BannerAnalyticsService: Tracking banner click for banner: $bannerId');
      
      // Get user information
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final userEmail = user?.email;

      // Get location information
      final locationData = await _getLocationData();
      
      // Get user agent and other device info
      final userAgent = await _getUserAgent();
      
      // Determine click type
      final clickType = UrlNavigationService.isInternalRoute(clickUrl) ? 'internal' : 'external';
      
      // Create analytics record
      final analyticsId = '${bannerId}_${DateTime.now().millisecondsSinceEpoch}_${userId.hashCode}';
      final analyticsRecord = BannerAnalyticsModel(
        analyticsId: analyticsId,
        bannerId: bannerId,
        userId: userId,
        userEmail: userEmail,
        clickUrl: clickUrl,
        clickType: clickType,
        clickedAt: DateTime.now(),
        userAgent: userAgent,
        ipAddress: locationData['ip'],
        country: locationData['country'],
        region: locationData['regionName'],
        city: locationData['city'],
        source: source ?? 'home_carousel',
        metadata: metadata ?? {},
      );

      // Save to Firestore subcollection
      await _saveAnalyticsRecord(analyticsRecord);
      
      dev.log('✅ BannerAnalyticsService: Successfully tracked banner click');
      
    } catch (e) {
      dev.log('❌ BannerAnalyticsService: Error tracking banner click: $e');
      // Don't throw error - analytics should not break the app
    }
  }

  /// Get location data using IP geolocation
  static Future<Map<String, String?>> _getLocationData() async {
    try {
      dev.log('🌍 BannerAnalyticsService: Getting location data...');
      
      final response = await http.get(
        Uri.parse(_ipApiUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        dev.log('📍 BannerAnalyticsService: Location data received: ${data.toString()}');
        
        return {
          'ip': data['query'] ?? 'unknown',
          'country': data['country'] ?? 'unknown',
          'regionName': data['regionName'] ?? 'unknown',
          'city': data['city'] ?? 'unknown',
          'timezone': data['timezone'] ?? 'unknown',
          'isp': data['isp'] ?? 'unknown',
        };
      } else {
        dev.log('⚠️ BannerAnalyticsService: Failed to get location data, status: ${response.statusCode}');
        return _getDefaultLocationData();
      }
    } catch (e) {
      dev.log('❌ BannerAnalyticsService: Error getting location data: $e');
      return _getDefaultLocationData();
    }
  }

  /// Get default location data when API fails
  static Map<String, String?> _getDefaultLocationData() {
    return {
      'ip': 'Manual',
      'country': 'Manual',
      'regionName': 'Manual',
      'city': 'Manual',
      'timezone': 'Manual',
      'isp': 'Manual',
    };
  }

  /// Get user agent string
  static Future<String> _getUserAgent() async {
    try {
      // For Flutter mobile apps, we'll create a custom user agent
      return 'RPSStationery-Mobile/${Platform.operatingSystem}-${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'RPSStationery-Mobile/Unknown';
    }
  }

  /// Save analytics record to Firestore subcollection under banner document
  static Future<void> _saveAnalyticsRecord(BannerAnalyticsModel record) async {
    try {
      await FirebaseFirestore.instance
          .collection(_bannerCollectionName)
          .doc(record.bannerId)
          .collection(_analyticsSubcollectionName)
          .doc(record.analyticsId)
          .set(record.toFirestore());
      
      dev.log('💾 BannerAnalyticsService: Saved analytics record to subcollection: ${record.analyticsId}');
    } catch (e) {
      dev.log('❌ BannerAnalyticsService: Error saving analytics record: $e');
      rethrow;
    }
  }

  // Note: Analytics dashboard methods removed as this is a user app
  // Analytics data is saved to banner subcollections for admin app usage
}
