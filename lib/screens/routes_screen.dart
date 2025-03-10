import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/providers/route_provider.dart';
import 'package:intl/intl.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);
    final routes = routeProvider.routes;

    return Scaffold(
      appBar: AppBar(title: Text("Saved Routes"), centerTitle: true),
      body: routes.isEmpty
          ? Center(child: Text("No saved routes"))
          : ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 6, spreadRadius: 2),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        "Date: ${DateFormat('dd.MM.yyyy HH:mm').format(route.date)}",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoBox("Distance", "${(route.distance / 1000).toStringAsFixed(2)} km"),
                        _buildInfoBox("Time", _formatTime(route.duration)),
                        _buildInfoBox("Avg Speed", "${route.averageSpeed.toStringAsFixed(2)} km/h"),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.map, color: Colors.green, size: 30),
                        label: Text('Route', style: TextStyle(fontSize: 16, color: Colors.green)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RouteDetailScreen(route: route),
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.delete, color: Colors.red, size: 30),
                        label: Text('Delete', style: TextStyle(fontSize: 16, color: Colors.red)),
                        onPressed: () => _confirmDelete(context, routeProvider, route),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      width: 100,
      height: 80,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, RouteProvider routeProvider, route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Route?"),
        content: Text("Are you sure you want to delete this route?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              routeProvider.removeRoute(route);
              Navigator.of(context).pop();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
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
