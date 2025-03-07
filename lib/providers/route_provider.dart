import 'package:flutter/material.dart';
import 'package:tracker/models/route_model.dart';

class RouteProvider with ChangeNotifier {
  final List<RouteModel> _routes = [];

  List<RouteModel> get routes => _routes;

  void addRoute(RouteModel route) {
    _routes.add(route);
    notifyListeners();
  }
}
