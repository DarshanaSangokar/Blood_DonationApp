import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_ese/algorithm/calculateHarversineFormula.dart';

class BloodRequestPage extends StatefulWidget {
  final String hospitalId;
  const BloodRequestPage(
      {required this.hospitalId, Key? key, required String userId})
      : super(key: key);

  @override
  State<BloodRequestPage> createState() => _BloodRequestPageState();
}

class _BloodRequestPageState extends State<BloodRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final unitsController = TextEditingController();
  String? selectedBloodType;
  double? hospitalLat;
  double? hospitalLon;

  List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _fetchHospitalLocation();
  }

  Future<void> _fetchHospitalLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        hospitalLat = position.latitude;
        hospitalLon = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch hospital location.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchNearbyDonors(
      double hospitalLat, double hospitalLon, String bloodType) async {
    List<Map<String, dynamic>> donors = [];
    try {
      final donorSnapshot =
          await FirebaseFirestore.instance.collection('donors').get();

      for (var doc in donorSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('location') && data['bloodType'] == bloodType) {
          final location = data['location'].split(',');
          final donorLat = double.parse(location[0]);
          final donorLon = double.parse(location[1]);

          final distance = calculateHaversineDistance(
              hospitalLat, hospitalLon, donorLat, donorLon);

          donors.add({
            'id': doc.id,
            'name': data['name'],
            'location': data['location'],
            'distance': distance,
          });
        }
      }

      donors.sort((a, b) => a['distance'].compareTo(b['distance']));
      return donors.take(5).toList();
    } catch (e) {
      print('Error fetching donors: $e');
      return [];
    }
  }

  Future<void> _createBloodRequest() async {
    if (_formKey.currentState!.validate()) {
      if (hospitalLat == null || hospitalLon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to fetch hospital location.')),
        );
        return;
      }

      final units = int.parse(unitsController.text);
      final bloodType = selectedBloodType!;
      final donors =
          await fetchNearbyDonors(hospitalLat!, hospitalLon!, bloodType);

      if (donors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No donors found nearby.')),
        );
        return;
      }

      try {
        final hospitalSnapshot = await FirebaseFirestore.instance
            .collection('hospitals')
            .doc(widget.hospitalId)
            .get();
        final hospitalData = hospitalSnapshot.data();

        await FirebaseFirestore.instance.collection('blood_requests').add({
          'hospitalId': widget.hospitalId,
          'hospitalName': hospitalData?['name'],
          'hospitalLocation': '$hospitalLat,$hospitalLon',
          'bloodType': bloodType,
          'units': units,
          'timestamp': FieldValue.serverTimestamp(),
          'donorsNotified': donors.map((d) => d['id']).toList(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blood request sent to top 5 donors.')),
        );
      } catch (e) {
        print('Error creating blood request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send blood request.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Request',
            style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Blood Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedBloodType,
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  border: OutlineInputBorder(),
                ),
                items: bloodTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a blood type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: unitsController,
                decoration: InputDecoration(
                  labelText: 'Units (ml)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createBloodRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text('Send Request',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 237, 243, 238))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
