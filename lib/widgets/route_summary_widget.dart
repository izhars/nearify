// widgets/route_summary_widget.dart
import 'package:flutter/material.dart';
import '../models/route_model.dart';

class RouteSummaryWidget extends StatelessWidget {
  final RouteModel route;

  const RouteSummaryWidget({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (route.duration != null)
            _buildRouteInfo(
              context,
              Icons.schedule_rounded,
              route.duration!,
              'Duration',
            ),
          if (route.distance != null)
            _buildRouteInfo(
              context,
              Icons.straighten_rounded,
              route.distance!,
              'Distance',
            ),
          _buildRouteInfo(
            context,
            Icons.list_rounded,
            '${route.steps.length}',
            'Steps',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}