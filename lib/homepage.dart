import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:projetfinal/maplocation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String locationText = 'Obtenir la localisation...';
  final TextEditingController _textInputController = TextEditingController();
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
      String? data = prefs.getString(AppConstants.keyData);
      String? expirationTimeStr = prefs.getString(AppConstants.keyExpiration);
      if (data == null || expirationTimeStr == null) {
        setState(() {});
        return; // No data or expiration time found.
      }
      DateTime expirationTime = DateTime.parse(expirationTimeStr);
      if (expirationTime.isAfter(DateTime.now())) {
        setState(() {
          message = 'last research : $data';
        });
      } else {
        // Data has expired. Remove it from SharedPreferences.
        await prefs.remove(AppConstants.keyData);
        await prefs.remove(AppConstants.keyExpiration);
        setState(() {
          message = 'Data has expired. Removed from SharedPreferences.';
        });
      }
    } catch (error) {
      setState(() {
        message = 'Error retrieving data from SharedPreferences: $error';
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
    } catch (error) {
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
    ).then((value) {
      // Mettre à jour les données avec la valeur renvoyée depuis MapLocation
      if (value != null) {
        setState(() {
          message = 'last research : $value';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(

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
              decoration: const  InputDecoration(
                hintText: 'Entrez quelque chose...',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _navigateToMapLocation,
            child: const Text('Valider'),
          ),
          Text(
            message,
            style:const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
