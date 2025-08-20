class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });
}