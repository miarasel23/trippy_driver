class PackageDetailsModel {
  final String id;
  final String subscriptionUuid;
  final String subscriptionRenewalDateTime;
  final String subscriptionExpiryDateTime;
  final String carSubscriptionType;
  final double carSubscriptionPrice;

  PackageDetailsModel({
    required this.id,
    required this.subscriptionUuid,
    required this.subscriptionRenewalDateTime,
    required this.subscriptionExpiryDateTime,
    required this.carSubscriptionType,
    required this.carSubscriptionPrice,
  });

  factory PackageDetailsModel.fromJson(Map<String, dynamic> json) {
    return PackageDetailsModel(
      id: json['id']?.toString() ?? '',
      subscriptionUuid: json['subscription_uuid']?.toString() ?? '',
      subscriptionRenewalDateTime: json['subscription_renewal_date_time']?.toString() ?? '',
      subscriptionExpiryDateTime: json['subscription_expiry_date_time']?.toString() ?? '',
      carSubscriptionType: json['car_subscription_type']?.toString() ?? '',
      carSubscriptionPrice: double.tryParse(json['car_subscription_price']?.toString() ?? '0') ?? 0.0,
    );
  }
}
