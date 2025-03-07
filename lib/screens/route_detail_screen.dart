import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  _RouteDetailScreenState createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  int _selectedIndex = 1; // 1 = Routes, 0 = Tracker

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Route Details")),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.route.points.isNotEmpty
                        ? widget.route.points.first
                        : LatLng(60.1699, 24.9384),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.route.points,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (widget.route.points.isNotEmpty)
                          Marker(
                            point: widget.route.points.first,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_pin, color: Colors.green, size: 40),
                          ),
                        if (widget.route.points.isNotEmpty)
                          Marker(
                            point: widget.route.points.last,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.flag, color: Colors.red, size: 40),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                        child: Icon(Icons.add),
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                        child: Icon(Icons.remove),
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        onPressed: () => _mapController.move(widget.route.points.first, 15),
                        child: Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoBox("Distance", "${(widget.route.distance / 1000).toStringAsFixed(2)} km"),
                SizedBox(width: 5),
                _buildInfoBox("Time", _formatTime(widget.route.duration)),
                SizedBox(width: 5),
                _buildInfoBox("Avg Speed", "${widget.route.averageSpeed.toStringAsFixed(2)} km/h", Colors.blue),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Navigator.pop(context);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Routes',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, [Color textColor = Colors.black]) {
    return Container(
      width: 120,
      height: 80,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
