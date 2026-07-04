class SearchLocationResponse {
  final bool? status;
  final String? message;
  final List<SearchLocationData>? data;

  SearchLocationResponse({this.status, this.message, this.data});

  factory SearchLocationResponse.fromJson(Map<String, dynamic> json) {
    return SearchLocationResponse(
      status: json['status'],
      message: json['message'],
      data: (json['data'] as List?)?.map((e) => SearchLocationData.fromJson(e)).toList(),
    );
  }
}

class SearchLocationData {
  final String? uuid;
  final String? placeId;
  final String? address;
  final double? latitude;
  final double? longitude;

  SearchLocationData({this.uuid, this.placeId, this.address, this.latitude, this.longitude});

  factory SearchLocationData.fromJson(Map<String, dynamic> json) {
    return SearchLocationData(
      uuid: json['uuid'] ?? json['geo_locat_uuid'],
      placeId: json['place_id'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}
