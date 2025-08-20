import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (position.latitude < -90 || position.latitude > 90 || position.longitude < -180 || position.longitude > 180) {
        throw Exception('Invalid coordinates');
      }

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Error getting location: $e');
    }
  }
}