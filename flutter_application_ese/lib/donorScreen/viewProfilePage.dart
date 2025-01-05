import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewProfilePage extends StatefulWidget {
  @override
  _ViewProfilePageState createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userProfileData;
  bool isLoading = false;

  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }

      final snapshot = await _firestore
          .collection('donors')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User profile not found in Firestore.');
      }

      setState(() {
        userProfileData = snapshot.docs.first.data();
        selectedLocation = _parseLocation(userProfileData?['location']);
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  LatLng? _parseLocation(String? location) {
    if (location != null && location.isNotEmpty) {
      final parts = location.split(',');
      if (parts.length == 2) {
        final latitude = double.tryParse(parts[0]);
        final longitude = double.tryParse(parts[1]);
        if (latitude != null && longitude != null) {
          return LatLng(latitude, longitude);
        }
      }
    }
    return null;
  }

  Future<void> _updateUserProfile(String field, dynamic newValue) async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }

      final snapshot = await _firestore
          .collection('donors')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User profile not found in Firestore.');
      }

      final docId = snapshot.docs.first.id;

      await _firestore
          .collection('donors')
          .doc(docId)
          .update({field: newValue});

      setState(() {
        userProfileData![field] = newValue;
      });

      _showSuccessSnackBar('$field updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<void> _deleteUserProfile() async {
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });

  //     User? currentUser = _auth.currentUser;

  //     if (currentUser == null) {
  //       throw Exception('User is not authenticated.');
  //     }

  //     final snapshot = await _firestore
  //         .collection('donors')
  //         .where('userId', isEqualTo: currentUser.uid)
  //         .get();

  //     if (snapshot.docs.isEmpty) {
  //       throw Exception('User profile not found in Firestore.');
  //     }

  //     final docId = snapshot.docs.first.id;

  //     // Delete the donor profile from Firestore
  //     await _firestore.collection('donors').doc(docId).delete();

  //     // Delete the user from Firebase Authentication
  //     await currentUser.delete();

  //     // Redirect to login page after deletion
  //     Navigator.pushReplacementNamed(context, '/login');
  //   } catch (e) {
  //     _showErrorSnackBar('Error deleting profile: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> _deleteUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }

      // Deleting user profile from Firestore
      final snapshot = await _firestore
          .collection('donors')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User profile not found in Firestore.');
      }

      final docId = snapshot.docs.first.id;
      await _firestore.collection('donors').doc(docId).delete();

      // Deleting user from Firebase Authentication
      await currentUser.delete();

      await _auth.signOut(); // Logout user after deletion

      _showSuccessSnackBar('Profile deleted successfully!');
      _reloadApp(); // Reload app or return to login
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        _showErrorSnackBar(
            'Please reauthenticate and try again to delete your profile.');
      } else {
        _showErrorSnackBar('Error deleting profile: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _reloadApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Profile',
            style: TextStyle(
                fontSize: 24, color: Color.fromARGB(255, 237, 243, 238))),
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userProfileData == null
              ? Center(child: Text('No profile data available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileField(
                            'Name', userProfileData?['name'] ?? 'N/A', false),
                        _buildProfileField('Date of Birth',
                            userProfileData?['dob'] ?? 'N/A', false),
                        _buildProfileField(
                            'Age',
                            userProfileData?['age']?.toString() ?? 'N/A',
                            false),
                        _buildProfileField('Blood Type',
                            userProfileData?['bloodType'] ?? 'N/A', false),
                        _buildProfileField('Gender',
                            userProfileData?['gender'] ?? 'N/A', false),
                        _buildProfileField('Mobile Number',
                            userProfileData?['mobile'] ?? 'N/A', true),
                        _buildLocationField(),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _deleteUserProfile,
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Delete Profile',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 237, 243, 238)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileField(String label, String value, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          SizedBox(width: 10),
          Expanded(
            child: isEditable
                ? GestureDetector(
                    onTap: () => _showEditDialog(label, value),
                    child: Row(
                      children: [
                        Text(value, style: TextStyle(fontSize: 16.0)),
                        Icon(Icons.edit, color: Colors.grey),
                      ],
                    ),
                  )
                : Text(value, style: TextStyle(fontSize: 16.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            'Location:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _selectLocation,
              child: Row(
                children: [
                  Text(
                    userProfileData?['location'] ?? 'Select Location',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Icon(Icons.edit_location_alt, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocation() async {
    final LatLng pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(
          initialLocation: selectedLocation ?? LatLng(0, 0),
        ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        selectedLocation = pickedLocation;
      });
      _updateUserProfile('location',
          '${pickedLocation.latitude}, ${pickedLocation.longitude}');
    }
  }

  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    if (field == 'Mobile Number') {
      controller.addListener(() {
        final mobile = controller.text;
        if (mobile.length > 10) {
          controller.text = mobile.substring(0, 10);
          controller.selection = TextSelection.collapsed(offset: 10);
        }
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: 'Enter new $field'),
            maxLength: 10,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (field == 'Mobile Number' && controller.text.length == 10) {
                  _updateUserProfile('mobile', controller.text);
                  Navigator.pop(context);
                } else {
                  _showErrorSnackBar(
                      'Please enter a valid 10-digit mobile number');
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class MapPicker extends StatelessWidget {
  final LatLng initialLocation;

  MapPicker({required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialLocation,
          zoom: 14,
        ),
        onTap: (LatLng location) {
          Navigator.pop(context, location);
        },
        markers: {
          Marker(
            markerId: MarkerId('selected_location'),
            position: initialLocation,
          ),
        },
      ),
    );
  }
}


// // Trying for redirect to login page.
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class ViewProfilePage extends StatefulWidget {
//   @override
//   _ViewProfilePageState createState() => _ViewProfilePageState();
// }

// class _ViewProfilePageState extends State<ViewProfilePage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Map<String, dynamic>? userProfileData;
//   bool isLoading = false;

//   LatLng? selectedLocation;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserProfile();
//   }

//   Future<void> _fetchUserProfile() async {
//     try {
//       setState(() {
//         isLoading = true;
//       });

//       User? currentUser = _auth.currentUser;

//       if (currentUser == null) {
//         throw Exception('User is not authenticated.');
//       }

//       final snapshot = await _firestore
//           .collection('donors')
//           .where('userId', isEqualTo: currentUser.uid)
//           .get();

//       if (snapshot.docs.isEmpty) {
//         throw Exception('User profile not found in Firestore.');
//       }

//       setState(() {
//         userProfileData = snapshot.docs.first.data();
//         selectedLocation = _parseLocation(userProfileData?['location']);
//       });
//     } catch (e) {
//       _showErrorSnackBar('Error fetching profile: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   LatLng? _parseLocation(String? location) {
//     if (location != null && location.isNotEmpty) {
//       final parts = location.split(',');
//       if (parts.length == 2) {
//         final latitude = double.tryParse(parts[0]);
//         final longitude = double.tryParse(parts[1]);
//         if (latitude != null && longitude != null) {
//           return LatLng(latitude, longitude);
//         }
//       }
//     }
//     return null;
//   }

//   Future<void> _updateUserProfile(String field, dynamic newValue) async {
//     try {
//       setState(() {
//         isLoading = true;
//       });

//       User? currentUser = _auth.currentUser;

//       if (currentUser == null) {
//         throw Exception('User is not authenticated.');
//       }

//       final snapshot = await _firestore
//           .collection('donors')
//           .where('userId', isEqualTo: currentUser.uid)
//           .get();

//       if (snapshot.docs.isEmpty) {
//         throw Exception('User profile not found in Firestore.');
//       }

//       final docId = snapshot.docs.first.id;

//       await _firestore
//           .collection('donors')
//           .doc(docId)
//           .update({field: newValue});

//       setState(() {
//         userProfileData![field] = newValue;
//       });

//       _showSuccessSnackBar('$field updated successfully!');
//     } catch (e) {
//       _showErrorSnackBar('Error updating profile: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _deleteUserProfile() async {
//     try {
//       setState(() {
//         isLoading = true;
//       });

//       User? currentUser = _auth.currentUser;

//       if (currentUser == null) {
//         throw Exception('User is not authenticated.');
//       }

//       final donorsSnapshot = await _firestore
//           .collection('donors')
//           .where('userId', isEqualTo: currentUser.uid)
//           .get();

//       if (donorsSnapshot.docs.isNotEmpty) {
//         final donorDocId = donorsSnapshot.docs.first.id;
//         await _firestore.collection('donors').doc(donorDocId).delete();
//       }

//       await _firestore.collection('users').doc(currentUser.uid).delete();

//       await currentUser.delete();

//       _showSuccessSnackBar('Profile deleted successfully!');
//       Navigator.pop(context);
//     } catch (e) {
//       _showErrorSnackBar('Error deleting profile: $e');
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Color.fromARGB(255, 216, 69, 69),
//       ),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'View Profile',
//           style: TextStyle(
//               fontSize: 24, color: Color.fromARGB(255, 237, 243, 238)),
//         ),
//         backgroundColor: Color.fromARGB(255, 216, 69, 69),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : userProfileData == null
//               ? Center(child: Text('No profile data available.'))
//               : Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildProfileField(
//                             'Name', userProfileData?['name'] ?? 'N/A', false),
//                         _buildProfileField('Date of Birth',
//                             userProfileData?['dob'] ?? 'N/A', false),
//                         _buildProfileField(
//                             'Age',
//                             userProfileData?['age']?.toString() ?? 'N/A',
//                             false),
//                         _buildProfileField('Blood Type',
//                             userProfileData?['bloodType'] ?? 'N/A', false),
//                         _buildProfileField('Gender',
//                             userProfileData?['gender'] ?? 'N/A', false),
//                         _buildProfileField('Mobile Number',
//                             userProfileData?['mobile'] ?? 'N/A', true),
//                         _buildLocationField(),
//                         SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: _deleteUserProfile,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color.fromARGB(255, 216, 69, 69),
//                           ),
//                           child: Text('Delete Profile'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//     );
//   }

//   Widget _buildProfileField(String label, String value, bool isEditable) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Text(
//             '$label:',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//           ),
//           SizedBox(width: 10),
//           Expanded(
//             child: isEditable
//                 ? GestureDetector(
//                     onTap: () => _showEditDialog(label, value),
//                     child: Row(
//                       children: [
//                         Text(value, style: TextStyle(fontSize: 16.0)),
//                         Icon(Icons.edit, color: Colors.grey),
//                       ],
//                     ),
//                   )
//                 : Text(value, style: TextStyle(fontSize: 16.0)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationField() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Text(
//             'Location:',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//           ),
//           SizedBox(width: 10),
//           Expanded(
//             child: GestureDetector(
//               onTap: _selectLocation,
//               child: Row(
//                 children: [
//                   Text(
//                     userProfileData?['location'] ?? 'Select Location',
//                     style: TextStyle(fontSize: 16.0),
//                   ),
//                   Icon(Icons.edit_location_alt, color: Colors.grey),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _selectLocation() async {
//     final LatLng pickedLocation = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MapPicker(
//           initialLocation: selectedLocation ?? LatLng(0, 0),
//         ),
//       ),
//     );

//     if (pickedLocation != null) {
//       setState(() {
//         selectedLocation = pickedLocation;
//       });
//       _updateUserProfile('location',
//           '${pickedLocation.latitude}, ${pickedLocation.longitude}');
//     }
//   }

//   void _showEditDialog(String field, String currentValue) {
//     TextEditingController controller =
//         TextEditingController(text: currentValue);

//     if (field == 'Mobile Number') {
//       controller.addListener(() {
//         final mobile = controller.text;
//         if (mobile.length > 10) {
//           controller.text = mobile.substring(0, 10);
//           controller.selection = TextSelection.collapsed(offset: 10);
//         }
//       });
//     }

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Edit $field'),
//           content: TextField(
//             controller: controller,
//             keyboardType: TextInputType.phone,
//             decoration: InputDecoration(hintText: 'Enter new $field'),
//             maxLength: 10,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (field == 'Mobile Number' && controller.text.length == 10) {
//                   _updateUserProfile('mobile', controller.text);
//                   Navigator.pop(context);
//                 } else {
//                   _showErrorSnackBar(
//                       'Please enter a valid 10-digit mobile number');
//                 }
//               },
//               child: Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class MapPicker extends StatelessWidget {
//   final LatLng initialLocation;

//   MapPicker({required this.initialLocation});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Pick Location'),
//       ),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: initialLocation,
//           zoom: 14,
//         ),
//         onTap: (LatLng location) {
//           Navigator.pop(context, location);
//         },
//         markers: {
//           Marker(
//             markerId: MarkerId('selected_location'),
//             position: initialLocation,
//           ),
//         },
//       ),
//     );
//   }
// }



// // //mobile number(only 10 digits) and location editable

// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';

// // class ViewProfilePage extends StatefulWidget {
// //   @override
// //   _ViewProfilePageState createState() => _ViewProfilePageState();
// // }

// // class _ViewProfilePageState extends State<ViewProfilePage> {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// //   Map<String, dynamic>? userProfileData;
// //   bool isLoading = false;

// //   LatLng? selectedLocation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchUserProfile();
// //   }

// //   Future<void> _fetchUserProfile() async {
// //     try {
// //       setState(() {
// //         isLoading = true;
// //       });

// //       User? currentUser = _auth.currentUser;

// //       if (currentUser == null) {
// //         throw Exception('User is not authenticated.');
// //       }

// //       final snapshot = await _firestore
// //           .collection('donors')
// //           .where('userId', isEqualTo: currentUser.uid)
// //           .get();

// //       if (snapshot.docs.isEmpty) {
// //         throw Exception('User profile not found in Firestore.');
// //       }

// //       setState(() {
// //         userProfileData = snapshot.docs.first.data();
// //         selectedLocation = _parseLocation(userProfileData?['location']);
// //       });
// //     } catch (e) {
// //       _showErrorSnackBar('Error fetching profile: $e');
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }

// //   LatLng? _parseLocation(String? location) {
// //     if (location != null && location.isNotEmpty) {
// //       final parts = location.split(',');
// //       if (parts.length == 2) {
// //         final latitude = double.tryParse(parts[0]);
// //         final longitude = double.tryParse(parts[1]);
// //         if (latitude != null && longitude != null) {
// //           return LatLng(latitude, longitude);
// //         }
// //       }
// //     }
// //     return null;
// //   }

// //   Future<void> _updateUserProfile(String field, dynamic newValue) async {
// //     try {
// //       setState(() {
// //         isLoading = true;
// //       });

// //       User? currentUser = _auth.currentUser;

// //       if (currentUser == null) {
// //         throw Exception('User is not authenticated.');
// //       }

// //       final snapshot = await _firestore
// //           .collection('donors')
// //           .where('userId', isEqualTo: currentUser.uid)
// //           .get();

// //       if (snapshot.docs.isEmpty) {
// //         throw Exception('User profile not found in Firestore.');
// //       }

// //       final docId = snapshot.docs.first.id;

// //       await _firestore
// //           .collection('donors')
// //           .doc(docId)
// //           .update({field: newValue});

// //       setState(() {
// //         userProfileData![field] = newValue;
// //       });

// //       _showSuccessSnackBar('$field updated successfully!');
// //     } catch (e) {
// //       _showErrorSnackBar('Error updating profile: $e');
// //     } finally {
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }

// //   void _showErrorSnackBar(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Color.fromARGB(255, 216, 69, 69),
// //       ),
// //     );
// //   }

// //   void _showSuccessSnackBar(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         backgroundColor: Colors.green,
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('View Profile',
// //             style: TextStyle(
// //                 fontSize: 24, color: Color.fromARGB(255, 237, 243, 238))),
// //         backgroundColor: Color.fromARGB(255, 216, 69, 69),
// //       ),
// //       body: isLoading
// //           ? Center(child: CircularProgressIndicator())
// //           : userProfileData == null
// //               ? Center(child: Text('No profile data available.'))
// //               : Padding(
// //                   padding: const EdgeInsets.all(16.0),
// //                   child: SingleChildScrollView(
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         _buildProfileField(
// //                             'Name', userProfileData?['name'] ?? 'N/A', false),
// //                         _buildProfileField('Date of Birth',
// //                             userProfileData?['dob'] ?? 'N/A', false),
// //                         _buildProfileField(
// //                             'Age',
// //                             userProfileData?['age']?.toString() ?? 'N/A',
// //                             false),
// //                         _buildProfileField('Blood Type',
// //                             userProfileData?['bloodType'] ?? 'N/A', false),
// //                         _buildProfileField('Gender',
// //                             userProfileData?['gender'] ?? 'N/A', false),
// //                         _buildProfileField('Mobile Number',
// //                             userProfileData?['mobile'] ?? 'N/A', true),
// //                         _buildLocationField(),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //     );
// //   }

// //   Widget _buildProfileField(String label, String value, bool isEditable) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8.0),
// //       child: Row(
// //         children: [
// //           Text(
// //             '$label:',
// //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
// //           ),
// //           SizedBox(width: 10),
// //           Expanded(
// //             child: isEditable
// //                 ? GestureDetector(
// //                     onTap: () => _showEditDialog(label, value),
// //                     child: Row(
// //                       children: [
// //                         Text(value, style: TextStyle(fontSize: 16.0)),
// //                         Icon(Icons.edit, color: Colors.grey),
// //                       ],
// //                     ),
// //                   )
// //                 : Text(value, style: TextStyle(fontSize: 16.0)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildLocationField() {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 8.0),
// //       child: Row(
// //         children: [
// //           Text(
// //             'Location:',
// //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
// //           ),
// //           SizedBox(width: 10),
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: _selectLocation,
// //               child: Row(
// //                 children: [
// //                   Text(
// //                     userProfileData?['location'] ?? 'Select Location',
// //                     style: TextStyle(fontSize: 16.0),
// //                   ),
// //                   Icon(Icons.edit_location_alt, color: Colors.grey),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Future<void> _selectLocation() async {
// //     final LatLng pickedLocation = await Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => MapPicker(
// //           initialLocation: selectedLocation ?? LatLng(0, 0),
// //         ),
// //       ),
// //     );

// //     if (pickedLocation != null) {
// //       setState(() {
// //         selectedLocation = pickedLocation;
// //       });
// //       _updateUserProfile('location',
// //           '${pickedLocation.latitude}, ${pickedLocation.longitude}');
// //     }
// //   }

// //   void _showEditDialog(String field, String currentValue) {
// //     TextEditingController controller =
// //         TextEditingController(text: currentValue);

// //     if (field == 'Mobile Number') {
// //       controller.addListener(() {
// //         final mobile = controller.text;
// //         if (mobile.length > 10) {
// //           controller.text = mobile.substring(0, 10);
// //           controller.selection = TextSelection.collapsed(offset: 10);
// //         }
// //       });
// //     }

// //     showDialog(
// //       context: context,
// //       builder: (context) {
// //         return AlertDialog(
// //           title: Text('Edit $field'),
// //           content: TextField(
// //             controller: controller,
// //             keyboardType: TextInputType.phone,
// //             decoration: InputDecoration(hintText: 'Enter new $field'),
// //             maxLength: 10,
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.pop(context);
// //               },
// //               child: Text('Cancel'),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 if (field == 'Mobile Number' && controller.text.length == 10) {
// //                   _updateUserProfile('mobile', controller.text);
// //                   Navigator.pop(context);
// //                 } else {
// //                   _showErrorSnackBar(
// //                       'Please enter a valid 10-digit mobile number');
// //                 }
// //               },
// //               child: Text('Save'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// // }

// // class MapPicker extends StatelessWidget {
// //   final LatLng initialLocation;

// //   MapPicker({required this.initialLocation});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Pick Location'),
// //       ),
// //       body: GoogleMap(
// //         initialCameraPosition: CameraPosition(
// //           target: initialLocation,
// //           zoom: 14,
// //         ),
// //         onTap: (LatLng location) {
// //           Navigator.pop(context, location);
// //         },
// //         markers: {
// //           Marker(
// //             markerId: MarkerId('selected_location'),
// //             position: initialLocation,
// //           ),
// //         },
// //       ),
// //     );
// //   }
// // }



// // //correctly deleting it

// // // import 'package:flutter/material.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:firebase_auth/firebase_auth.dart';

// // // class ViewProfilePage extends StatefulWidget {
// // //   @override
// // //   _ViewProfilePageState createState() => _ViewProfilePageState();
// // // }

// // // class _ViewProfilePageState extends State<ViewProfilePage> {
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// // //   Map<String, dynamic>? userProfileData;
// // //   bool isLoading = false;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchUserProfile();
// // //   }

// // //   Future<void> _fetchUserProfile() async {
// // //     try {
// // //       setState(() {
// // //         isLoading = true;
// // //       });

// // //       User? currentUser = _auth.currentUser;

// // //       if (currentUser == null) {
// // //         throw Exception('User is not authenticated.');
// // //       }

// // //       final snapshot = await _firestore
// // //           .collection('donors')
// // //           .where('userId', isEqualTo: currentUser.uid)
// // //           .get();

// // //       if (snapshot.docs.isEmpty) {
// // //         throw Exception('User profile not found in Firestore.');
// // //       }

// // //       setState(() {
// // //         userProfileData = snapshot.docs.first.data();
// // //       });
// // //     } catch (e) {
// // //       _showErrorSnackBar('Error fetching profile: $e');
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }

// // //   Future<void> _updateUserProfile(String field, String newValue) async {
// // //     try {
// // //       setState(() {
// // //         isLoading = true;
// // //       });

// // //       User? currentUser = _auth.currentUser;

// // //       if (currentUser == null) {
// // //         throw Exception('User is not authenticated.');
// // //       }

// // //       final snapshot = await _firestore
// // //           .collection('donors')
// // //           .where('userId', isEqualTo: currentUser.uid)
// // //           .get();

// // //       if (snapshot.docs.isEmpty) {
// // //         throw Exception('User profile not found in Firestore.');
// // //       }

// // //       final docId = snapshot.docs.first.id;

// // //       await _firestore
// // //           .collection('donors')
// // //           .doc(docId)
// // //           .update({field: newValue});

// // //       setState(() {
// // //         userProfileData![field] = newValue;
// // //       });

// // //       _showSuccessSnackBar('$field updated successfully!');
// // //     } catch (e) {
// // //       _showErrorSnackBar('Error updating profile: $e');
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }

// // //   Future<void> _deleteUserProfile() async {
// // //     try {
// // //       setState(() {
// // //         isLoading = true;
// // //       });

// // //       User? currentUser = _auth.currentUser;

// // //       if (currentUser == null) {
// // //         throw Exception('User is not authenticated.');
// // //       }

// // //       // Deleting user profile from Firestore
// // //       final snapshot = await _firestore
// // //           .collection('donors')
// // //           .where('userId', isEqualTo: currentUser.uid)
// // //           .get();

// // //       if (snapshot.docs.isEmpty) {
// // //         throw Exception('User profile not found in Firestore.');
// // //       }

// // //       final docId = snapshot.docs.first.id;
// // //       await _firestore.collection('donors').doc(docId).delete();

// // //       // Deleting user from Firebase Authentication
// // //       await currentUser.delete();

// // //       await _auth.signOut(); // Logout user after deletion

// // //       _showSuccessSnackBar('Profile deleted successfully!');
// // //       _reloadApp(); // Reload app or return to login
// // //     } catch (e) {
// // //       if (e.toString().contains('requires-recent-login')) {
// // //         _showErrorSnackBar(
// // //             'Please reauthenticate and try again to delete your profile.');
// // //       } else {
// // //         _showErrorSnackBar('Error deleting profile: $e');
// // //       }
// // //     } finally {
// // //       setState(() {
// // //         isLoading = false;
// // //       });
// // //     }
// // //   }

// // //   void _reloadApp() {
// // //     Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
// // //   }

// // //   void _showSuccessSnackBar(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message),
// // //         backgroundColor: Colors.green,
// // //       ),
// // //     );
// // //   }

// // //   void _showErrorSnackBar(String message) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message),
// // //         backgroundColor: Colors.red,
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text(
// // //           'View Profile',
// // //           style: TextStyle(color: Colors.white),
// // //         ),
// // //         backgroundColor: Color.fromARGB(255, 216, 69, 69),
// // //         actions: [
// // //           IconButton(
// // //             icon: Icon(Icons.logout),
// // //             onPressed: () async {
// // //               await _auth.signOut();
// // //               _reloadApp();
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //       body: isLoading
// // //           ? Center(child: CircularProgressIndicator())
// // //           : userProfileData == null
// // //               ? Center(child: Text('No profile data available.'))
// // //               : Padding(
// // //                   padding: const EdgeInsets.all(16.0),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       _buildProfileField(
// // //                           'Name', userProfileData!['name'], true),
// // //                       _buildProfileField(
// // //                           'Date of Birth', userProfileData!['dob'], true),
// // //                       _buildProfileField(
// // //                           'Age', userProfileData!['age'].toString(), true),
// // //                       _buildProfileField(
// // //                           'Blood Type', userProfileData!['bloodType'], false),
// // //                       _buildProfileField(
// // //                           'Gender', userProfileData!['gender'], false),
// // //                       _buildProfileField(
// // //                           'Location', userProfileData!['location'], true),
// // //                       Spacer(),
// // //                       Center(
// // //                         child: ElevatedButton(
// // //                           onPressed: _deleteUserProfile,
// // //                           style: ElevatedButton.styleFrom(
// // //                               primary: Colors.redAccent),
// // //                           child: Text('Delete Profile'),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //     );
// // //   }

// // //   Widget _buildProfileField(String label, String value, bool isEditable) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(vertical: 8.0),
// // //       child: Row(
// // //         children: [
// // //           Text(
// // //             '$label:',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontSize: 16.0,
// // //             ),
// // //           ),
// // //           SizedBox(width: 10),
// // //           Expanded(
// // //             child: isEditable
// // //                 ? GestureDetector(
// // //                     onTap: () => _showEditDialog(label, value),
// // //                     child: Row(
// // //                       children: [
// // //                         Text(
// // //                           value,
// // //                           style: TextStyle(fontSize: 16.0),
// // //                         ),
// // //                         Icon(Icons.edit, color: Colors.grey),
// // //                       ],
// // //                     ),
// // //                   )
// // //                 : Text(
// // //                     value,
// // //                     style: TextStyle(fontSize: 16.0),
// // //                   ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   void _showEditDialog(String field, String currentValue) {
// // //     TextEditingController controller =
// // //         TextEditingController(text: currentValue);

// // //     showDialog(
// // //       context: context,
// // //       builder: (context) {
// // //         return AlertDialog(
// // //           title: Text('Edit $field'),
// // //           content: TextField(
// // //             controller: controller,
// // //             decoration: InputDecoration(hintText: 'Enter new $field'),
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context);
// // //               },
// // //               child: Text('Cancel'),
// // //             ),
// // //             TextButton(
// // //               onPressed: () {
// // //                 _updateUserProfile(field.toLowerCase(), controller.text);
// // //                 Navigator.pop(context);
// // //               },
// // //               child: Text('Save'),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }
// // // }




// // // //correct working profile page.

// // // // import 'package:flutter/material.dart';
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:firebase_auth/firebase_auth.dart';

// // // // class ViewProfilePage extends StatefulWidget {
// // // //   @override
// // // //   _ViewProfilePageState createState() => _ViewProfilePageState();
// // // // }

// // // // class _ViewProfilePageState extends State<ViewProfilePage> {
// // // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // // //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// // // //   Map<String, dynamic>? userProfileData;

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _fetchUserProfile();
// // // //   }

// // // //   Future<void> _fetchUserProfile() async {
// // // //     try {
// // // //       User? currentUser = _auth.currentUser;

// // // //       if (currentUser == null) {
// // // //         throw Exception('User is not authenticated.');
// // // //       }

// // // //       final snapshot = await _firestore
// // // //           .collection('donors')
// // // //           .where('userId', isEqualTo: currentUser.uid)
// // // //           .get();

// // // //       if (snapshot.docs.isEmpty) {
// // // //         throw Exception('User profile not found in Firestore.');
// // // //       }

// // // //       setState(() {
// // // //         userProfileData = snapshot.docs.first.data();
// // // //       });
// // // //     } catch (e) {
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         SnackBar(content: Text('Error fetching profile: $e')),
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Text(
// // // //           'View Profile',
// // // //           style: TextStyle(color: Colors.white),
// // // //         ),
// // // //         backgroundColor: Color.fromARGB(255, 216, 69, 69),
// // // //       ),
// // // //       body: userProfileData == null
// // // //           ? Center(child: CircularProgressIndicator())
// // // //           : Padding(
// // // //               padding: const EdgeInsets.all(16.0),
// // // //               child: Column(
// // // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // // //                 children: [
// // // //                   _buildProfileField('Name', userProfileData!['name']),
// // // //                   _buildProfileField('Date of Birth', userProfileData!['dob']),
// // // //                   _buildProfileField('Age', userProfileData!['age'].toString()),
// // // //                   _buildProfileField(
// // // //                       'Blood Type', userProfileData!['bloodType']),
// // // //                   _buildProfileField('Gender', userProfileData!['gender']),
// // // //                   _buildProfileField('Location', userProfileData!['location']),
// // // //                   Spacer(),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //     );
// // // //   }

// // // //   Widget _buildProfileField(String label, String value) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(vertical: 8.0),
// // // //       child: Row(
// // // //         children: [
// // // //           Text(
// // // //             '$label:',
// // // //             style: TextStyle(
// // // //               fontWeight: FontWeight.bold,
// // // //               fontSize: 16.0,
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: 10),
// // // //           Expanded(
// // // //             child: Text(
// // // //               value,
// // // //               style: TextStyle(fontSize: 16.0),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }
