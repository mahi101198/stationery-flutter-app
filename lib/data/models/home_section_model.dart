import 'package:cloud_firestore/cloud_firestore.dart';

/// Home Section Model - Represents a section in the home screen
/// Firestore path: home_sections/{section_id}
class HomeSectionModel {
  final String sectionId;
  final String title;
  final String? subtitle;
  final String type; // popular | flash_sale | seasonal_sale | category_spotlight | new_arrivals | recommended | deals | custom
  final int rank;
  final String status; // active | inactive | scheduled
  final String? iconUrl;
  final String? backgroundColor;
  final int? maxItems;
  final bool? showViewAll;
  final String? viewAllLink;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeSectionModel({
    required this.sectionId,
    required this.title,
    this.subtitle,
    required this.type,
    required this.rank,
    required this.status,
    this.iconUrl,
    this.backgroundColor,
    this.maxItems,
    this.showViewAll,
    this.viewAllLink,
    this.startTime,
    this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Check if section is active
  bool get isActive => status == 'active';

  /// Check if section is scheduled
  bool get isScheduled => status == 'scheduled';

  /// Check if section is currently live (active + within time range)
  bool get isLive {
    if (status != 'active') return false;
    
    final now = DateTime.now();
    
    // Check start time
    if (startTime != null && now.isBefore(startTime!)) {
      return false;
    }
    
    // Check end time
    if (endTime != null && now.isAfter(endTime!)) {
      return false;
    }
    
    return true;
  }

  /// Check if section should show "View All" button
  bool get shouldShowViewAll => showViewAll ?? true;

  // ==================== FACTORY CONSTRUCTORS ====================

  /// Create from Firestore document
  factory HomeSectionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return HomeSectionModel(
      sectionId: data['section_id'] ?? doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      type: data['type'] ?? 'custom',
      rank: data['rank'] ?? 0,
      status: data['status'] ?? 'inactive',
      iconUrl: data['icon_url'],
      backgroundColor: data['background_color'],
      maxItems: data['max_items'],
      showViewAll: data['show_view_all'],
      viewAllLink: data['view_all_link'],
      startTime: _parseTimestamp(data['start_time']),
      endTime: _parseTimestamp(data['end_time']),
      createdAt: _parseTimestamp(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updated_at']) ?? DateTime.now(),
    );
  }

  /// Create from Map
  factory HomeSectionModel.fromMap(Map<String, dynamic> data) {
    return HomeSectionModel(
      sectionId: data['section_id'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      type: data['type'] ?? 'custom',
      rank: data['rank'] ?? 0,
      status: data['status'] ?? 'inactive',
      iconUrl: data['icon_url'],
      backgroundColor: data['background_color'],
      maxItems: data['max_items'],
      showViewAll: data['show_view_all'],
      viewAllLink: data['view_all_link'],
      startTime: _parseTimestamp(data['start_time']),
      endTime: _parseTimestamp(data['end_time']),
      createdAt: _parseTimestamp(data['created_at']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updated_at']) ?? DateTime.now(),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Parse timestamp from Firestore (handles both Timestamp and number)
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      // Unix timestamp in seconds
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    
    return null;
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'section_id': sectionId,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'rank': rank,
      'status': status,
      'icon_url': iconUrl,
      'background_color': backgroundColor,
      'max_items': maxItems,
      'show_view_all': showViewAll,
      'view_all_link': viewAllLink,
      'start_time': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'end_time': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() {
    return 'HomeSectionModel(sectionId: $sectionId, title: $title, type: $type, rank: $rank, status: $status, isLive: $isLive)';
  }
}
