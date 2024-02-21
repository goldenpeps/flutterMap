import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show acos, cos, sin;
import 'package:shared_preferences/shared_preferences.dart';

//données de recherche
class AppConstants {
  static const String keyData = 'myData';
  static const String keyExpiration = 'expirationTime';
}

class MapLocation extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String userInput;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.userInput,
  });

  @override
  _MapLocationState createState() => _MapLocationState();
}

class _MapLocationState extends State<MapLocation> {
  String userCoordinates = '';
  double calc = 0.0;
  double userLatex = 0.0;
  double userLngex = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCoordinates();
  }

  //sauvegarde des données + durée de vie
  Future<bool> saveDataWithExpiration(String data, Duration expirationDuration) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DateTime expirationTime = DateTime.now().add(expirationDuration);
      await prefs.setString(AppConstants.keyData, data);
      await prefs.setString(AppConstants.keyExpiration, expirationTime.toIso8601String());
      return true;
    } catch (error) {
      return false;
    }
  }

  //recherche coordonnées
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
          calc = distanceVolBird(widget.latitude, widget.longitude, userLat, userLng);
          saveDataWithExpiration(widget.userInput, const Duration(hours: 2, minutes: 3, seconds: 2));
        });
      } else {
        setState(() {
          userCoordinates = 'No coordinates found for ${widget.userInput}';
        });
      }
    } else {
      // Handle error
    }
  }

  //calcul distance
  double distanceVolBird(double lat1, double lon1, double lat2, double lon2) {
    const rayonTerre = 6371.0;
    final l1 = _degreesToRadians(lat1);
    final l2 = _degreesToRadians(lat2);
    final deltaLon = _degreesToRadians(lon2 - lon1);

    final distance = acos(sin(l1) * sin(l2) + cos(l1) * cos(l2) * cos(deltaLon)) * rayonTerre;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Empêcher la fermeture automatique en appuyant sur la flèche de retour
        Navigator.of(context).pop(widget.userInput);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Map Location'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'latitude: ${widget.latitude}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'longitude: ${widget.longitude}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'User Input: ${widget.userInput}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'distance: $calc km', // Display user coordinates here
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              userCoordinates, // Display user coordinates here
              style: const TextStyle(fontSize: 18),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(widget.latitude, widget.longitude),
                  initialZoom: 9.2,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(widget.latitude, widget.longitude),
                          LatLng(userLatex, userLngex),
                        ],
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
                        child: const FlutterLogo(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
