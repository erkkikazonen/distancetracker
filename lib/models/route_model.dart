import 'package:latlong2/latlong.dart';

class RouteModel {
  final List<LatLng> points;
  final double distance;
  final int duration;
  final DateTime date;
  final double averageSpeed;

  RouteModel({
    required this.points,
    required this.distance,
    required this.duration,
    required this.date,
    required this.averageSpeed,
  });
}
