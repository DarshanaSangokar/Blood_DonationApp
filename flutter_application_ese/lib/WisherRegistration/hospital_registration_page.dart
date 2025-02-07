import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HospitalWisherRegistrationPage extends StatefulWidget {
  @override
  _HospitalWisherRegistrationPageState createState() =>
      _HospitalWisherRegistrationPageState();
}

class _HospitalWisherRegistrationPageState
    extends State<HospitalWisherRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController hospitalNameController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController registrationNumberController = TextEditingController();
  TextEditingController emailController =
      TextEditingController(); // Email Controller
  LatLng? selectedLocation;

  // Method to get the current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled. Please enable them.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          'Location permissions are permanently denied. Enable them in settings.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  // Select location using the map
  void _selectLocationOnMap() async {
    LatLng? chosenLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(),
      ),
    );

    if (chosenLocation != null) {
      setState(() {
        selectedLocation = chosenLocation;
      });
    }
  }

  // Display Snackbar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Save registration data
  void _registerHospital() async {
    if (_formKey.currentState!.validate()) {
      if (selectedLocation == null) {
        _showSnackBar('Please provide your location.');
        return;
      }

      final hospitalWisherData = {
        'name': hospitalNameController.text,
        'contact': contactNumberController.text,
        'address': addressController.text,
        'registrationNumber': registrationNumberController.text,
        'email': emailController.text, // Save email data
        'location':
            '${selectedLocation!.latitude},${selectedLocation!.longitude}',
      };

      // Save data to your database (e.g., Firebase Firestore)
      /*
      await FirebaseFirestore.instance.collection('hospitals').add(hospitalData);
      */

      // _showSnackBar('Hospital Registered Successfully');
      // _formKey.currentState!.reset();
      // hospitalNameController.clear();
      // contactNumberController.clear();
      // addressController.clear();
      // registrationNumberController.clear();
      // emailController.clear(); // Clear email field
      // setState(() {
      //   selectedLocation = null;
      // });
      try {
        // Save data to the Firestore collection for hospital wishers
        await FirebaseFirestore.instance
            .collection('hospital_wishers')
            .add(hospitalWisherData);

        _showSnackBar('Hospital Wisher Registered Successfully');
        _formKey.currentState!.reset();
        hospitalNameController.clear();
        contactNumberController.clear();
        addressController.clear();
        registrationNumberController.clear();
        emailController.clear(); // Clear email field
        setState(() {
          selectedLocation = null;
        });
      } catch (e) {
        _showSnackBar('Error registering hospital wisher: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital Wisher Registration',
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
        backgroundColor: Color.fromARGB(255, 82, 183, 255),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: hospitalNameController,
                decoration: InputDecoration(
                  labelText: 'Hospital Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hospital name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: contactNumberController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  } else if (value.length != 10) {
                    return 'Contact number must be 10 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: registrationNumberController,
                decoration: InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter registration number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: Icon(Icons.my_location),
                    label: Text('Use Live Location',
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255))),
                    style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 90, 198, 230)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectLocationOnMap,
                    icon: Icon(Icons.map),
                    label: Text('Pick on Map',
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255))),
                    style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 90, 198, 230)),
                  ),
                ],
              ),
              if (selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _registerHospital,
                  child: Text('Register',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                  style: ElevatedButton.styleFrom(
                    primary: Color.fromARGB(255, 33, 146, 103),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng selectedLocation =
      LatLng(20.5937, 78.9629); // Default location (India)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selectedLocation,
          zoom: 5.0,
        ),
        onTap: (location) {
          setState(() {
            selectedLocation = location;
          });
        },
        markers: {
          Marker(
            markerId: MarkerId('selected'),
            position: selectedLocation,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, selectedLocation); // Return selected location
        },
        child: Icon(Icons.check),
        backgroundColor: Colors.green,
      ),
    );
  }
}
