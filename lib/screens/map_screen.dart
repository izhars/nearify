// main_map_screen.dart
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nearify/models/location_model.dart';
import 'package:nearify/services/location_service.dart';
import 'package:nearify/widgets/error_banner_widget.dart';
import 'package:nearify/widgets/location_bar_widget.dart';
import 'package:nearify/widgets/location_details_tab_widget.dart';
import '../models/route_model.dart';
import '../services/geocoding_service.dart';
import '../widgets/map_widget.dart';
import '../widgets/location_card.dart';
import '../widgets/search_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isLoading = false;
  bool _mapReady = false;
  bool _showLocationDetails = false;
  String? _error;
  LatLng? _currentLocation;
  LocationModel? _currentLocationModel;
  LocationModel? _destination;
  RouteModel? _route;
  List<LocationModel> _suggestions = [];
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getDirections() async {
    if (_currentLocation == null || _destination == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final route = await _geocodingService.getDirections(
        origin: _currentLocation!,
        destination: LatLng(_destination!.latitude, _destination!.longitude),
      );

      setState(() {
        _route = route as RouteModel?;
        _isLoading = false;
      });

      if (route.polylinePoints.isNotEmpty) {
        _fitMapToRoute();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      _showErrorSnackBar('Error getting directions: $e');
    }
  }

  void _fitMapToRoute() {
    if (_route == null || _route!.polylinePoints.isEmpty) return;

    final points = _route!.polylinePoints;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _handleMapTap(LatLng latLng) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationModel = await _geocodingService.reverseGeocode(
          latLng.latitude, latLng.longitude);

      setState(() {
        _destination = locationModel as LocationModel?;
        _searchController.text = locationModel.name ?? locationModel.address ?? '';
        _showLocationDetails = true;
        _isLoading = false;
      });

      if (_currentLocation != null) {
        await _getDirections();
      }

      _mapController.move(latLng, _mapController.camera.zoom);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error getting location details: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = location;
      });

      if (_mapReady && _mapController != null) {
        _mapController.move(location!, 15.0);
      }

      final locationModel = await _geocodingService.reverseGeocode(
          location!.latitude, location.longitude);

      setState(() {
        _currentLocationModel = locationModel as LocationModel?;
        _isLoading = false;
      });

      if (_destination != null) {
        await _getDirections();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error getting location: $e');
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    try {
      final suggestions = await _geocodingService.autocomplete(query, _currentLocation);
      setState(() {
        _suggestions = suggestions.cast<LocationModel>();
      });
    } catch (e) {
      _showErrorSnackBar('Search error: $e', color: Colors.orange);
    }
  }

  Future<void> _selectDestination(LocationModel destination) async {
    setState(() {
      _destination = destination;
      _suggestions = [];
      _searchController.text = destination.name ?? destination.address ?? '';
    });

    if (_currentLocation != null) {
      await _getDirections();
    }
  }

  void _clearDestination() {
    setState(() {
      _destination = null;
      _route = null;
      _searchController.clear();
      _suggestions = [];
      _showLocationDetails = false;
    });
  }

  void _toggleLocationDetails() {
    setState(() {
      _showLocationDetails = !_showLocationDetails;
    });
  }

  void _showErrorSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _dismissError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearify Maps'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.my_location_rounded),
            onPressed: _isLoading ? null : _getCurrentLocation,
            tooltip: 'Get current location',
          ),
        ],
      ),
      body: _currentLocation == null
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      )
          : Column(
        children: [
          // Search Bar
          SearchBar(
            controller: _searchController,
            suggestions: _suggestions,
            onSearch: _search,
            onSuggestionSelected: _selectDestination,
            onClear: _clearDestination,
            currentDestination: _destination?.name ?? _destination?.address,
          ),

          // Map with overlays
          Expanded(
            child: Stack(
              children: [
                MapWidget(
                  mapController: _mapController,
                  currentLocation: _currentLocation,
                  destination: _destination,
                  route: _route,
                  onMapReady: () {
                    setState(() {
                      _mapReady = true;
                    });
                  },
                  onMapTap: _handleMapTap,
                ),

                // Error Banner
                if (_error != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: ErrorBannerWidget(
                      error: _error!,
                      onDismiss: _dismissError,
                    ),
                  ),

                // Floating Action Button for Details
                if (_destination != null)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton.small(
                      onPressed: _toggleLocationDetails,
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).primaryColor,
                      elevation: 4,
                      child: Icon(
                        _showLocationDetails ? Icons.map_rounded : Icons.info_rounded,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Compact Location Bar
          LocationBarWidget(
            currentLocationModel: _currentLocationModel,
            destination: _destination,
            route: _route,
            showLocationDetails: _showLocationDetails,
            onClearDestination: _clearDestination,
            onToggleDetails: _toggleLocationDetails,
          ),

          // Detailed Location Cards with Tab View
          if (_showLocationDetails)
            LocationDetailsTabWidget(
              tabController: _tabController,
              currentLocationModel: _currentLocationModel,
              destination: _destination,
              route: _route,
            ),
        ],
      ),
    );
  }
}