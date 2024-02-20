import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show sin, cos, sqrt, atan2;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  double calCul = 0.0;
  LatLng userLatLng = LatLng(0.0, 0.0);
  GoogleMapController? mapController;

  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};

  static const String _keyData = 'myData';
  static const String _keyExpiration = 'expirationTime';

@override
  void initState() {
    super.initState();
    fetchCoordinates();
  }
  Future<bool> saveDataWithExpiration(String data, Duration expirationDuration) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DateTime expirationTime = DateTime.now().add(expirationDuration);
      await prefs.setString(_keyData, data);
      await prefs.setString(_keyExpiration, expirationTime.toIso8601String());
      print('Data saved to SharedPreferences.');
      return true;
    } catch (e) {
      print('Error saving data to SharedPreferences: $e');
      return false;
    }
  }
  Future<void> fetchCoordinates() async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${widget.userInput}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final double userLat = double.parse(data[0]['lat']);
          final double userLng = double.parse(data[0]['lon']);
            userLatLng = LatLng(userLat, userLng);
            calCul = distanceVolBird(widget.latitude, widget.longitude, userLat, userLng);
            await _createPolylines(widget.latitude, widget.longitude, userLat, userLng);
          saveDataWithExpiration(widget.userInput, const Duration(hours: 2, minutes: 3, seconds: 2));
            setState(() {
          });
        }
      } else {
        print('Failed to fetch coordinates');
      }
    } catch (error) {
      print('Error fetching coordinates: $error');
    }
  }
  Future<void> _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "",
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.transit,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }


  double distanceVolBird(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0;
    final double deltaLon = lon2 - lon1;
    final double deltaLat = lat2 - lat1;
    lat1 = _degreesToRadians(lat1);
    lon1 = _degreesToRadians(lon1);
    lat2 = _degreesToRadians(lat2);
    lon2 = _degreesToRadians(lon2);
    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;
    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Location'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
            'distance: $calCul',
            style: const TextStyle(fontSize: 18),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 9.2,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('start'),
                  position: LatLng(widget.latitude, widget.longitude),
                  icon: BitmapDescriptor.defaultMarker,
                ),
                Marker(
                  markerId: MarkerId('destination'),
                  position: userLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
          ),
        ],
      ),
    );
  }
}
