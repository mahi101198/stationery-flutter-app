/// Delivery Info Model - Represents delivery and trust information
class DeliveryInfoModel {
  final bool codAvailable;
  final String returnPolicy;
  final String deliveryEstimate;

  const DeliveryInfoModel({
    required this.codAvailable,
    required this.returnPolicy,
    required this.deliveryEstimate,
  });

  /// Create from Firestore document
  factory DeliveryInfoModel.fromFirestore(Map<String, dynamic> data) {
    return DeliveryInfoModel(
      codAvailable: data['cod_available'] ?? false,
      returnPolicy: data['return_policy'] ?? '',
      deliveryEstimate: data['estimated_delivery'] ?? data['delivery_estimate_text'] ?? data['delivery_estimate'] ?? '',
    );
  }

  /// Create empty delivery info
  factory DeliveryInfoModel.empty() {
    return const DeliveryInfoModel(
      codAvailable: false,
      returnPolicy: '',
      deliveryEstimate: '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'cod_available': codAvailable,
      'return_policy': returnPolicy,
      'delivery_estimate': deliveryEstimate,
    };
  }

  /// Convert to Map
  Map<String, dynamic> toMap() => toFirestore();

  /// Create copy with optional parameter overrides
  DeliveryInfoModel copyWith({
    bool? codAvailable,
    String? returnPolicy,
    String? deliveryEstimate,
  }) {
    return DeliveryInfoModel(
      codAvailable: codAvailable ?? this.codAvailable,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      deliveryEstimate: deliveryEstimate ?? this.deliveryEstimate,
    );
  }

  @override
  String toString() => 'DeliveryInfoModel(codAvailable: $codAvailable, returnPolicy: $returnPolicy, deliveryEstimate: $deliveryEstimate)';
}
