import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking banner click analytics
class BannerAnalyticsModel {
  final String analyticsId;
  final String bannerId;
  final String userId;
  final String? userEmail;
  final String clickUrl;
  final String clickType; // 'external' or 'internal'
  final DateTime clickedAt;
  final String userAgent;
  final String? ipAddress;
  final String? country;
  final String? region;
  final String? city;
  final String? source; // 'home_carousel', 'category_page', etc.
  final Map<String, dynamic> metadata;

  const BannerAnalyticsModel({
    required this.analyticsId,
    required this.bannerId,
    required this.userId,
    this.userEmail,
    required this.clickUrl,
    required this.clickType,
    required this.clickedAt,
    required this.userAgent,
    this.ipAddress,
    this.country,
    this.region,
    this.city,
    this.source,
    this.metadata = const {},
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'analyticsId': analyticsId,
      'bannerId': bannerId,
      'userId': userId,
      'userEmail': userEmail,
      'clickUrl': clickUrl,
      'clickType': clickType,
      'clickedAt': Timestamp.fromDate(clickedAt),
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'country': country,
      'region': region,
      'city': city,
      'source': source,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory BannerAnalyticsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return BannerAnalyticsModel(
      analyticsId: doc.id,
      bannerId: data['bannerId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      clickUrl: data['clickUrl'] ?? '',
      clickType: data['clickType'] ?? 'external',
      clickedAt: _parseTimestamp(data['clickedAt']),
      userAgent: data['userAgent'] ?? '',
      ipAddress: data['ipAddress'],
      country: data['country'],
      region: data['region'],
      city: data['city'],
      source: data['source'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Helper method to parse timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BannerAnalyticsModel &&
          runtimeType == other.runtimeType &&
          analyticsId == other.analyticsId;

  @override
  int get hashCode => analyticsId.hashCode;
}

// Note: BannerAnalyticsSummary model removed as this is a user app
// Individual click records are saved to banner subcollections for admin app usage
