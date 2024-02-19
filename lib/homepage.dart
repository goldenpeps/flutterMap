import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'MapLocation.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String locationText = 'Obtenir la localisation...';
  TextEditingController _textInputController = TextEditingController();

  final List<String> carouselImages = [
    'assets/images/image1.png',
    'assets/images/image2.png',
    'assets/images/image1.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
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
        ],
      ),
    );
  }
}
