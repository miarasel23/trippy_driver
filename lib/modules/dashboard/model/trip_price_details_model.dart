import 'dart:convert';

class TripPriceDetailsRequest {
  final String platform;
  final String languageCode;
  final String actionWhen;
  final String serviceType;
  final String countryCode;
  final List<String> pickupLocationUuid;
  final List<String> dropoffLocationUuid;
  final String startDatetime;
  final String? endDatetime;

  TripPriceDetailsRequest({
    required this.platform,
    required this.languageCode,
    this.actionWhen = "trip_details_customer_admin",
    required this.serviceType,
    this.countryCode = "BD",
    required this.pickupLocationUuid,
    required this.dropoffLocationUuid,
    required this.startDatetime,
    this.endDatetime,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'platform': platform,
      'language_code': languageCode,
      'action_when': actionWhen,
      'servive_type': serviceType,
      'country_code': countryCode,
      'start_datetime': startDatetime,
      'pickup_location_uuid': jsonEncode(pickupLocationUuid),
      'dropoff_location_uuid': jsonEncode(dropoffLocationUuid),
    };
    
    if (endDatetime != null) {
      data['end_datetime'] = endDatetime;
    }

    return data;
  }
}

class TripPriceDetailsResponse {
  final bool? status;
  final String? message;
  final dynamic data; // We'll leave data dynamic for now since the exact vehicle details structure wasn't provided

  TripPriceDetailsResponse({this.status, this.message, this.data});

  factory TripPriceDetailsResponse.fromJson(Map<String, dynamic> json) {
    return TripPriceDetailsResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'],
    );
  }
}
