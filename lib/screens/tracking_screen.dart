import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart';

import '../models/route_model.dart';
import '../providers/route_provider.dart';


class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  TrackingScreenState createState() => TrackingScreenState();
}

class TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  bool _tracking = false;
  bool _paused = false;
  double _distance = 0.0;
  int _seconds = 0;
  double _averageSpeed = 0.0;
  Position? _previousPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  final List<LatLng> _routePoints = [];
  final List<LatLng> _loadedRoutePoints = [];
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else if (status.isDenied) {
      _showPermissionDialog();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Location Permission Required"),
          content: Text("This app needs location access to track your route."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: Text("Settings"),
            ),
          ],
        );
      },
    );
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_userLocation!, 15.0);
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error: Can't find location: $e");
      }
    }
  }

   void _updateDistance(Position position) {
    if (_previousPosition != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _distance += distanceInMeters;

          _averageSpeed = _seconds > 0 ? (_distance / 1000) / (_seconds / 3600) : 0.0;

          _routePoints.add(LatLng(position.latitude, position.longitude));

          _userLocation = LatLng(position.latitude, position.longitude);

          _mapController.move(_userLocation!, _mapController.camera.zoom);

        });
      }
    }
    _previousPosition = position;
  }

  void _startTracking() {
    if (_tracking) return;

    if (mounted) {
      setState(() {
        _tracking = true;
        _paused = false;
        _seconds = 0;
        _distance = 0.0;
        _averageSpeed = 0.0;
        _routePoints.clear();
      });
    }

    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (!_paused && mounted) {
        setState(() {
          _seconds++;
        });
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (!_paused) {
        _updateDistance(position);
      }
    });
  }
  void _pauseTracking() {
    if (mounted) {
      setState(() {
        _paused = true;
        _positionStream?.pause();
        _timer?.cancel();
      });
    }
  }

  void _resumeTracking() {
    if (mounted) {
      setState(() {
        _paused = false;
      });
    }

    _positionStream?.resume();

    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopTracking() {
    if (!_tracking) return;

    setState(() {
      _tracking = false;
      _paused = false;
      _previousPosition = null;
    });

    _timer?.cancel();
    _timer = null;

    _positionStream?.cancel();
    _positionStream = null;

    if (_routePoints.isNotEmpty) {
      _showSaveDialog();
    }
  }

  void _centerMap() {
    setState(() {
    });

    if (_userLocation != null) {
      _mapController.move(_userLocation!, _mapController.camera.zoom);
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Save Route?"),
          content: Text("Do you want to save this route?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _saveRoute();
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _saveRoute() {
    final route = RouteModel(
      points: List.from(_routePoints),
      distance: _distance,
      duration: _seconds,
      date: DateTime.now(),
      averageSpeed: _averageSpeed,
    );

    Provider.of<RouteProvider>(context, listen: false).addRoute(route);

    if (mounted) {
      setState(() {
        _routePoints.clear();
        _distance = 0.0;
        _seconds = 0;
        _averageSpeed = 0.0;
      });
    }
  }

  List<LatLng> _parseGpxOrKml(String filePath) {
    final file = File(filePath);
    final document = XmlDocument.parse(file.readAsStringSync());

    List<LatLng> loadedRoutePoints = [];

    for (var trkpt in document.findAllElements('trkpt')) {
      final lat = double.parse(trkpt.getAttribute('lat')!);
      final lon = double.parse(trkpt.getAttribute('lon')!);
      loadedRoutePoints.add(LatLng(lat, lon));
    }

    return loadedRoutePoints;
  }


  Future<void> _loadRoute() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;

        if (!mounted) return;

        List<LatLng> newRoute = _parseGpxOrKml(filePath);

        if (newRoute.isNotEmpty) {
          double avgLat = newRoute.map((p) => p.latitude).reduce((a, b) => a + b) / newRoute.length;
          double avgLon = newRoute.map((p) => p.longitude).reduce((a, b) => a + b) / newRoute.length;
          LatLng center = LatLng(avgLat, avgLon);

          setState(() {
            _loadedRoutePoints.clear();
            _loadedRoutePoints.addAll(newRoute);
          });

          _mapController.move(center, 15.0);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reitti ladattu onnistuneesti!")),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Virhe ladattaessa reittiä: $e");
      }
    }
  }


  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Distance Tracker"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _userLocation ?? LatLng(60.1699, 24.9384),
                    initialZoom: 15,
                    onMapEvent: (event) {
                      if (event is MapEventMove) {
                        setState(() {
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                        if (_loadedRoutePoints.isNotEmpty)
                          Polyline(
                            points: _loadedRoutePoints,
                            strokeWidth: 4.0,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 30,
                            ),
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
                        onPressed: _loadRoute,
                        child: Icon(Icons.upload_file),
                      ),
                      SizedBox(height: 10),
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
                        onPressed: _centerMap,
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
                _buildInfoBox("Distance", "${(_distance / 1000).toStringAsFixed(2)} km"),
                SizedBox(width: 5),
                _buildInfoBox("Time", _formatTime(_seconds)),
                SizedBox(width: 5),
                _buildInfoBox("Avg Speed", "${_averageSpeed.toStringAsFixed(2)} km/h", Colors.blue),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _tracking
                ? [
              _paused
                  ? _buildGreenButton("Start", _resumeTracking)
                  : _buildGreenButton("Pause", _pauseTracking),
              SizedBox(width: 20),
              _buildGreenButton("Stop", _stopTracking),
            ]
                : (_distance > 0
                ? [
              _buildGreenButton("Restart", _startTracking),
              SizedBox(width: 20),
              _buildGreenButton("Save", _saveRoute),
            ]
                : [
              _buildGreenButton("Start", _startTracking),
            ]),
          ),
          SizedBox(height: 20),
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
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildGreenButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

}
