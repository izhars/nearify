// widgets/directions_list_widget.dart
import 'package:flutter/material.dart';
import '../models/route_model.dart';
import 'route_summary_widget.dart';

class DirectionsListWidget extends StatelessWidget {
  final RouteModel? route;

  const DirectionsListWidget({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    if (route == null || route!.steps.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Route summary header
        RouteSummaryWidget(route: route!),

        // Directions list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: route!.steps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final step = route!.steps[index];
              return _buildDirectionStep(context, step, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No directions available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a destination to get directions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionStep(BuildContext context, step, int index) {
    String instruction = step.instruction;
    String distance = step.distance != null
        ? "${(step.distance! / 1000).toStringAsFixed(1)} km"
        : '';
    String duration = step.duration != null
        ? "${(step.duration! / 60).round()} min"
        : '';

    // Clean up HTML tags from instruction if present
    instruction = instruction.replaceAll(RegExp(r'<[^>]*>'), '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          instruction,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            height: 1.3,
          ),
        ),
        subtitle: distance.isNotEmpty || duration.isNotEmpty
            ? Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              if (distance.isNotEmpty) ...[
                Icon(Icons.straighten_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  distance,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (distance.isNotEmpty && duration.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 12),
              ],
              if (duration.isNotEmpty) ...[
                Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}