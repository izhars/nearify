import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OlaMapApp extends StatefulWidget {
  const OlaMapApp({super.key});

  @override
  State<OlaMapApp> createState() => _OlaMapAppState();
}

class _OlaMapAppState extends State<OlaMapApp> {
  LatLng? _currentLocation;
  String? _address;
  String? _locationName;
  bool _isLoadingLocation = false;
  MapController? _mapController;
  bool _mapReady = false;
  final String olaApiKey = "81BdA7HuHsQVRzEShFlU0BZTyAjpmDBaxd4zBmiJ";

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Refresh location and move map
  Future<void> _refreshLocation() async {
    if (_isLoadingLocation) return;

    await _getLocation();

    // If we have a location and map is ready, animate to it
    if (_currentLocation != null && _mapReady && _mapController != null) {
      _mapController!.move(_currentLocation!, 15.0);
    }
  }

  /// Get GPS location
  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _address = "Location permission denied";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Move map to current location smoothly (only if map is ready)
      if (_mapReady && _mapController != null) {
        _mapController!.move(_currentLocation!, 15.0);
      }

      await _fetchAddress(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _address = "Error getting location: $e";
        _isLoadingLocation = false;
      });
    }
  }

  /// Fetch address from Ola Maps
  Future<void> _fetchAddress(double lat, double lon) async {
    final url = "https://api.olamaps.io/places/v1/reverse-geocode?lat=$lat&lng=$lon";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $olaApiKey"},
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract different parts of the address
        final addressData = data["address"];
        final freeformAddress = addressData?["freeformAddress"] ?? "Address not found";

        // Try to get a more readable location name
        String locationName = "";
        if (addressData != null) {
          final building = addressData["building"] ?? "";
          final street = addressData["streetName"] ?? "";
          final district = addressData["district"] ?? "";
          final city = addressData["city"] ?? "";
          final state = addressData["state"] ?? "";

          // Create a readable location name
          List<String> nameParts = [];
          if (building.isNotEmpty) nameParts.add(building);
          if (street.isNotEmpty) nameParts.add(street);
          if (district.isNotEmpty && district != city) nameParts.add(district);
          if (city.isNotEmpty) nameParts.add(city);
          if (state.isNotEmpty) nameParts.add(state);

          locationName = nameParts.take(3).join(", "); // Take first 3 parts
          if (locationName.isEmpty) locationName = freeformAddress;
        }

        setState(() {
          _address = freeformAddress;
          _locationName = locationName.isEmpty ? freeformAddress : locationName;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _address = "API Error: ${response.body}";
          _locationName = "Unable to fetch location name";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _address = "API Error: $e";
        _locationName = "Unable to fetch location name";
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Ola Maps in Flutter"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: _isLoadingLocation
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.my_location),
              onPressed: _isLoadingLocation ? null : _refreshLocation,
            )
          ],
        ),
        body: _currentLocation == null
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Getting your location..."),
            ],
          ),
        )
            : Column(
          children: [
            // Map
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: 15,
                  minZoom: 5,
                  maxZoom: 18,
                  // Callback when map is ready
                  onMapReady: () {
                    setState(() {
                      _mapReady = true;
                    });
                  },
                  // Enhanced interaction options for smooth zooming
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                    // Enable smooth zoom animations
                    enableMultiFingerGestureRace: true,
                    pinchZoomWinGestures: MultiFingerGesture.all,
                    pinchMoveWinGestures: MultiFingerGesture.all,
                    // enableScrollWheel: true,
                    scrollWheelVelocity: 0.005,
                  ),
                ),
                children: [
                  // Use multiple tile sources for better performance
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: "com.example.olamaps",
                    maxZoom: 19,
                    tileSize: 256,
                    // Enhanced tile loading for smoothness
                    keepBuffer: 5,
                    panBuffer: 2,
                    // Use memory cache for better performance
                    tileProvider: NetworkTileProvider(),
                   // backgroundColor: Colors.grey[200],
                    errorTileCallback: (tile, error, stackTrace) {
                      print('Tile loading error: $error');
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 80,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Location Info Card
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        "Current Location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location Name (primary)
                  Text(
                    _locationName ?? "Fetching location...",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Full Address (secondary)
                  if (_address != null && _address != _locationName)
                    Text(
                      _address!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Coordinates (tertiary)
                  Text(
                    "Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, "
                        "Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}