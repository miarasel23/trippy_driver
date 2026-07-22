class RentalTripModel {
  final int id;
  final String uuid;
  final String serviceName;
  final String paymentMethod;
  final String startDatetime;
  final double offerAmmount;
  final double customerOfferAmmount;
  final String tripStatus;
  final String pickupKm;
  final double totalDistance;
  final bool givenReview;
  final CarCategory carCategory;
  final CarService carService;
  final List<LocationModel> pickupLocations;
  final List<LocationModel> dropoffLocations;
  final String createdAt;
  final MyBid? myBid;
  final String note;
  final List<CustomerModel> customer;

  RentalTripModel({
    required this.id,
    required this.uuid,
    required this.serviceName,
    required this.paymentMethod,
    required this.startDatetime,
    required this.offerAmmount,
    required this.customerOfferAmmount,
    required this.tripStatus,
    required this.pickupKm,
    required this.totalDistance,
    required this.givenReview,
    required this.carCategory,
    required this.carService,
    required this.pickupLocations,
    required this.dropoffLocations,
    required this.createdAt,
    this.myBid,
    this.note = '',
    this.customer = const [],
  });

  factory RentalTripModel.fromJson(Map<String, dynamic> json) {
    final tripDetails = json['trip_details'] as Map<String, dynamic>? ?? json;
    final locationDetails = json['location_details'] as Map<String, dynamic>?;

    final distanceObj = json['distance'] as Map<String, dynamic>?;
    final double totalDist = distanceObj != null ? double.tryParse(distanceObj['total_km']?.toString() ?? '0') ?? 0.0 : 0.0;

    return RentalTripModel(
      id: tripDetails['id'] ?? 0,
      uuid: tripDetails['uuid'] ?? '',
      serviceName: tripDetails['service_name'] ?? '',
      paymentMethod: tripDetails['payment_method'] ?? '',
      startDatetime: tripDetails['start_datetime'] ?? '',
      offerAmmount: (tripDetails['offer_amount'] ?? tripDetails['offer_ammount'] ?? 0).toDouble(),
      customerOfferAmmount: (tripDetails['customer_offer_amount'] ?? tripDetails['customer_offer_ammount'] ?? 0).toDouble(),
      tripStatus: tripDetails['trip_status'] ?? '',
      createdAt: tripDetails['created_at'] ?? '',
      pickupKm: tripDetails['pickup_km'] ?? '0 m',
      totalDistance: totalDist,
      givenReview: tripDetails['given_review'] ?? false,
      carCategory: CarCategory.fromJson(tripDetails['car_category'] ?? {}),
      carService: CarService.fromJson(tripDetails['car_service'] ?? {}),
      pickupLocations: ((locationDetails?['pickup_locations'] ?? json['pickup_locations']) as List?)
              ?.map((e) => LocationModel.fromJson(e))
              .toList() ??
          [],
      dropoffLocations: ((locationDetails?['dropoff_locations'] ?? json['dropoff_locations']) as List?)
              ?.map((e) => LocationModel.fromJson(e))
              .toList() ??
          [],
      myBid: json['my_bid'] != null ? MyBid.fromJson(json['my_bid']) : null,
      note: tripDetails['note'] ?? json['note'] ?? '',
      customer: (json['customer'] != null && json['customer'] is List && (json['customer'] as List).isNotEmpty)
          ? (json['customer'] as List).map((e) => CustomerModel.fromJson(e)).toList()
          : (json['customer_details'] != null && json['customer_details'] is Map)
              ? [CustomerModel.fromJson(json['customer_details'] as Map<String, dynamic>)]
              : [],
    );
  }
}

class MyBid {
  final String uuid;
  final double amount;
  final double totalAmount;
  final String status;
  final String createdAt;

  MyBid({
    required this.uuid,
    required this.amount,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory MyBid.fromJson(Map<String, dynamic> json) {
    return MyBid(
      uuid: json['uuid'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CarCategory {
  final String uuid;
  final String carType;
  final String carAvatar;

  CarCategory({
    required this.uuid,
    required this.carType,
    required this.carAvatar,
  });

  factory CarCategory.fromJson(Map<String, dynamic> json) {
    return CarCategory(
      uuid: json['uuid'] ?? '',
      carType: json['car_type'] ?? '',
      carAvatar: json['car_avatar'] ?? '',
    );
  }
}

class CarService {
  final String uuid;
  final String serviceName;
  final String avatar;

  CarService({
    required this.uuid,
    required this.serviceName,
    required this.avatar,
  });

  factory CarService.fromJson(Map<String, dynamic> json) {
    return CarService(
      uuid: json['uuid'] ?? '',
      serviceName: json['service_name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}

class LocationModel {
  final String uuid;
  final String address;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.uuid,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      uuid: json['uuid'] ?? '',
      address: json['address'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CustomerModel {
  final String rentBidUuid;
  final String customerUuid;
  final String name;
  final String email;
  final String profilePicture;
  final String countryCode;
  final bool isActive;
  final String phone;
  final String bidStatus;
  final bool hasBid;
  final bool reviewStatus;
  final double averageRating;

  CustomerModel({
    required this.rentBidUuid,
    required this.customerUuid,
    required this.name,
    required this.email,
    required this.profilePicture,
    required this.countryCode,
    required this.isActive,
    required this.phone,
    required this.bidStatus,
    required this.hasBid,
    required this.reviewStatus,
    required this.averageRating,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      rentBidUuid: json['rent_bid_uuid'] ?? '',
      customerUuid: json['customer_uuid'] ?? json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      countryCode: json['country_code'] ?? '',
      isActive: json['is_active'] ?? false,
      phone: json['phone'] ?? '',
      bidStatus: json['bid_status'] ?? '',
      hasBid: json['has_bid'] ?? false,
      reviewStatus: json['given_review'] ?? json['review_status'] ?? false,
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
    );
  }
}
