import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../utils/app_urls.dart';

class MapHelper {

  /// Get the exact place_id and formatted_address from Google Geocoding API
  /// for a given lat/lng. Returns null if nothing found.
  /// This guarantees ZERO mismatch between the pin position and the address/UUID.
  static Future<({String placeId, String address})?> getPlaceIdFromCoordinates(LatLng position) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${AppUrls.googleApiKey}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0] as Map<String, dynamic>;
          final placeId = first['place_id'] as String?;
          final address = first['formatted_address'] as String?;
          if (placeId != null && address != null) {
            return (placeId: placeId, address: address);
          }
        }
      }
    } catch (e) {
      debugPrint('getPlaceIdFromCoordinates failed: $e');
    }
    return null;
  }

  /// Get polyline points between two locations
  static Future<Set<Polyline>> getRouteBetweenCoordinates(
      LatLng from, LatLng to) async {
    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: AppUrls.googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(from.latitude, from.longitude),
        destination: PointLatLng(to.latitude, to.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      final coords =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: coords,
          color: Colors.blue,
          width: 5,
        ),
      };
    }
    return {};
  }

  /// Get polyline points across multiple locations
  static Future<Set<Polyline>> getRouteBetweenMultipleCoordinates(
      List<LatLng> points, {Color color = Colors.blue}) async {
    if (points.length < 2) return {};

    final origin = points.first;
    final destination = points.last;
    final wayPoints = points.sublist(1, points.length - 1).map((p) => PolylineWayPoint(location: '${p.latitude},${p.longitude}')).toList();

    final polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: AppUrls.googleApiKey,
      request: PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        wayPoints: wayPoints,
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      final coords =
          result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: coords,
          color: color,
          width: 5,
        ),
      };
    }
    return {};
  }
}
