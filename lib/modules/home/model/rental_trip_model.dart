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
  final CarCategory carCategory;
  final CarService carService;
  final List<LocationModel> pickupLocations;
  final List<LocationModel> dropoffLocations;
  final String createdAt;
  final MyBid? myBid;
  final String note;

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
    required this.carCategory,
    required this.carService,
    required this.pickupLocations,
    required this.dropoffLocations,
    required this.createdAt,
    this.myBid,
    this.note = '',
  });

  factory RentalTripModel.fromJson(Map<String, dynamic> json) {
    final distanceObj = json['distance'] as Map<String, dynamic>?;
    final double totalDist = distanceObj != null ? double.tryParse(distanceObj['total_km']?.toString() ?? '0') ?? 0.0 : 0.0;

    return RentalTripModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      serviceName: json['service_name'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      startDatetime: json['start_datetime'] ?? '',
      offerAmmount: (json['offer_ammount'] ?? 0).toDouble(),
      customerOfferAmmount: (json['customer_offer_ammount'] ?? 0).toDouble(),
      tripStatus: json['trip_status'] ?? '',
      createdAt: json['created_at'] ?? '',
      pickupKm: json['pickup_km'] ?? '0 m',
      totalDistance: totalDist,
      carCategory: CarCategory.fromJson(json['car_category'] ?? {}),
      carService: CarService.fromJson(json['car_service'] ?? {}),
      pickupLocations: (json['pickup_locations'] as List?)
              ?.map((e) => LocationModel.fromJson(e))
              .toList() ??
          [],
      dropoffLocations: (json['dropoff_locations'] as List?)
              ?.map((e) => LocationModel.fromJson(e))
              .toList() ??
          [],
      myBid: json['my_bid'] != null ? MyBid.fromJson(json['my_bid']) : null,
      note: json['note'] ?? json['trip_details']?['note'] ?? '',
    );
  }
}

class MyBid {
  final String uuid;
  final double amount;
  final String status;
  final String createdAt;

  MyBid({
    required this.uuid,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory MyBid.fromJson(Map<String, dynamic> json) {
    return MyBid(
      uuid: json['uuid'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
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
