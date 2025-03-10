import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

class RouteParserService {
  static Future<List<LatLng>> parseGpxOrKml(String filePath) async {
    try {
      String content = await File(filePath).readAsString();
      if (filePath.endsWith('.gpx')) {
        return _parseGpx(content);
      } else if (filePath.endsWith('.kml')) {
        return _parseKml(content);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing file: $e");
      }
    }
    return [];
  }

  static List<LatLng> _parseGpx(String gpxContent) {
    final document = XmlDocument.parse(gpxContent);
    final points = <LatLng>[];

    for (var trkpt in document.findAllElements('trkpt')) {
      double lat = double.parse(trkpt.getAttribute('lat') ?? '0');
      double lon = double.parse(trkpt.getAttribute('lon') ?? '0');
      points.add(LatLng(lat, lon));
    }

    return points;
  }

  static List<LatLng> _parseKml(String kmlContent) {
    final document = XmlDocument.parse(kmlContent);
    final points = <LatLng>[];

    for (var coord in document.findAllElements('coordinates')) {
      var coords = coord.text.trim().split(" ");
      for (var point in coords) {
        var latLon = point.split(",");
        if (latLon.length >= 2) {
          double lon = double.parse(latLon[0]);
          double lat = double.parse(latLon[1]);
          points.add(LatLng(lat, lon));
        }
      }
    }

    return points;
  }
}
