import 'package:flutter/material.dart';

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
            'User Input: ${widget.userInput}',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
