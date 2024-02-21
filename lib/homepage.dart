import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:projetfinal/key.dart';
import 'MapLocation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String locationText = 'obtenir la localisation...';
  final TextEditingController _textInputController = TextEditingController();
  static const String _keyData = 'myData';
  static const String _keyExpiration = 'expirationTime';
  String message = "";

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
        return;
      }
      DateTime expirationTime = DateTime.parse(expirationTimeStr);
      if (expirationTime.isAfter(DateTime.now())) {
        setState(() {
          message = 'last localisation : $data';
        });
      } else {
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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image
            Image.asset(
              'assets/images/logo.png',  // Remplacez 'assets/votre_image.png' par le chemin de votre image
              width: 300,  // ajustez la largeur selon vos besoins
              height: 300, // ajustez la hauteur selon vos besoins
            ),
            const SizedBox(height: 16),
            // Row with AutoCompleteTextField and Button
            Row(
              children: [
                Expanded(
                  child: placesAutoCompleteTextField(),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _navigateToMapLocation();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Valider'),
                ),
              ],
            ),
            const SizedBox(height: 16),
           Text(
            message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),),
          ],
        ),
      ),
    );
  }


  Widget placesAutoCompleteTextField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _textInputController,
        googleAPIKey: cleApi,
        inputDecoration: const InputDecoration(
          hintText: "Search your location",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        debounceTime: 400,
        countries: ["usa", "fr"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          print("placeDetails" + prediction.lat.toString());
        },
        itemClick: (Prediction prediction) {
          _textInputController.text = prediction.description ?? "";
          _textInputController.selection = TextSelection.fromPosition(
              TextPosition(offset: prediction.description?.length ?? 0));
        },
        seperatedBuilder: const Divider(),
        containerHorizontalPadding: 10,
        itemBuilder: (context, index, Prediction prediction) {
          return Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(
                  width: 7,
                ),
                Expanded(child: Text("${prediction.description ?? ""}"))
              ],
            ),
          );
        },
        isCrossBtnShown: true,
      ),
    );
  }
}
