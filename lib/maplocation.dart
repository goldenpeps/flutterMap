import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show sin, cos, sqrt, atan2;

class MapLocation extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String userInput;

  MapLocation({
    required this.latitude,
    required this.longitude,
    required this.userInput,
  });

  @override
  _MapLocationState createState() => _MapLocationState();
}

class _MapLocationState extends State<MapLocation> {
  String userCoordinates = '';
  double calcul = 0.0;
  double userLatex = 0.0;
  double userLngex = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCoordinates();
  }
  Future<void> fetchCoordinates() async {
    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${widget.userInput}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final double userLat = double.parse(data[0]['lat']);
        final double userLng = double.parse(data[0]['lon']);
        setState(() {
          userCoordinates = 'User Coordinates: $userLat, $userLng';
          userLatex = userLat;
          userLngex = userLng;
          calcul = distanceVolOiseau(widget.latitude, widget.longitude, userLat, userLng);
        });
      } else {
        setState(() {
          userCoordinates = 'No coordinates found for ${widget.userInput}';
        });
      }
    } else {
      print('Failed to fetch coordinates');
    }

  }
  double distanceVolOiseau(double lat1, double lon1, double lat2, double lon2) {
    double rayonTerre = 6371.0; // Rayon moyen de la Terre en kilomètres
    double deltaLon = lon2 - lon1;
    double deltaLat = lat2 - lat1;
    lat1 = _degreesToRadians(lat1);
    lon1 = _degreesToRadians(lon1);
    lat2 = _degreesToRadians(lat2);
    lon2 = _degreesToRadians(lon2);
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = rayonTerre * c;
    return distance;
  }
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Location'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text(
            'latitude: ${widget.latitude}',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'longitude: ${widget.longitude}',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'User Input: ${widget.userInput}',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'distance: $calcul', // Display user coordinates here
            style: TextStyle(fontSize: 18),
          ),
          Text(
            userCoordinates, // Display user coordinates here
            style: TextStyle(fontSize: 18),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(widget.latitude, widget.longitude),
                zoom: 9.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [LatLng(widget.latitude, widget.longitude), LatLng(userLatex, userLngex), ],
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: LatLng(widget.latitude, widget.longitude),
                      child: FlutterLogo(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}