import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking banner view analytics (impressions)
class BannerViewAnalyticsModel {
  final String viewId;
  final String bannerId;
  final String userId;
  final String? userEmail;
  final DateTime viewedAt;
  final String userAgent;
  final String? ipAddress;
  final String? country;
  final String? region;
  final String? city;
  final String? source; // 'home_carousel', 'category_page', etc.
  final Map<String, dynamic> metadata;

  const BannerViewAnalyticsModel({
    required this.viewId,
    required this.bannerId,
    required this.userId,
    this.userEmail,
    required this.viewedAt,
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
      'viewId': viewId,
      'bannerId': bannerId,
      'userId': userId,
      'userEmail': userEmail,
      'viewedAt': Timestamp.fromDate(viewedAt),
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
  factory BannerViewAnalyticsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return BannerViewAnalyticsModel(
      viewId: doc.id,
      bannerId: data['bannerId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      viewedAt: _parseTimestamp(data['viewedAt']),
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
      other is BannerViewAnalyticsModel &&
          runtimeType == other.runtimeType &&
          viewId == other.viewId;

  @override
  int get hashCode => viewId.hashCode;
}
