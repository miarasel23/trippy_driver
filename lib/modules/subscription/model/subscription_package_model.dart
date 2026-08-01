class SubscriptionPackageModel {
  final int id;
  final String uuid;
  final String subscriptionType;
  final double price;
  final double previousPrice;
  final int validateFor; // days
  final String status;

  SubscriptionPackageModel({
    required this.id,
    required this.uuid,
    required this.subscriptionType,
    required this.price,
    required this.previousPrice,
    required this.validateFor,
    required this.status,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPackageModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      subscriptionType: json['subscription_type'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      previousPrice: double.tryParse(json['previous_price']?.toString() ?? '0') ?? 0.0,
      validateFor: int.tryParse(json['validate_for']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? '',
    );
  }
}
