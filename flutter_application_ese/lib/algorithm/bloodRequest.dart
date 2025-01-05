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



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class BloodRequestPage extends StatefulWidget {
//   final String userId; // Pass the current hospital's user ID

//   BloodRequestPage({required this.userId});

//   @override
//   _BloodRequestPageState createState() => _BloodRequestPageState();
// }

// class _BloodRequestPageState extends State<BloodRequestPage> {
//   final _formKey = GlobalKey<FormState>();
//   String? _selectedBloodType;
//   String? _selectedUrgency;
//   String? _additionalNotes;

//   // Blood types
//   final List<String> _bloodTypes = [
//     'A+',
//     'A-',
//     'B+',
//     'B-',
//     'AB+',
//     'AB-',
//     'O+',
//     'O-'
//   ];

//   // Urgency levels
//   final List<String> _urgencyLevels = ['Low', 'Medium', 'High'];

//   Future<void> _submitRequest() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();

//       try {
//         // Save the blood request to Firestore
//         await FirebaseFirestore.instance.collection('blood_requests').add({
//           'hospitalId': widget.userId,
//           'bloodType': _selectedBloodType,
//           'urgency': _selectedUrgency,
//           'notes': _additionalNotes ?? '',
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Blood request submitted successfully!')),
//         );

//         // Navigate back or reset form
//         Navigator.pop(context);
//       } catch (e) {
//         // Handle errors
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to submit request: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Create Blood Request'),
//         backgroundColor: const Color.fromARGB(255, 220, 61, 61),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Blood Type Dropdown
//               DropdownButtonFormField<String>(
//                 decoration: InputDecoration(
//                   labelText: 'Select Blood Type',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: _bloodTypes.map((type) {
//                   return DropdownMenuItem(
//                     value: type,
//                     child: Text(type),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedBloodType = value;
//                   });
//                 },
//                 validator: (value) =>
//                     value == null ? 'Please select a blood type' : null,
//               ),
//               SizedBox(height: 16),

//               // Urgency Dropdown
//               DropdownButtonFormField<String>(
//                 decoration: InputDecoration(
//                   labelText: 'Select Urgency Level',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: _urgencyLevels.map((level) {
//                   return DropdownMenuItem(
//                     value: level,
//                     child: Text(level),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedUrgency = value;
//                   });
//                 },
//                 validator: (value) =>
//                     value == null ? 'Please select an urgency level' : null,
//               ),
//               SizedBox(height: 16),

//               // Additional Notes
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Additional Notes (optional)',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 3,
//                 onSaved: (value) {
//                   _additionalNotes = value;
//                 },
//               ),
//               SizedBox(height: 16),

//               // Submit Button
//               ElevatedButton(
//                 onPressed: _submitRequest,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 220, 61, 61),
//                 ),
//                 child: Text('Submit Request', style: TextStyle(fontSize: 18)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// // // Import necessary packages
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';

// // class HospitalHomePage extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title:
// //             Text('Hospital Home Page', style: TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.blue,
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             ElevatedButton(
// //               onPressed: () {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (context) => BloodRequestPage(),
// //                   ),
// //                 );
// //               },
// //               child: Text('Create Blood Request'),
// //               style: ElevatedButton.styleFrom(
// //                 primary: Colors.red,
// //                 padding: EdgeInsets.symmetric(vertical: 15),
// //                 textStyle: TextStyle(fontSize: 18),
// //               ),
// //             ),
// //             SizedBox(height: 20),
// //             Expanded(
// //               child: StreamBuilder(
// //                 stream: FirebaseFirestore.instance
// //                     .collection('bloodRequests')
// //                     .snapshots(),
// //                 builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
// //                   if (snapshot.connectionState == ConnectionState.waiting) {
// //                     return Center(child: CircularProgressIndicator());
// //                   }

// //                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //                     return Center(
// //                       child: Text(
// //                         'No Blood Requests Found',
// //                         style: TextStyle(fontSize: 16),
// //                       ),
// //                     );
// //                   }

// //                   return ListView.builder(
// //                     itemCount: snapshot.data!.docs.length,
// //                     itemBuilder: (context, index) {
// //                       var request = snapshot.data!.docs[index];
// //                       return Card(
// //                         child: ListTile(
// //                           title: Text('Blood Group: ${request['bloodGroup']}'),
// //                           subtitle: Text(
// //                               'Units: ${request['units']} \nContact: ${request['contact']}'),
// //                           trailing: Text(request['status']),
// //                         ),
// //                       );
// //                     },
// //                   );
// //                 },
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class BloodRequestPage extends StatefulWidget {
// //   @override
// //   _BloodRequestPageState createState() => _BloodRequestPageState();
// // }

// // class _BloodRequestPageState extends State<BloodRequestPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   TextEditingController bloodGroupController = TextEditingController();
// //   TextEditingController unitsController = TextEditingController();
// //   TextEditingController contactController = TextEditingController();

// //   void _createBloodRequest() async {
// //     if (_formKey.currentState!.validate()) {
// //       await FirebaseFirestore.instance.collection('bloodRequests').add({
// //         'bloodGroup': bloodGroupController.text,
// //         'units': int.parse(unitsController.text),
// //         'contact': contactController.text,
// //         'status': 'Pending',
// //         'timestamp': FieldValue.serverTimestamp(),
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Blood Request Created Successfully')),
// //       );

// //       bloodGroupController.clear();
// //       unitsController.clear();
// //       contactController.clear();

// //       Navigator.pop(context);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title:
// //             Text('Create Blood Request', style: TextStyle(color: Colors.white)),
// //         backgroundColor: Colors.red,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               TextFormField(
// //                 controller: bloodGroupController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Blood Group',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Please enter blood group';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               TextFormField(
// //                 controller: unitsController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Number of Units',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 keyboardType: TextInputType.number,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Please enter number of units';
// //                   }
// //                   if (int.tryParse(value) == null) {
// //                     return 'Please enter a valid number';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               TextFormField(
// //                 controller: contactController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Contact Number',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 keyboardType: TextInputType.phone,
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Please enter contact number';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 20),
// //               Center(
// //                 child: ElevatedButton(
// //                   onPressed: _createBloodRequest,
// //                   child: Text('Submit Request'),
// //                   style: ElevatedButton.styleFrom(
// //                     primary: Colors.red,
// //                     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
