import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nearify/utils/constants.dart';
import '../models/route_model.dart';

class RoutingService {

  Future<RouteModel> getRoute(LatLng start, LatLng end, {int retries = 3}) async {
    try {
      return await _getRouteOlaMaps(start, end, retries: retries);
    } catch (e) {
      print('Ola Maps routing failed: $e');
      return await _getRouteOSRM(start, end, retries: retries);
    }
  }

  /// Ola Maps routing
  Future<RouteModel> _getRouteOlaMaps(LatLng start, LatLng end, {int retries = 3}) async {
    // Validate API key early
    if (AppConstants.olaApiKey.isEmpty) {
      throw Exception('Ola Maps API key is missing or empty');
    }

    // Construct the URL with encoded parameters
    final origin = '${start.latitude},${start.longitude}';
    final destination = '${end.latitude},${end.longitude}';
    final url = 'https://api.olamaps.io/routing/v1/directions?origin=$origin&destination=$destination&mode=driving';

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final requestId = 'flutter-app-${DateTime.now().millisecondsSinceEpoch}';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${AppConstants.olaApiKey}',
            'X-Request-Id': requestId,
            'X-Correlation-Id': requestId,
          },
        );

        print('Ola Maps Routing Attempt $attempt - Status: ${response.statusCode}');
        print('Ola Maps Routing Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final polyline = data['routes']?[0]?['overview_polyline']?['points'] as String?;
          if (polyline == null) throw Exception('No polyline found in response');
          final leg = data['routes']?[0]?['legs']?[0];
          if (leg == null) throw Exception('No leg data found in response');
          return RouteModel.fromJson(
            {
              'duration': leg['duration'] ?? data['routes']?[0]?['duration'] ?? 0,
              'distance': leg['distance'] ?? data['routes']?[0]?['distance'] ?? 0,
            },
            _decodePolyline(polyline),
          );
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or restricted API key');
        } else {
          throw Exception('Ola API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Ola Maps routing attempt $attempt failed: $e');
        if (attempt == retries) {
          throw Exception('Ola Maps routing failed after $retries attempts: $e');
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Ola Maps routing failed after $retries attempts');
  }

  /// OSRM routing (OpenStreetMap)
  Future<RouteModel> _getRouteOSRM(LatLng start, LatLng end, {int retries = 3}) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http.get(Uri.parse(url));

        print('OSRM Routing Response Status (Attempt $attempt): ${response.statusCode}');
        print('OSRM Routing Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final polyline = data['routes']?[0]?['geometry'] as String?;
          if (polyline == null) throw Exception('No polyline found in response');
          // Extract duration and distance from legs[0]
          final leg = data['routes']?[0]?['legs']?[0];
          if (leg == null) throw Exception('No leg data found in response');
          return RouteModel.fromJson(
            {
              'duration': leg['duration'], // e.g., 1485.4 seconds
              'distance': leg['distance'], // e.g., 17885.6 meters
            },
            _decodePolyline(polyline),
          );
        } else {
          throw Exception('OSRM API Error: ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == retries) throw e;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('OSRM routing failed after $retries attempts');
  }

  /// Decode polyline string to list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}