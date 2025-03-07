import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/providers/route_provider.dart';
import 'package:intl/intl.dart';
import 'route_detail_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = Provider.of<RouteProvider>(context).routes;

    return Scaffold(
      appBar: AppBar(title: Text("Saved Routes")),
      body: routes.isEmpty
          ? Center(child: Text("No saved routes"))
          : ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return ListTile(
            title: Text("Route ${index + 1}"),
            subtitle: Text(
              "Distance: ${(route.distance / 1000).toStringAsFixed(2)} km\n"
                  "Avg Speed: ${route.averageSpeed.toStringAsFixed(2)} km/h\n"
                  "Time: ${route.duration} sec\n"
                  "Date: ${DateFormat('dd.MM.yyyy HH:mm').format(route.date)}\n"
                  "TAP FOR VIEW ON A MAP",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteDetailScreen(route: route),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
