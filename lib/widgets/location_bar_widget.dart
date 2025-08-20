// widgets/location_bar_widget.dart
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';

class LocationBarWidget extends StatelessWidget {
  final LocationModel? currentLocationModel;
  final LocationModel? destination;
  final RouteModel? route;
  final bool showLocationDetails;
  final VoidCallback onClearDestination;
  final VoidCallback onToggleDetails;

  const LocationBarWidget({
    super.key,
    required this.currentLocationModel,
    required this.destination,
    required this.route,
    required this.showLocationDetails,
    required this.onClearDestination,
    required this.onToggleDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (currentLocationModel == null && destination == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Current Location Row
                if (currentLocationModel != null)
                  _buildLocationRow(
                    context,
                    icon: Icons.my_location_rounded,
                    iconColor: Colors.green,
                    label: 'From',
                    locationName: currentLocationModel!.name ?? 'Current Location',
                    isDestination: false,
                  ),

                // Divider
                if (currentLocationModel != null && destination != null)
                  _buildDivider(context),

                // Destination Row
                if (destination != null)
                  _buildLocationRow(
                    context,
                    icon: Icons.location_on_rounded,
                    iconColor: Theme.of(context).primaryColor,
                    label: 'To',
                    locationName: destination!.name ?? destination!.address ?? 'Destination',
                    isDestination: true,
                  ),
              ],
            ),
          ),

          // Route Info Bar
          if (route != null) _buildRouteInfoBar(context),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String label,
        required String locationName,
        required bool isDestination,
      }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                locationName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isDestination)
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey[500]),
            onPressed: onClearDestination,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Clear destination',
          ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (route!.duration != null) ...[
            _buildRouteInfoItem(
              context,
              Icons.schedule_rounded,
              route!.duration!,
            ),
            const SizedBox(width: 16),
          ],
          if (route!.distance != null) ...[
            _buildRouteInfoItem(
              context,
              Icons.straighten_rounded,
              route!.distance!,
            ),
            const SizedBox(width: 16),
          ],
          const Spacer(),
          GestureDetector(
            onTap: onToggleDetails,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showLocationDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoItem(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}