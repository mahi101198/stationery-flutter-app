/// Content Card Model - Represents dynamic backend-driven content cards
class ContentCardModel {
  final String cardId;
  final String title;
  final String type; // "text" | "list" | "steps" | "key_value" | "warning" | "info"
  final dynamic data;
  final int order; // For ordering cards, lower number = higher priority

  const ContentCardModel({
    required this.cardId,
    required this.title,
    required this.type,
    required this.data,
    this.order = 999, // Default to high number if not specified
  });

  /// Check if card has valid data
  bool get hasData {
    if (data == null) return false;
    if (data is String) return (data as String).isNotEmpty;
    if (data is List) return (data as List).isNotEmpty;
    if (data is Map) return (data as Map).isNotEmpty;
    return true;
  }

  /// Create from Firestore document
  factory ContentCardModel.fromFirestore(Map<String, dynamic> cardData) {
    return ContentCardModel(
      cardId: cardData['card_id'] ?? '',
      title: cardData['title'] ?? '',
      type: cardData['type'] ?? 'text',
      data: cardData['data'],
      order: cardData['order'] ?? 999,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'card_id': cardId,
      'title': title,
      'type': type,
      'data': data,
      'order': order,
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() => toFirestore();

  /// Create copy with optional parameter overrides
  ContentCardModel copyWith({
    String? cardId,
    String? title,
    String? type,
    dynamic data,
    int? order,
  }) {
    return ContentCardModel(
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      type: type ?? this.type,
      data: data ?? this.data,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentCardModel &&
          runtimeType == other.runtimeType &&
          cardId == other.cardId;

  @override
  int get hashCode => cardId.hashCode;

  @override
  String toString() => 'ContentCardModel(cardId: $cardId, title: $title, type: $type)';
}
