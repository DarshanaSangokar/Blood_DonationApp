import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Default to center of India
    zoom: 4.0,
  );

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _selectLocation(LatLng position) {
    setState(() {
      selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pick a Location"),
        backgroundColor: Colors.redAccent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            onMapCreated: _onMapCreated,
            onTap: _selectLocation,
            markers: selectedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: MarkerId('selectedLocation'),
                      position: selectedLocation!,
                    ),
                  },
          ),
          if (selectedLocation != null)
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(8),
                child: Text(
                  'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          Positioned(
            bottom: 50,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                if (selectedLocation != null) {
                  Navigator.pop(context, selectedLocation);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a location')),
                  );
                }
              },
              child: Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
