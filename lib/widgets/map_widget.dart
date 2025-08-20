import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';

class MapWidget extends StatefulWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final LocationModel? destination;
  final RouteModel? route;
  final VoidCallback onMapReady;
  final Function(LatLng)? onMapTap;
  final Function(LatLng)? onMapLongPress;
  final List<LocationModel>? additionalMarkers;
  final bool showUserLocationButton;
  final bool showZoomControls;
  final bool showTrafficLayer;
  final String? customTileUrl;
  final MapTheme theme;

  const MapWidget({
    super.key,
    required this.mapController,
    this.currentLocation,
    this.destination,
    this.route,
    required this.onMapReady,
    this.onMapTap,
    this.onMapLongPress,
    this.additionalMarkers,
    this.showUserLocationButton = true,
    this.showZoomControls = true,
    this.showTrafficLayer = false,
    this.customTileUrl,
    this.theme = MapTheme.light,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _tileUrl {
    if (widget.customTileUrl != null) return widget.customTileUrl!;

    switch (widget.theme) {
      case MapTheme.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapTheme.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTheme.terrain:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get _subdomains {
    switch (widget.theme) {
      case MapTheme.dark:
        return ['a', 'b', 'c', 'd'];
      case MapTheme.terrain:
        return ['a', 'b', 'c'];
      default:
        return ['a', 'b', 'c'];
    }
  }

  void _centerOnUserLocation() {
    if (widget.currentLocation != null) {
      widget.mapController.move(widget.currentLocation!, 16.0);
    }
  }

  void _fitBounds() {
    if (widget.currentLocation != null && widget.destination != null) {
      final points = <LatLng>[
        widget.currentLocation!,
        LatLng(widget.destination!.latitude, widget.destination!.longitude),
      ];

      if (widget.additionalMarkers != null) {
        for (final marker in widget.additionalMarkers!) {
          points.add(LatLng(marker.latitude, marker.longitude));
        }
      }

      final bounds = LatLngBounds.fromPoints(points);

      widget.mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ));
    }
  }

  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2 * _pulseAnimation.value),
            shape: BoxShape.circle,
          ),
          child: Container(
            margin: const EdgeInsets.all(15),
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
              Icons.my_location,
              color: Colors.blue,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDestinationMarker() {
    return Container(
      width: 80,
      height: 80,
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
        Icons.location_pin,
        color: Colors.red,
        size: 40,
      ),
    );
  }

  Widget _buildAdditionalMarker(LocationModel location, int index) {
    final colors = [Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final color = colors[index % colors.length];

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.place,
        color: color,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: widget.theme == MapTheme.dark ? Colors.grey[900] : Colors.grey[200],
          child: FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: widget.currentLocation ?? const LatLng(0, 0),
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 20,
              onMapReady: () {
                setState(() => _isLoading = false);
                widget.onMapReady();
              },
              onTap: widget.onMapTap != null
                  ? (tapPosition, point) => widget.onMapTap!(point)
                  : null,
              onLongPress: widget.onMapLongPress != null
                  ? (tapPosition, point) => widget.onMapLongPress!(point)
                  : null,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                enableMultiFingerGestureRace: true,
                pinchZoomWinGestures: MultiFingerGesture.all,
                pinchMoveWinGestures: MultiFingerGesture.all,
                scrollWheelVelocity: 0.005,
                rotationWinGestures: MultiFingerGesture.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: _subdomains,
                userAgentPackageName: 'com.example.olamaps',
                maxZoom: 20,
                tileSize: 256,
                keepBuffer: 8,
                panBuffer: 3,
                tileProvider: NetworkTileProvider(),
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('Tile loading error: $error');
                },
                tileBuilder: (context, widget, tile) {
                  return ColorFiltered(
                    colorFilter: this.widget.theme == MapTheme.dark
                        ? ColorFilter.mode(
                      Colors.grey.withOpacity(0.2),
                      BlendMode.overlay,
                    )
                        : const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    ),
                    child: widget,
                  );
                },
              ),

              // Route polyline
              if (widget.route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.route!.polylinePoints,
                      strokeWidth: 6.0,
                      color: Colors.blue,
                      gradientColors: [
                        Colors.blue,
                        Colors.blue.withOpacity(0.8),
                        Colors.lightBlue,
                      ],
                    ),
                  ],
                ),

              // Markers layer
              MarkerLayer(
                markers: [
                  // Current location marker
                  if (widget.currentLocation != null)
                    Marker(
                      point: widget.currentLocation!,
                      width: 80,
                      height: 80,
                      child: _buildCurrentLocationMarker(),
                    ),

                  // Destination marker
                  if (widget.destination != null)
                    Marker(
                      point: LatLng(widget.destination!.latitude, widget.destination!.longitude),
                      width: 80,
                      height: 80,
                      child: _buildDestinationMarker(),
                    ),

                  // Additional markers
                  if (widget.additionalMarkers != null)
                    ...widget.additionalMarkers!.asMap().entries.map(
                          (entry) => Marker(
                        point: LatLng(entry.value.latitude, entry.value.longitude),
                        width: 60,
                        height: 60,
                        child: _buildAdditionalMarker(entry.value, entry.key),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Control buttons
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              if (widget.showUserLocationButton && widget.currentLocation != null)
                FloatingActionButton(
                  mini: true,
                  onPressed: _centerOnUserLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),

              const SizedBox(height: 8),

              FloatingActionButton(
                mini: true,
                onPressed: _fitBounds,
                backgroundColor: Colors.white,
                child: const Icon(Icons.fit_screen, color: Colors.grey),
              ),

              if (widget.showZoomControls) ...[
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    final zoom = widget.mapController.camera.zoom;
                    widget.mapController.move(
                      widget.mapController.camera.center,
                      zoom + 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.grey),
                ),

                const SizedBox(height: 4),

                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    final zoom = widget.mapController.camera.zoom;
                    widget.mapController.move(
                      widget.mapController.camera.center,
                      zoom - 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),

        // Map info overlay
        // if (widget.route != null)
        //   Positioned(
        //     bottom: 16,
        //     left: 16,
        //     right: 16,
        //     child: Container(
        //       padding: const EdgeInsets.all(12),
        //       decoration: BoxDecoration(
        //         color: Colors.white,
        //         borderRadius: BorderRadius.circular(8),
        //         boxShadow: [
        //           BoxShadow(
        //             color: Colors.black.withOpacity(0.2),
        //             blurRadius: 8,
        //             offset: const Offset(0, 2),
        //           ),
        //         ],
        //       ),
        //       child: Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceAround,
        //         children: [
        //           Column(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               const Icon(Icons.access_time, color: Colors.grey, size: 20),
        //               const SizedBox(height: 4),
        //               Text(
        //                 widget.route!.duration ?? 'N/A',
        //                 style: const TextStyle(fontWeight: FontWeight.bold),
        //               ),
        //             ],
        //           ),
        //           Column(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               const Icon(Icons.straighten, color: Colors.grey, size: 20),
        //               const SizedBox(height: 4),
        //               Text(
        //                 widget.route!.distance ?? 'N/A',
        //                 style: const TextStyle(fontWeight: FontWeight.bold),
        //               ),
        //             ],
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}

enum MapTheme {
  light,
  dark,
  satellite,
  terrain,
}