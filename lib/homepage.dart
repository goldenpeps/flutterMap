import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'MapLocation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String locationText = 'Obtenir la localisation...';
  TextEditingController _textInputController = TextEditingController();
  static const String _keyData = 'myData';
  static const String _keyExpiration = 'expirationTime';
  String message = "";

  final List<String> carouselImages = [
    'assets/images/image1.png',
    'assets/images/image2.png',
    'assets/images/image1.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
    _getDataIfNotExpired();
  }
  Future<void> _getDataIfNotExpired() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(_keyData);
      String? expirationTimeStr = prefs.getString(_keyExpiration);
      if (data == null || expirationTimeStr == null) {
        setState(() {
          message = 'No data or expiration time found in SharedPreferences.';
        });
        return; // No data or expiration time found.
      }
      DateTime expirationTime = DateTime.parse(expirationTimeStr);
      if (expirationTime.isAfter(DateTime.now())) {
        setState(() {
          message = 'last localisation : $data';
        });
      } else {
        // Data has expired. Remove it from SharedPreferences.
        await prefs.remove(_keyData);
        await prefs.remove(_keyExpiration);
        setState(() {
          message = 'Data has expired. Removed from SharedPreferences.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error retrieving data from SharedPreferences: $e';
      });
    }
  }
  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        locationText =
        'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
      });
    } catch (e) {
      print(e.toString());
      setState(() {
        locationText = 'Impossible d\'obtenir la localisation.';
      });
    }
  }

  void _navigateToMapLocation() {
    String userInput = _textInputController.text;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocation(
          latitude: locationText.isNotEmpty
              ? double.parse(locationText.split(",")[0].split(":")[1].trim())
              : 0.0,
          longitude: locationText.isNotEmpty
              ? double.parse(locationText.split(",")[1].split(":")[1].trim())
              : 0.0,
          userInput: userInput,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              enableInfiniteScroll: true,
              autoPlay: true,
            ),
            items: carouselImages.map((item) => Image.asset(item)).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textInputController,
              decoration: const InputDecoration(
                hintText: 'Entrez quelque chose...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Check if the input is not empty
              if (_textInputController.text.isNotEmpty) {
                // If input is valid, navigate to map location
                _navigateToMapLocation();
              } else {
                // If input is not valid, you can show an error message or take other actions
                // For now, let's just print an error message
                print('Veuillez entrer quelque chose avant de valider.');
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              padding: EdgeInsets.all(16),
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Valider'),
          ),
          const Column(
            children: <Widget>[
              SizedBox(height: 100),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Container(margin: const EdgeInsets.all(15.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent)
              ),
              child: Text(
                message,
                style:TextStyle(fontSize: 18),
              ),)],
          ),
        ],
      ),
    );
  }
}
