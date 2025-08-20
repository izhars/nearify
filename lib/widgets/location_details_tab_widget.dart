// widgets/location_details_tab_widget.dart
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../widgets/location_card.dart';
import 'directions_list_widget.dart';

class LocationDetailsTabWidget extends StatelessWidget {
  final TabController tabController;
  final LocationModel? currentLocationModel;
  final LocationModel? destination;
  final RouteModel? route;

  const LocationDetailsTabWidget({
    super.key,
    required this.tabController,
    required this.currentLocationModel,
    required this.destination,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Tab Bar with better styling
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Locations'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Directions'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // Locations Tab
                _buildLocationsTab(),
                // Directions Tab
                DirectionsListWidget(route: route),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (currentLocationModel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LocationCard(
                location: currentLocationModel,
                title: 'Current Location',
                accentColor: Colors.green,
                customIcon: Icons.my_location_rounded,
                isCollapsible: true,
              ),
            ),
          if (destination != null)
            LocationCard(
              location: destination,
              title: 'Destination',
              accentColor: Colors.blue,
              customIcon: Icons.location_on_rounded,
              isCollapsible: true,
            ),
          if (currentLocationModel == null && destination == null)
            _buildEmptyLocationsState(),
        ],
      ),
    );
  }

  Widget _buildEmptyLocationsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_searching_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No locations available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a destination or tap on the map',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}