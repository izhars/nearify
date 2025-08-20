import 'package:latlong2/latlong.dart';

class StepModel {
  final String instruction;
  final double? distance; // meters
  final double? duration; // seconds
  final LatLng? startLocation;
  final LatLng? endLocation;

  StepModel({
    required this.instruction,
    this.distance,
    this.duration,
    this.startLocation,
    this.endLocation,
  });

  factory StepModel.fromJson(Map<String, dynamic> json) {
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle string values that might have units
        String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleanValue);
      }
      return null;
    }

    LatLng? safeLatLng(Map<String, dynamic>? loc) {
      if (loc == null) return null;
      final lat = loc['lat'] ?? loc['latitude'];
      final lng = loc['lng'] ?? loc['longitude'];
      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
      return null;
    }

    return StepModel(
      instruction: json['instructions']?.toString() ??
          json['instruction']?.toString() ??
          json['html_instructions']?.toString()?.replaceAll(RegExp(r'<[^>]*>'), '') ??
          'Proceed',
      distance: safeToDouble(json['distance']), // Ola Maps returns direct numeric values
      duration: safeToDouble(json['duration']), // Ola Maps returns direct numeric values
      startLocation: safeLatLng(json['start_location']),
      endLocation: safeLatLng(json['end_location']),
    );
  }
}

class RouteModel {
  final String? duration; // formatted e.g. "45 mins"
  final String? distance; // formatted e.g. "18.8 km"
  final List<LatLng> polylinePoints;
  final List<StepModel> steps;

  RouteModel({
    this.duration,
    this.distance,
    required this.polylinePoints,
    required this.steps,
  });

  factory RouteModel.fromJson(
      Map<String, dynamic> json, List<LatLng> polylinePoints) {

    String? formatDuration(dynamic duration) {
      if (duration == null) return null;

      // Handle numeric values (seconds) - Ola Maps returns seconds as integers
      if (duration is int) {
        final seconds = duration;
        if (seconds < 60) {
          return '${seconds}s';
        } else if (seconds < 3600) {
          final minutes = (seconds / 60).round();
          return '${minutes}m';
        } else {
          final hours = (seconds / 3600).floor();
          final remainingMinutes = ((seconds % 3600) / 60).round();
          return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
        }
      }

      // Handle double values
      if (duration is double) {
        final seconds = duration.toInt();
        if (seconds < 60) {
          return '${seconds}s';
        } else if (seconds < 3600) {
          final minutes = (seconds / 60).round();
          return '${minutes}m';
        } else {
          final hours = (seconds / 3600).floor();
          final remainingMinutes = ((seconds % 3600) / 60).round();
          return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
        }
      }

      // If it's already a formatted string, return as-is
      if (duration is String) {
        return duration;
      }

      return duration?.toString();
    }

    String? formatDistance(dynamic distance) {
      if (distance == null) return null;

      // Handle numeric values (meters) - Ola Maps returns meters as integers
      if (distance is int) {
        final meters = distance;
        if (meters >= 1000) {
          final km = (meters / 1000).toStringAsFixed(1);
          return '${km}km';
        } else {
          return '${meters}m';
        }
      }

      // Handle double values
      if (distance is double) {
        final meters = distance.toInt();
        if (meters >= 1000) {
          final km = (meters / 1000).toStringAsFixed(1);
          return '${km}km';
        } else {
          return '${meters}m';
        }
      }

      // If it's already a formatted string, return as-is
      if (distance is String) {
        return distance;
      }

      return distance?.toString();
    }

    List<StepModel> parseSteps(dynamic stepsData) {
      if (stepsData == null) return [];
      if (stepsData is List) {
        return stepsData.map((step) {
          if (step is Map<String, dynamic>) {
            return StepModel.fromJson(step);
          }
          return StepModel(instruction: step.toString());
        }).toList();
      }
      return [];
    }

    return RouteModel(
      duration: formatDuration(json['duration']),
      distance: formatDistance(json['distance']),
      polylinePoints: polylinePoints,
      steps: parseSteps(json['steps']),
    );
  }
}

// Extension to decode polyline (if not already implemented)
extension PolylineDecoder on String {
  List<LatLng> decodePolyline() {
    try {
      List<LatLng> points = [];
      int index = 0;
      int len = length;
      int lat = 0;
      int lng = 0;

      while (index < len) {
        int b;
        int shift = 0;
        int result = 0;

        // Decode latitude
        do {
          if (index >= len) break;
          b = codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < len);

        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        if (index >= len) break;

        shift = 0;
        result = 0;

        // Decode longitude
        do {
          if (index >= len) break;
          b = codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < len);

        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        points.add(LatLng(lat / 1E5, lng / 1E5));
      }
      return points;
    } catch (e) {
      print('Error decoding polyline: $e');
      return []; // Return empty list on error
    }
  }
}