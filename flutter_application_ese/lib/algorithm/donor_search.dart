import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_ese/algorithm/calculateHarversineFormula.dart';

class DonorSearchPage extends StatefulWidget {
  final String userId;
  DonorSearchPage({required this.userId});

  @override
  _DonorSearchPageState createState() => _DonorSearchPageState();
}

class _DonorSearchPageState extends State<DonorSearchPage> {
  final _formKey = GlobalKey<FormState>();
  final radiusController = TextEditingController();
  String? selectedBloodType;
  List<Map<String, dynamic>> searchResults = [];
  double? userLat;
  double? userLon;

  List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  Map<String, List<String>> bloodTypeCompatibility = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
  };

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        userLat = position.latitude;
        userLon = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch your location.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchNearbyDonors(
      double userLat, double userLon, double radiusKm) async {
    List<Map<String, dynamic>> donors = [];
    try {
      final donorSnapshot =
          await FirebaseFirestore.instance.collection('donors').get();
      for (var doc in donorSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('location') && data.containsKey('bloodType')) {
          final location = data['location'].split(',');
          final donorLat = double.parse(location[0]);
          final donorLon = double.parse(location[1]);

          final distance =
              calculateHaversineDistance(userLat, userLon, donorLat, donorLon);

          if (distance <= radiusKm) {
            donors.add({
              'name': data['name'],
              'bloodType': data['bloodType'],
              'location': data['location'],
              'distance': distance,
            });
          }
        }
      }

      donors.sort((a, b) => a['distance'].compareTo(b['distance']));
    } catch (e) {
      print('Error fetching donors: $e');
    }
    return donors;
  }

  Future<void> _searchDonors() async {
    if (_formKey.currentState!.validate()) {
      if (userLat == null || userLon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to fetch your location.')),
        );
        return;
      }

      final radiusKm = double.parse(radiusController.text);
      final allDonors = await fetchNearbyDonors(userLat!, userLon!, radiusKm);

      if (selectedBloodType != null) {
        final compatibleBloodTypes =
            bloodTypeCompatibility[selectedBloodType!] ?? [];

        final filteredDonors = allDonors.where((donor) {
          return compatibleBloodTypes.contains(donor['bloodType']);
        }).toList();

        filteredDonors.sort((a, b) {
          final aPriority = a['bloodType'] == selectedBloodType ? 0 : 1;
          final bPriority = b['bloodType'] == selectedBloodType ? 0 : 1;
          return aPriority.compareTo(bPriority);
        });

        setState(() {
          searchResults = filteredDonors;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donor Search',
            style: TextStyle(
                fontSize: 24, color: const Color.fromARGB(255, 237, 243, 238))),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Donors Near You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: radiusController,
                decoration: InputDecoration(
                  labelText: 'Search Radius (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
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
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searchDonors,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 216, 69, 69),
                  ),
                  child: Text('Search',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 237, 243, 238))),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No donors found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final donor = searchResults[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              leading: Icon(
                                Icons.person,
                                color: Colors.redAccent,
                              ),
                              title: Text(donor['name'] ?? 'Unknown'),
                              subtitle: Text(
                                'Blood Type: ${donor['bloodType']}, Distance: ${donor['distance'].toStringAsFixed(2)} km',
                              ),
                            ),
                          );
                        },
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
// import 'package:geolocator/geolocator.dart'; // Import geolocator package
// import 'package:flutter_application_ese/algorithm/calculateHarversineFormula.dart';

// class DonorSearchPage extends StatefulWidget {
//   final String userId;
//   DonorSearchPage({required this.userId});

//   @override
//   _DonorSearchPageState createState() => _DonorSearchPageState();
// }

// class _DonorSearchPageState extends State<DonorSearchPage> {
//   final _formKey = GlobalKey<FormState>();
//   final radiusController = TextEditingController();
//   String? selectedBloodType;
//   List<Map<String, dynamic>> searchResults = [];
//   double? userLat;
//   double? userLon;

//   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

//   Map<String, List<String>> bloodTypeCompatibility = {
//     'A+': ['A+', 'A-', 'O+', 'O-'],
//     'A-': ['A-', 'O-'],
//     'B+': ['B+', 'B-', 'O+', 'O-'],
//     'B-': ['B-', 'O-'],
//     'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
//     'AB-': ['A-', 'B-', 'AB-', 'O-'],
//     'O+': ['O+', 'O-'],
//     'O-': ['O-'],
//   };

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserLocation(); // Fetch the user's location when the page is loaded
//   }

//   // Fetch user's current location using the Geolocator package
//   Future<void> _fetchUserLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       setState(() {
//         userLat = position.latitude;
//         userLon = position.longitude;
//       });
//     } catch (e) {
//       print('Error fetching user location: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Unable to fetch your location.')),
//       );
//     }
//   }

//   Future<List<Map<String, dynamic>>> fetchNearbyDonors(
//       double userLat, double userLon, double radiusKm) async {
//     List<Map<String, dynamic>> donors = [];

//     try {
//       final donorSnapshot =
//           await FirebaseFirestore.instance.collection('donors').get();

//       for (var doc in donorSnapshot.docs) {
//         final data = doc.data();
//         if (data.containsKey('location') && data.containsKey('bloodType')) {
//           final location = data['location'].split(',');
//           final donorLat = double.parse(location[0]);
//           final donorLon = double.parse(location[1]);

//           final distance =
//               calculateHaversineDistance(userLat, userLon, donorLat, donorLon);

//           if (distance <= radiusKm) {
//             donors.add({
//               'name': data['name'],
//               'bloodType': data['bloodType'],
//               'location': data['location'],
//               'distance': distance,
//             });
//           }
//         }
//       }

//       // Sort donors by distance
//       donors.sort((a, b) => a['distance'].compareTo(b['distance']));
//     } catch (e) {
//       print('Error fetching donors: $e');
//     }

//     return donors;
//   }

//   Future<void> _searchDonors() async {
//     if (_formKey.currentState!.validate()) {
//       if (userLat == null || userLon == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Unable to fetch your location.')),
//         );
//         return;
//       }

//       final radiusKm = double.parse(radiusController.text);
//       final allDonors = await fetchNearbyDonors(userLat!, userLon!, radiusKm);

//       if (selectedBloodType != null) {
//         final compatibleBloodTypes =
//             bloodTypeCompatibility[selectedBloodType!] ?? [];

//         final filteredDonors = allDonors.where((donor) {
//           return compatibleBloodTypes.contains(donor['bloodType']);
//         }).toList();

//         // Prioritize same blood type, then compatible types
//         // filteredDonors.sort((a, b) {
//         //   final aPriority = donor['bloodType'] == selectedBloodType ? 0 : 1;
//         //   final bPriority = donor['bloodType'] == selectedBloodType ? 0 : 1;
//         //   return aPriority.compareTo(bPriority);
//         // });
//         filteredDonors.sort((a, b) {
//           final aPriority = a['bloodType'] == selectedBloodType ? 0 : 1;
//           final bPriority = b['bloodType'] == selectedBloodType ? 0 : 1;
//           return aPriority.compareTo(bPriority);
//         });

//         setState(() {
//           searchResults = filteredDonors;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Donor Search')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextFormField(
//                 controller: radiusController,
//                 decoration: InputDecoration(
//                   labelText: 'Search Radius (km)',
//                 ),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || double.tryParse(value) == null) {
//                     return 'Please enter a valid number';
//                   }
//                   return null;
//                 },
//               ),
//               DropdownButtonFormField<String>(
//                 value: selectedBloodType,
//                 decoration: InputDecoration(labelText: 'Blood Type'),
//                 items: bloodTypes
//                     .map((type) =>
//                         DropdownMenuItem(value: type, child: Text(type)))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedBloodType = value;
//                   });
//                 },
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select a blood type';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _searchDonors,
//                 child: Text('Search'),
//               ),
//               SizedBox(height: 20),
//               Expanded(
//                 child: searchResults.isEmpty
//                     ? Center(child: Text('No donors found'))
//                     : ListView.builder(
//                         itemCount: searchResults.length,
//                         itemBuilder: (context, index) {
//                           final donor = searchResults[index];
//                           return ListTile(
//                             title: Text(donor['name'] ?? 'Unknown'),
//                             subtitle: Text(
//                                 'Blood Type: ${donor['bloodType']}, Distance: ${donor['distance'].toStringAsFixed(2)} km'),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






// //Simple with same blood type.

// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:geolocator/geolocator.dart'; // Import geolocator package
// // import 'package:flutter_application_ese/algorithm/calculateHarversineFormula.dart';

// // class DonorSearchPage extends StatefulWidget {
// //   final String userId;
// //   DonorSearchPage({required this.userId});

// //   @override
// //   _DonorSearchPageState createState() => _DonorSearchPageState();
// // }

// // class _DonorSearchPageState extends State<DonorSearchPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   final radiusController = TextEditingController();
// //   String? selectedBloodType;
// //   List<Map<String, dynamic>> searchResults = [];
// //   double? userLat;
// //   double? userLon;

// //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchUserLocation(); // Fetch the user's location when the page is loaded
// //   }

// //   // Fetch user's current location using the Geolocator package
// //   Future<void> _fetchUserLocation() async {
// //     try {
// //       Position position = await Geolocator.getCurrentPosition(
// //         desiredAccuracy: LocationAccuracy.high,
// //       );
// //       setState(() {
// //         userLat = position.latitude;
// //         userLon = position.longitude;
// //       });
// //     } catch (e) {
// //       print('Error fetching user location: $e');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Unable to fetch your location.')),
// //       );
// //     }
// //   }

// //   Future<List<Map<String, dynamic>>> fetchNearbyDonors(
// //       double userLat, double userLon, double radiusKm) async {
// //     List<Map<String, dynamic>> donors = [];

// //     try {
// //       final donorSnapshot =
// //           await FirebaseFirestore.instance.collection('donors').get();

// //       for (var doc in donorSnapshot.docs) {
// //         final data = doc.data();
// //         if (data.containsKey('location')) {
// //           final location = data['location'].split(',');
// //           final donorLat = double.parse(location[0]);
// //           final donorLon = double.parse(location[1]);

// //           final distance =
// //               calculateHaversineDistance(userLat, userLon, donorLat, donorLon);

// //           if (distance <= radiusKm) {
// //             donors.add({
// //               'name': data['name'],
// //               'bloodType': data['bloodType'],
// //               'location': data['location'],
// //               'distance': distance,
// //             });
// //           }
// //         }
// //       }

// //       // Sort donors by distance
// //       donors.sort((a, b) => a['distance'].compareTo(b['distance']));
// //     } catch (e) {
// //       print('Error fetching donors: $e');
// //     }

// //     return donors;
// //   }

// //   Future<void> _searchDonors() async {
// //     if (_formKey.currentState!.validate()) {
// //       if (userLat == null || userLon == null) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Unable to fetch your location.')),
// //         );
// //         return;
// //       }

// //       final radiusKm = double.parse(radiusController.text);
// //       final donors = await fetchNearbyDonors(userLat!, userLon!, radiusKm);
// //       final filteredDonors = donors.where((donor) {
// //         return donor['bloodType'] == selectedBloodType;
// //       }).toList();

// //       setState(() {
// //         searchResults = filteredDonors;
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Donor Search')),
// //       body: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               TextFormField(
// //                 controller: radiusController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Search Radius (km)',
// //                 ),
// //                 keyboardType: TextInputType.number,
// //                 validator: (value) {
// //                   if (value == null || double.tryParse(value) == null) {
// //                     return 'Please enter a valid number';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               DropdownButtonFormField<String>(
// //                 value: selectedBloodType,
// //                 decoration: InputDecoration(labelText: 'Blood Type'),
// //                 items: bloodTypes
// //                     .map((type) =>
// //                         DropdownMenuItem(value: type, child: Text(type)))
// //                     .toList(),
// //                 onChanged: (value) {
// //                   setState(() {
// //                     selectedBloodType = value;
// //                   });
// //                 },
// //                 validator: (value) {
// //                   if (value == null) {
// //                     return 'Please select a blood type';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 20),
// //               ElevatedButton(
// //                 onPressed: _searchDonors,
// //                 child: Text('Search'),
// //               ),
// //               SizedBox(height: 20),
// //               Expanded(
// //                 child: searchResults.isEmpty
// //                     ? Center(child: Text('No donors found'))
// //                     : ListView.builder(
// //                         itemCount: searchResults.length,
// //                         itemBuilder: (context, index) {
// //                           final donor = searchResults[index];
// //                           return ListTile(
// //                             title: Text(donor['name'] ?? 'Unknown'),
// //                             subtitle: Text(
// //                                 'Blood Type: ${donor['bloodType']}, Distance: ${donor['distance'].toStringAsFixed(2)} km'),
// //                           );
// //                         },
// //                       ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
