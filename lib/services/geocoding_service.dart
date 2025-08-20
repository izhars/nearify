import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nearify/models/route_model.dart';
import 'package:nearify/utils/constants.dart' hide AppConstants;
import '../models/location_model.dart';
import '../utils/constants.dart';

class GeocodingService {

  /// Reverse geocoding with Ola Maps or Nominatim fallback
  Future<LocationModel> reverseGeocode(double lat, double lon, {int retries = 3}) async {
    try {
      return await _reverseGeocodeOlaMaps(lat, lon, retries: retries);
    } catch (e) {
      print('Ola Maps reverse geocoding failed: $e');
      return await _reverseGeocodeNominatim(lat, lon, retries: retries);
    }
  }

  /// Ola Maps reverse geocoding
  Future<LocationModel> _reverseGeocodeOlaMaps(double lat, double lon, {int retries = 3}) async {
    final url = 'https://api.olamaps.io/places/v1/reverse-geocode?lat=$lat&lng=$lon';

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${AppConstants.olaApiKey}',
            'X-Request-Id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
            'X-Correlation-Id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
          },
        );

        print('Ola Maps Reverse Geocode Response Status (Attempt $attempt): ${response.statusCode}');
        print('Ola Maps Reverse Geocode Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return _parseOlaResponse(data, lat, lon);
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or restricted API key');
        } else {
          throw Exception('Ola API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (attempt == retries) throw e;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Ola Maps reverse geocoding failed after $retries attempts');
  }

  /// Nominatim reverse geocoding
  Future<LocationModel> _reverseGeocodeNominatim(double lat, double lon, {int retries = 3}) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1';

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'OlaMapApp/1.0 (contact: your-email@example.com)'},
        );

        print('Nominatim Reverse Geocode Response Status (Attempt $attempt): ${response.statusCode}');
        print('Nominatim Reverse Geocode Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return _parseNominatimResponse(data, lat, lon);
        } else {
          throw Exception('Nominatim API Error: ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == retries) throw e;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Nominatim reverse geocoding failed after $retries attempts');
  }

  /// Parse Ola Maps response
  LocationModel _parseOlaResponse(Map<String, dynamic> data, double lat, double lon) {
    Map<String, dynamic>? addressData;
    String? freeformAddress;

    if (data.containsKey('results') && data['results'] is List && data['results'].isNotEmpty) {
      addressData = data['results'][0]['address'];
      freeformAddress = data['results'][0]['formatted_address'] ??
          data['results'][0]['display_name'] ??
          addressData?['freeformAddress'];
    } else if (data.containsKey('address')) {
      addressData = data['address'];
      freeformAddress = data['formatted_address'] ??
          data['display_name'] ??
          addressData?['freeformAddress'];
    }

    String locationName = _extractLocationName(addressData, freeformAddress);

    return LocationModel(
      latitude: lat,
      longitude: lon,
      address: freeformAddress ?? 'Address not found',
      name: locationName,
    );
  }

  /// Parse Nominatim response
  LocationModel _parseNominatimResponse(Map<String, dynamic> data, double lat, double lon) {
    final displayName = data['display_name'] ?? 'Address not found';
    final addressData = data['address'] as Map<String, dynamic>?;

    String locationName = _extractLocationName(addressData, displayName);

    return LocationModel(
      latitude: lat,
      longitude: lon,
      address: displayName,
      name: locationName,
    );
  }

  /// Extract readable location name
  String _extractLocationName(Map<String, dynamic>? addressData, String? fallback) {
    if (addressData == null) return fallback ?? 'Unknown location';

    List<String> nameParts = [];
    final possibleFields = [
      'building', 'house_number', 'house_name',
      'road', 'street', 'streetName',
      'neighbourhood', 'suburb', 'district',
      'city', 'town', 'village',
      'state', 'region'
    ];

    for (String field in possibleFields) {
      String? value = addressData[field]?.toString();
      if (value != null && value.isNotEmpty && !nameParts.contains(value)) {
        nameParts.add(value);
        if (nameParts.length >= 3) break;
      }
    }

    return nameParts.isEmpty ? (fallback ?? 'Unknown location') : nameParts.join(', ');
  }

  /// Autocomplete search
  Future<List<LocationModel>> autocomplete(String input, LatLng? currentLocation, {int retries = 3}) async {
    try {
      return await _autocompleteOlaMaps(input, currentLocation, retries: retries);
    } catch (e) {
      print('Ola Maps autocomplete failed: $e');
      return await _autocompleteNominatim(input, currentLocation, retries: retries);
    }
  }

  /// Ola Maps autocomplete
  Future<List<LocationModel>> _autocompleteOlaMaps(
      String input,
      LatLng? currentLocation, {
        int retries = 3,
      }) async {

    // URL encode the input to handle special characters
    final encodedInput = Uri.encodeComponent(input.trim());

    // Build URL with more flexible parameters
    String url = 'https://api.olamaps.io/places/v1/autocomplete?input=$encodedInput&api_key=${AppConstants.olaApiKey}';

    // Add location and radius only if current location is available
    if (currentLocation != null) {
      final location = '${currentLocation.latitude},${currentLocation.longitude}';
      url += '&location=$location&radius=50000'; // Increased radius to 50km
    }

    // Remove strictbounds or make it optional
    // url += '&strictbounds=false'; // Try without strict bounds first

    print('Ola Maps Request URL: $url');

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Request-Id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
            'X-Correlation-Id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
          },
        );

        print('Ola Maps Autocomplete Response Status (Attempt $attempt): ${response.statusCode}');
        print('Ola Maps Autocomplete Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final predictions = data['predictions'] as List<dynamic>? ?? [];

          // Check if predictions is empty and log for debugging
          if (predictions.isEmpty) {
            print('Warning: Empty predictions for input: "$input"');
            print('API returned status: ${data['status']}');
            if (data['error_message'] != null && data['error_message'].toString().isNotEmpty) {
              print('Error message: ${data['error_message']}');
            }
          }

          return predictions.map((p) {
            final geometry = p['geometry']?['location'];
            return LocationModel(
              latitude: geometry?['lat']?.toDouble() ?? 0.0,
              longitude: geometry?['lng']?.toDouble() ?? 0.0,
              address: p['description'] ?? 'Unknown place',
              name: p['structured_formatting']?['main_text'] ??
                  p['description'] ??
                  'Unknown place',
            );
          }).toList();
        } else {
          throw Exception(
              'Ola API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Attempt $attempt failed: $e');
        if (attempt == retries) throw e;
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw Exception('Ola Maps autocomplete failed after $retries attempts');
  }

// Alternative function without location-based filtering
  Future<List<LocationModel>> _autocompleteOlaMapsGlobal(
      String input, {
        int retries = 3,
      }) async {

    final encodedInput = Uri.encodeComponent(input.trim());
    final url = 'https://api.olamaps.io/places/v1/autocomplete?input=$encodedInput&api_key=${AppConstants.olaApiKey}';

    print('Ola Maps Global Request URL: $url');

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Request-Id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
          },
        );

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final predictions = data['predictions'] as List<dynamic>? ?? [];

          return predictions.map((p) {
            final geometry = p['geometry']?['location'];
            return LocationModel(
              latitude: geometry?['lat']?.toDouble() ?? 0.0,
              longitude: geometry?['lng']?.toDouble() ?? 0.0,
              address: p['description'] ?? 'Unknown place',
              name: p['structured_formatting']?['main_text'] ??
                  p['description'] ??
                  'Unknown place',
            );
          }).toList();
        } else {
          throw Exception('Ola API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (attempt == retries) throw e;
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    throw Exception('Ola Maps autocomplete failed after $retries attempts');
  }


  /// Nominatim autocomplete
  Future<List<LocationModel>> _autocompleteNominatim(String input, LatLng? currentLocation, {int retries = 3}) async {
    final url = 'https://nominatim.openstreetmap.org/search?q=$input&format=json&limit=5';

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'OlaMapApp/1.0 (contact: your-email@example.com)'},
        );

        print('Nominatim Autocomplete Response Status (Attempt $attempt): ${response.statusCode}');
        print('Nominatim Autocomplete Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List<dynamic>;
          return data.map((p) {
            return LocationModel(
              latitude: double.parse(p['lat'] ?? '0.0'),
              longitude: double.parse(p['lon'] ?? '0.0'),
              address: p['display_name'] ?? 'Unknown place',
              name: p['display_name']?.split(',')?.first ?? 'Unknown place',
            );
          }).toList();
        } else {
          throw Exception('Nominatim API Error: ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == retries) throw e;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Nominatim autocomplete failed after $retries attempts');
  }

  /// Fetch directions from Ola Maps
  Future<RouteModel> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    final waypointsStr = waypoints != null && waypoints.isNotEmpty
        ? waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')
        : '';

    final url = 'https://api.olamaps.io/routing/v1/directions'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '${waypointsStr.isNotEmpty ? '&waypoints=$waypointsStr' : ''}'
        '&mode=driving&alternatives=false&steps=true&overview=full&language=en&traffic_metadata=false'
        '&api_key=${AppConstants.olaApiKey}';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-request-id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
          'x-correlation-id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
          'Content-Type': 'application/json',
        },
      );

      print('Ola Maps Directions Response: ${response.statusCode}');
      print('Ola Maps Directions Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] != 'SUCCESS') {
          throw Exception('API returned error status: ${data['status']}');
        }

        final routes = data['routes'] as List<dynamic>?;
        if (routes == null || routes.isEmpty) {
          throw Exception('No routes found in response');
        }

        final route = routes[0] as Map<String, dynamic>;
        final legs = route['legs'] as List<dynamic>?;
        if (legs == null || legs.isEmpty) {
          throw Exception('No legs found in route');
        }

        final leg = legs[0] as Map<String, dynamic>;
        final stepsData = leg['steps'] as List<dynamic>? ?? [];

        // Decode polyline with better error handling
        List<LatLng> polylinePoints = [];
        final overviewPolyline = route['overview_polyline'];

        if (overviewPolyline != null) {
          final polylineString = overviewPolyline is Map<String, dynamic>
              ? overviewPolyline['points'] as String?
              : overviewPolyline as String?;

          if (polylineString != null && polylineString.isNotEmpty) {
            try {
              polylinePoints = polylineString.decodePolyline();
              print('Decoded ${polylinePoints.length} polyline points');
            } catch (e) {
              print('Error decoding polyline: $e');
              // Fallback: create simple line from steps if available
              polylinePoints = _createFallbackPolyline(stepsData, origin, destination);
            }
          }
        }

        // Final fallback: just origin and destination
        if (polylinePoints.isEmpty) {
          print('Using fallback polyline: origin to destination');
          polylinePoints = [origin, destination];
        }

        // Create RouteModel with proper data structure for Ola Maps
        return RouteModel.fromJson(
          {
            'duration': leg['duration'], // This is an integer (seconds)
            'distance': leg['distance'], // This is an integer (meters)
            'steps': stepsData,
          },
          polylinePoints,
        );
      } else {
        throw Exception(
            'Ola Directions API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch Ola Maps directions: $e');
    }
  }

// Helper method to create polyline from steps if main polyline fails
  List<LatLng> _createFallbackPolyline(List<dynamic> stepsData, LatLng origin, LatLng destination) {
    List<LatLng> points = [origin];

    for (var step in stepsData) {
      if (step is Map<String, dynamic>) {
        final endLoc = step['end_location'];
        if (endLoc != null && endLoc is Map<String, dynamic>) {
          final lat = endLoc['lat'];
          final lng = endLoc['lng'];
          if (lat is num && lng is num) {
            points.add(LatLng(lat.toDouble(), lng.toDouble()));
          }
        }
      }
    }

    // Ensure destination is the last point
    if (points.last.latitude != destination.latitude ||
        points.last.longitude != destination.longitude) {
      points.add(destination);
    }

    return points;
  }
}