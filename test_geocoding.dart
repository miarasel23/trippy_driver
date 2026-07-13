import 'package:geocoding/geocoding.dart';

void main() async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(23.8036783, 90.3741158, localeIdentifier: "bn_BD");
    print("Success: ${placemarks.first.street}, ${placemarks.first.subLocality}, ${placemarks.first.locality}");
  } catch (e) {
    print("Error: $e");
  }
}
