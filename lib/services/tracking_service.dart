import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../widgets/tracking_controls.dart';
import '../widgets/info_box.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    LatLng? location = await LocationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _userLocation = location;
        _mapController.move(_userLocation!, 15.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tracking")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(60.1699, 24.9384),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
            ],
          ),
          TrackingControls(), // Ohjauspainikkeet (Start, Stop, Pause)
          Positioned(
            bottom: 10,
            left: 10,
            child: InfoBox(), // Näyttää nopeuden, ajan jne.
          ),
        ],
      ),
    );
  }
}
