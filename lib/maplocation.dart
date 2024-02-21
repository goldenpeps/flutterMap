import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'key.dart';

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
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.userInput,
  }) : super(key: key);

  @override
  _MapLocationState createState() => _MapLocationState();
}

class _MapLocationState extends State<MapLocation> {
  //coordonnées et calculdistance
  double calCul = 0.0;
  LatLng userLatLng = const LatLng(0.0, 0.0);

  //variable controlleur pour tracer la ligne sur la map
  GoogleMapController? mapController;
  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  
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
    //appelle les coordonnées carte pour lafficher (API)
    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${widget.userInput}'),
    );
    //reponse de l'api valide
    if (response.statusCode == 200) {
      //decode valeur
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        //recuperation des localisation des données et parametrage des valeurs globals
        final double userLat = double.parse(data[0]['lat']);
        final double userLng = double.parse(data[0]['lon']);

        //set position du marker destination sur la carte
        userLatLng = LatLng(userLat, userLng);

        //direction vers la creation du chemin
        await _createPolylines(widget.latitude, widget.longitude, userLat, userLng);

        //sauvegarde des données
        await saveDataWithExpiration(widget.userInput, const Duration(hours: 2, minutes: 3, seconds: 2));
        //affichage sur la map
        setState(() {});
      }
    } else {
      if (kDebugMode) {
        print('error');
      }
    }
  }

  //fonction cretations de la lignes
  Future<void> _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      cleApi,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      calCul += distanceVolBird(polylineCoordinates[i].latitude, polylineCoordinates[i].longitude, polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(polylineId: id, color: Colors.deepPurple, points: polylineCoordinates, width: 3);
    polylines[id] = polyline;
  }

  double distanceVolBird(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination: ${widget.userInput}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Distance: ${calCul.toStringAsFixed(2)} km',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      markerId: const MarkerId('start'),
                      position: LatLng(widget.latitude, widget.longitude),
                      icon: BitmapDescriptor.defaultMarker,
                    ),
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: userLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    ),
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
