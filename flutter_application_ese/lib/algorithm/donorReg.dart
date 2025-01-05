// // Adding just mobile number field in the code.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_ese/algorithm/MapPickerScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonorRegistrationPage extends StatefulWidget {
  @override
  _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
}

class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController(); // Added for mobile number
  String? selectedBloodType;
  String? selectedGender;

  LatLng? selectedLocation;

  List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<String> genders = ['Male', 'Female', 'Other'];

  void _getLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled.');
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

    _showSnackBar('Live location selected successfully.');
  }

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

      _showSnackBar('Location selected on map successfully.');
    }
  }

  Future<bool> _isDonorUnique(String name, String dob) async {
    final querySnapshot = await _firestore
        .collection('donors')
        .where('name', isEqualTo: name)
        .where('dob', isEqualTo: dob)
        .get();

    return querySnapshot.docs.isEmpty; // True if no existing donor is found
  }

  void _selectDateOfBirth(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
      });
    }
  }

  void _registerDonor() async {
    if (_formKey.currentState!.validate()) {
      if (selectedLocation == null) {
        _showSnackBar('Please select a location (live or map).');
        return;
      }

      final dob = DateTime.parse(dobController.text);
      final age = DateTime.now().year - dob.year;
      if (age < 18) {
        _showSnackBar('Donor must be at least 18 years old.');
        return;
      }

      final name = nameController.text;
      final dobText = dobController.text;
      final email = emailController.text;
      final password = passwordController.text;
      final mobile = mobileController.text; // Get the mobile number

      // Check for unique donor
      if (!await _isDonorUnique(name, dobText)) {
        _showSnackBar('Donor with these credentials already exists.');
        return;
      }

      try {
        // Create user in Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final donorData = {
          'name': name,
          'dob': dobText,
          'age': age,
          'bloodType': selectedBloodType,
          'gender': selectedGender,
          'location':
              '${selectedLocation!.latitude},${selectedLocation!.longitude}',
          'userId': userCredential
              .user?.uid, // Store user ID from Firebase Authentication
          'mobile': mobile, // Save mobile number
        };

        final userData = {
          'email': email,
          'role': 'donor', // Add role to identify the user as a donor
        };

        // Store donor data in Firestore
        await _firestore.collection('donors').add(donorData);

        // Store user data in users collection
        await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .set(userData);

        _showSnackBar('Donor registered successfully!');
        _formKey.currentState!.reset();
        nameController.clear();
        dobController.clear();
        emailController.clear();
        passwordController.clear();
        mobileController.clear(); // Clear mobile number field
        setState(() {
          selectedLocation = null;
          selectedBloodType = null;
          selectedGender = null;
        });
      } catch (e) {
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donor Registration',
            style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: mobileController, // Added for mobile number
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDateOfBirth(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your date of birth';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
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
                    return 'Please select your blood type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: genders
                    .map((gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _getLiveLocation,
                    icon: Icon(Icons.my_location),
                    label: Text('Use Live Location',
                        style: TextStyle(
                            color: const Color.fromARGB(255, 237, 243, 238))),
                    style: ElevatedButton.styleFrom(primary: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectLocationOnMap,
                    icon: Icon(Icons.map),
                    label: Text('Pick on Map',
                        style: TextStyle(
                            color: const Color.fromARGB(255, 237, 243, 238))),
                    style: ElevatedButton.styleFrom(primary: Colors.blue),
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
                  onPressed: _registerDonor,
                  child: Text('Register',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 237, 243, 238))),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.redAccent,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
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

// // till this all functions in the app are working fine.

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_ese/algorithm/MapPickerScreen.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class DonorRegistrationPage extends StatefulWidget {
//   @override
//   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// }

// class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _firestore = FirebaseFirestore.instance;
//   final _auth = FirebaseAuth.instance;

//   final nameController = TextEditingController();
//   final dobController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   String? selectedBloodType;
//   String? selectedGender;

//   LatLng? selectedLocation;

//   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
//   List<String> genders = ['Male', 'Female', 'Other'];

//   void _getLiveLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showSnackBar('Location services are disabled.');
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showSnackBar('Location permissions are denied.');
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showSnackBar(
//           'Location permissions are permanently denied. Enable them in settings.');
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);

//     setState(() {
//       selectedLocation = LatLng(position.latitude, position.longitude);
//     });

//     _showSnackBar('Live location selected successfully.');
//   }

//   void _selectLocationOnMap() async {
//     LatLng? chosenLocation = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MapPickerScreen(),
//       ),
//     );

//     if (chosenLocation != null) {
//       setState(() {
//         selectedLocation = chosenLocation;
//       });

//       _showSnackBar('Location selected on map successfully.');
//     }
//   }

//   Future<bool> _isDonorUnique(String name, String dob) async {
//     final querySnapshot = await _firestore
//         .collection('donors')
//         .where('name', isEqualTo: name)
//         .where('dob', isEqualTo: dob)
//         .get();

//     return querySnapshot.docs.isEmpty; // True if no existing donor is found
//   }

//   void _selectDateOfBirth(BuildContext context) async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );

//     if (pickedDate != null) {
//       setState(() {
//         dobController.text =
//             pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
//       });
//     }
//   }

//   void _registerDonor() async {
//     if (_formKey.currentState!.validate()) {
//       if (selectedLocation == null) {
//         _showSnackBar('Please select a location (live or map).');
//         return;
//       }

//       final dob = DateTime.parse(dobController.text);
//       final age = DateTime.now().year - dob.year;
//       if (age < 18) {
//         _showSnackBar('Donor must be at least 18 years old.');
//         return;
//       }

//       final name = nameController.text;
//       final dobText = dobController.text;
//       final email = emailController.text;
//       final password = passwordController.text;

//       // Check for unique donor
//       if (!await _isDonorUnique(name, dobText)) {
//         _showSnackBar('Donor with these credentials already exists.');
//         return;
//       }

//       try {
//         // Create user in Firebase Authentication
//         UserCredential userCredential =
//             await _auth.createUserWithEmailAndPassword(
//           email: email,
//           password: password,
//         );

//         final donorData = {
//           'name': name,
//           'dob': dobText,
//           'age': age,
//           'bloodType': selectedBloodType,
//           'gender': selectedGender,
//           'location':
//               '${selectedLocation!.latitude},${selectedLocation!.longitude}',
//           'userId': userCredential
//               .user?.uid, // Store user ID from Firebase Authentication
//         };

//         final userData = {
//           'email': email,
//           'role': 'donor', // Add role to identify the user as a donor
//         };

//         // Store donor data in Firestore
//         await _firestore.collection('donors').add(donorData);

//         // Store user data in users collection
//         await _firestore
//             .collection('users')
//             .doc(userCredential.user?.uid)
//             .set(userData);

//         _showSnackBar('Donor registered successfully!');
//         _formKey.currentState!.reset();
//         nameController.clear();
//         dobController.clear();
//         emailController.clear();
//         passwordController.clear();
//         setState(() {
//           selectedLocation = null;
//           selectedBloodType = null;
//           selectedGender = null;
//         });
//       } catch (e) {
//         _showSnackBar('Error: ${e.toString()}');
//       }
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Donor Registration',
//             style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextFormField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your name';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                     return 'Please enter a valid email';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: passwordController,
//                 obscureText: true,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your password';
//                   } else if (value.length < 6) {
//                     return 'Password must be at least 6 characters long';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               GestureDetector(
//                 onTap: () => _selectDateOfBirth(context),
//                 child: AbsorbPointer(
//                   child: TextFormField(
//                     controller: dobController,
//                     decoration: InputDecoration(
//                       labelText: 'Date of Birth',
//                       hintText: 'YYYY-MM-DD',
//                       border: OutlineInputBorder(),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please select your date of birth';
//                       }
//                       return null;
//                     },
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedBloodType,
//                 decoration: InputDecoration(
//                   labelText: 'Blood Type',
//                   border: OutlineInputBorder(),
//                 ),
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
//                     return 'Please select your blood type';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedGender,
//                 decoration: InputDecoration(
//                   labelText: 'Gender',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: genders
//                     .map((gender) =>
//                         DropdownMenuItem(value: gender, child: Text(gender)))
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedGender = value;
//                   });
//                 },
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select your gender';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: _getLiveLocation,
//                     icon: Icon(Icons.my_location),
//                     label: Text('Use Live Location'),
//                     style: ElevatedButton.styleFrom(primary: Colors.green),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _selectLocationOnMap,
//                     icon: Icon(Icons.map),
//                     label: Text('Pick on Map'),
//                     style: ElevatedButton.styleFrom(primary: Colors.blue),
//                   ),
//                 ],
//               ),
//               if (selectedLocation != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8.0),
//                   child: Text(
//                     'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
//                     style: TextStyle(color: Colors.green),
//                   ),
//                 ),
//               SizedBox(height: 20),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: _registerDonor,
//                   child: Text('Register'),
//                   style: ElevatedButton.styleFrom(
//                     primary: Colors.redAccent,
//                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                     textStyle: TextStyle(fontSize: 18),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:firebase_auth/firebase_auth.dart';

// // class DonorRegistrationPage extends StatefulWidget {
// //   @override
// //   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// // }

// // class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _firestore = FirebaseFirestore.instance;
// //   final _auth = FirebaseAuth.instance;

// //   final nameController = TextEditingController();
// //   final dobController = TextEditingController();
// //   final emailController = TextEditingController();
// //   final passwordController = TextEditingController();
// //   String? selectedBloodType;
// //   String? selectedGender;

// //   LatLng? selectedLocation;

// //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
// //   List<String> genders = ['Male', 'Female', 'Other'];

// //   /// Fetches the live location of the user
// //   void _getLiveLocation() async {
// //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// //     if (!serviceEnabled) {
// //       _showSnackBar('Location services are disabled.');
// //       return;
// //     }

// //     LocationPermission permission = await Geolocator.checkPermission();
// //     if (permission == LocationPermission.denied) {
// //       permission = await Geolocator.requestPermission();
// //       if (permission == LocationPermission.denied) {
// //         _showSnackBar('Location permissions are denied.');
// //         return;
// //       }
// //     }

// //     if (permission == LocationPermission.deniedForever) {
// //       _showSnackBar(
// //           'Location permissions are permanently denied. Enable them in settings.');
// //       return;
// //     }

// //     Position position = await Geolocator.getCurrentPosition(
// //         desiredAccuracy: LocationAccuracy.high);

// //     setState(() {
// //       selectedLocation = LatLng(position.latitude, position.longitude);
// //     });

// //     _showSnackBar('Live location selected successfully.');
// //   }

// //   /// Allows the user to pick a location on the map
// //   void _selectLocationOnMap() async {
// //     LatLng? chosenLocation = await Navigator.push(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => MapPickerScreen(),
// //       ),
// //     );

// //     if (chosenLocation != null) {
// //       setState(() {
// //         selectedLocation = chosenLocation;
// //       });

// //       _showSnackBar('Location selected on map successfully.');
// //     }
// //   }

// //   Future<bool> _isDonorUnique(String name, String dob) async {
// //     final querySnapshot = await _firestore
// //         .collection('donors')
// //         .where('name', isEqualTo: name)
// //         .where('dob', isEqualTo: dob)
// //         .get();

// //     return querySnapshot.docs.isEmpty; // True if no existing donor is found
// //   }

// //   void _selectDateOfBirth(BuildContext context) async {
// //     DateTime? pickedDate = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now(),
// //       firstDate: DateTime(1900),
// //       lastDate: DateTime.now(),
// //     );

// //     if (pickedDate != null) {
// //       setState(() {
// //         dobController.text =
// //             pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
// //       });
// //     }
// //   }

// //   void _registerDonor() async {
// //     if (_formKey.currentState!.validate()) {
// //       if (selectedLocation == null) {
// //         _showSnackBar('Please select a location (live or map).');
// //         return;
// //       }

// //       final dob = DateTime.parse(dobController.text);
// //       final age = DateTime.now().year - dob.year;
// //       if (age < 18) {
// //         _showSnackBar('Donor must be at least 18 years old.');
// //         return;
// //       }

// //       final name = nameController.text;
// //       final dobText = dobController.text;
// //       final email = emailController.text;
// //       final password = passwordController.text;

// //       // Check for unique donor
// //       if (!await _isDonorUnique(name, dobText)) {
// //         _showSnackBar('Donor with these credentials already exists.');
// //         return;
// //       }

// //       try {
// //         // Create user in Firebase Authentication
// //         UserCredential userCredential =
// //             await _auth.createUserWithEmailAndPassword(
// //           email: email,
// //           password: password,
// //         );

// //         final donorData = {
// //           'name': name,
// //           'dob': dobText,
// //           'age': age,
// //           'bloodType': selectedBloodType,
// //           'gender': selectedGender,
// //           'location':
// //               '${selectedLocation!.latitude},${selectedLocation!.longitude}',
// //           'userId': userCredential
// //               .user?.uid, // Store user ID from Firebase Authentication
// //         };

// //         // Store donor data in Firestore
// //         await _firestore.collection('donors').add(donorData);
// //         _showSnackBar('Donor registered successfully!');
// //         _formKey.currentState!.reset();
// //         nameController.clear();
// //         dobController.clear();
// //         emailController.clear();
// //         passwordController.clear();
// //         setState(() {
// //           selectedLocation = null;
// //           selectedBloodType = null;
// //           selectedGender = null;
// //         });
// //       } catch (e) {
// //         _showSnackBar('Error: ${e.toString()}');
// //       }
// //     }
// //   }

// //   void _showSnackBar(String message) {
// //     ScaffoldMessenger.of(context)
// //         .showSnackBar(SnackBar(content: Text(message)));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Donor Registration',
// //             style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
// //         backgroundColor: Colors.redAccent,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               TextFormField(
// //                 controller: nameController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Name',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Please enter your name';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               TextFormField(
// //                 controller: emailController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Email',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Please enter your email';
// //                   } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
// //                     return 'Please enter a valid email';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               TextFormField(
// //                 controller: passwordController,
// //                 obscureText: true,
// //                 decoration: InputDecoration(
// //                   labelText: 'Password',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || value.isEmpty) {
// //                     return 'Please enter your password';
// //                   } else if (value.length < 6) {
// //                     return 'Password must be at least 6 characters long';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               GestureDetector(
// //                 onTap: () => _selectDateOfBirth(context),
// //                 child: AbsorbPointer(
// //                   child: TextFormField(
// //                     controller: dobController,
// //                     decoration: InputDecoration(
// //                       labelText: 'Date of Birth',
// //                       hintText: 'YYYY-MM-DD',
// //                       border: OutlineInputBorder(),
// //                     ),
// //                     validator: (value) {
// //                       if (value == null || value.isEmpty) {
// //                         return 'Please select your date of birth';
// //                       }
// //                       return null;
// //                     },
// //                   ),
// //                 ),
// //               ),
// //               SizedBox(height: 16),
// //               DropdownButtonFormField<String>(
// //                 value: selectedBloodType,
// //                 decoration: InputDecoration(
// //                   labelText: 'Blood Type',
// //                   border: OutlineInputBorder(),
// //                 ),
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
// //                     return 'Please select your blood type';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               DropdownButtonFormField<String>(
// //                 value: selectedGender,
// //                 decoration: InputDecoration(
// //                   labelText: 'Gender',
// //                   border: OutlineInputBorder(),
// //                 ),
// //                 items: genders
// //                     .map((gender) =>
// //                         DropdownMenuItem(value: gender, child: Text(gender)))
// //                     .toList(),
// //                 onChanged: (value) {
// //                   setState(() {
// //                     selectedGender = value;
// //                   });
// //                 },
// //                 validator: (value) {
// //                   if (value == null) {
// //                     return 'Please select your gender';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 16),
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   ElevatedButton.icon(
// //                     onPressed: _getLiveLocation,
// //                     icon: Icon(Icons.my_location),
// //                     label: Text('Use Live Location'),
// //                     style: ElevatedButton.styleFrom(primary: Colors.green),
// //                   ),
// //                   ElevatedButton.icon(
// //                     onPressed: _selectLocationOnMap,
// //                     icon: Icon(Icons.map),
// //                     label: Text('Pick on Map'),
// //                     style: ElevatedButton.styleFrom(primary: Colors.blue),
// //                   ),
// //                 ],
// //               ),
// //               if (selectedLocation != null)
// //                 Padding(
// //                   padding: const EdgeInsets.only(top: 8.0),
// //                   child: Text(
// //                     'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
// //                     style: TextStyle(color: Colors.green),
// //                   ),
// //                 ),
// //               SizedBox(height: 20),
// //               Center(
// //                 child: ElevatedButton(
// //                   onPressed: _registerDonor,
// //                   child: Text('Register'),
// //                   style: ElevatedButton.styleFrom(
// //                     primary: Colors.redAccent,
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

// // class MapPickerScreen extends StatefulWidget {
// //   @override
// //   _MapPickerScreenState createState() => _MapPickerScreenState();
// // }

// // class _MapPickerScreenState extends State<MapPickerScreen> {
// //   LatLng selectedLocation =
// //       LatLng(20.5937, 78.9629); // Default location (India)

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text('Pick Location'),
// //         backgroundColor: Colors.blue,
// //       ),
// //       body: GoogleMap(
// //         initialCameraPosition: CameraPosition(
// //           target: selectedLocation,
// //           zoom: 5.0,
// //         ),
// //         onTap: (location) {
// //           setState(() {
// //             selectedLocation = location;
// //           });
// //         },
// //         markers: {
// //           Marker(
// //             markerId: MarkerId('selected'),
// //             position: selectedLocation,
// //           ),
// //         },
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: () {
// //           Navigator.pop(context, selectedLocation); // Return selected location
// //         },
// //         child: Icon(Icons.check),
// //         backgroundColor: Colors.green,
// //       ),
// //     );
// //   }
// // }


// // // import 'package:flutter/material.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // import 'package:geolocator/geolocator.dart';
// // // import 'package:google_maps_flutter/google_maps_flutter.dart';

// // // class DonorRegistrationPage extends StatefulWidget {
// // //   @override
// // //   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// // // }

// // // class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final _firestore = FirebaseFirestore.instance;

// // //   final nameController = TextEditingController();
// // //   final dobController = TextEditingController();
// // //   final emailController = TextEditingController();
// // //   final passwordController = TextEditingController();
// // //   String? selectedBloodType;
// // //   String? selectedGender;

// // //   LatLng? selectedLocation;

// // //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
// // //   List<String> genders = ['Male', 'Female', 'Other'];

// // //   /// Fetches the live location of the user
// // //   void _getLiveLocation() async {
// // //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// // //     if (!serviceEnabled) {
// // //       _showSnackBar('Location services are disabled.');
// // //       return;
// // //     }

// // //     LocationPermission permission = await Geolocator.checkPermission();
// // //     if (permission == LocationPermission.denied) {
// // //       permission = await Geolocator.requestPermission();
// // //       if (permission == LocationPermission.denied) {
// // //         _showSnackBar('Location permissions are denied.');
// // //         return;
// // //       }
// // //     }

// // //     if (permission == LocationPermission.deniedForever) {
// // //       _showSnackBar(
// // //           'Location permissions are permanently denied. Enable them in settings.');
// // //       return;
// // //     }

// // //     Position position = await Geolocator.getCurrentPosition(
// // //         desiredAccuracy: LocationAccuracy.high);

// // //     setState(() {
// // //       selectedLocation = LatLng(position.latitude, position.longitude);
// // //     });

// // //     _showSnackBar('Live location selected successfully.');
// // //   }

// // //   /// Allows the user to pick a location on the map
// // //   void _selectLocationOnMap() async {
// // //     LatLng? chosenLocation = await Navigator.push(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (context) => MapPickerScreen(),
// // //       ),
// // //     );

// // //     if (chosenLocation != null) {
// // //       setState(() {
// // //         selectedLocation = chosenLocation;
// // //       });

// // //       _showSnackBar('Location selected on map successfully.');
// // //     }
// // //   }

// // //   Future<bool> _isDonorUnique(String name, String dob) async {
// // //     final querySnapshot = await _firestore
// // //         .collection('donors')
// // //         .where('name', isEqualTo: name)
// // //         .where('dob', isEqualTo: dob)
// // //         .get();

// // //     return querySnapshot.docs.isEmpty; // True if no existing donor is found
// // //   }

// // //   void _selectDateOfBirth(BuildContext context) async {
// // //     DateTime? pickedDate = await showDatePicker(
// // //       context: context,
// // //       initialDate: DateTime.now(),
// // //       firstDate: DateTime(1900),
// // //       lastDate: DateTime.now(),
// // //     );

// // //     if (pickedDate != null) {
// // //       setState(() {
// // //         dobController.text =
// // //             pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
// // //       });
// // //     }
// // //   }

// // //   void _registerDonor() async {
// // //     if (_formKey.currentState!.validate()) {
// // //       if (selectedLocation == null) {
// // //         _showSnackBar('Please select a location (live or map).');
// // //         return;
// // //       }

// // //       final dob = DateTime.parse(dobController.text);
// // //       final age = DateTime.now().year - dob.year;
// // //       if (age < 18) {
// // //         _showSnackBar('Donor must be at least 18 years old.');
// // //         return;
// // //       }

// // //       final name = nameController.text;
// // //       final dobText = dobController.text;

// // //       // Check for unique donor
// // //       if (!await _isDonorUnique(name, dobText)) {
// // //         _showSnackBar('Donor with these credentials already exists.');
// // //         return;
// // //       }

// // //       final donorData = {
// // //         'name': name,
// // //         'dob': dobText,
// // //         'age': age,
// // //         'bloodType': selectedBloodType,
// // //         'gender': selectedGender,
// // //         'location':
// // //             '${selectedLocation!.latitude},${selectedLocation!.longitude}',
// // //       };

// // //       await _firestore.collection('donors').add(donorData);
// // //       _showSnackBar('Donor registered successfully!');
// // //       _formKey.currentState!.reset();
// // //       nameController.clear();
// // //       dobController.clear();
// // //       setState(() {
// // //         selectedLocation = null;
// // //         selectedBloodType = null;
// // //         selectedGender = null;
// // //       });
// // //     }
// // //   }

// // //   void _showSnackBar(String message) {
// // //     ScaffoldMessenger.of(context)
// // //         .showSnackBar(SnackBar(content: Text(message)));
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text('Donor Registration',
// // //             style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
// // //         backgroundColor: Colors.redAccent,
// // //       ),
// // //       body: SingleChildScrollView(
// // //         padding: const EdgeInsets.all(16.0),
// // //         child: Form(
// // //           key: _formKey,
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               TextFormField(
// // //                 controller: nameController,
// // //                 decoration: InputDecoration(
// // //                   labelText: 'Name',
// // //                   border: OutlineInputBorder(),
// // //                 ),
// // //                 validator: (value) {
// // //                   if (value == null || value.isEmpty) {
// // //                     return 'Please enter your name';
// // //                   }
// // //                   return null;
// // //                 },
// // //               ),
// // //               SizedBox(height: 16),
// // //               // Email Field
// // //               TextFormField(
// // //                 controller: emailController,
// // //                 decoration: InputDecoration(
// // //                   labelText: 'Email',
// // //                   border: OutlineInputBorder(),
// // //                 ),
// // //                 validator: (value) {
// // //                   if (value == null || value.isEmpty) {
// // //                     return 'Please enter your email';
// // //                   } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
// // //                     return 'Please enter a valid email';
// // //                   }
// // //                   return null;
// // //                 },
// // //               ),
// // //               SizedBox(height: 16),
// // //               // Password Field
// // //               TextFormField(
// // //                 controller: passwordController,
// // //                 obscureText: true,
// // //                 decoration: InputDecoration(
// // //                   labelText: 'Password',
// // //                   border: OutlineInputBorder(),
// // //                 ),
// // //                 validator: (value) {
// // //                   if (value == null || value.isEmpty) {
// // //                     return 'Please enter your password';
// // //                   } else if (value.length < 6) {
// // //                     return 'Password must be at least 6 characters long';
// // //                   }
// // //                   return null;
// // //                 },
// // //               ),
// // //               SizedBox(height: 16),
// // //               GestureDetector(
// // //                 onTap: () => _selectDateOfBirth(context),
// // //                 child: AbsorbPointer(
// // //                   child: TextFormField(
// // //                     controller: dobController,
// // //                     decoration: InputDecoration(
// // //                       labelText: 'Date of Birth',
// // //                       hintText: 'YYYY-MM-DD',
// // //                       border: OutlineInputBorder(),
// // //                     ),
// // //                     validator: (value) {
// // //                       if (value == null || value.isEmpty) {
// // //                         return 'Please select your date of birth';
// // //                       }
// // //                       return null;
// // //                     },
// // //                   ),
// // //                 ),
// // //               ),
// // //               SizedBox(height: 16),
// // //               DropdownButtonFormField<String>(
// // //                 value: selectedBloodType,
// // //                 decoration: InputDecoration(
// // //                   labelText: 'Blood Type',
// // //                   border: OutlineInputBorder(),
// // //                 ),
// // //                 items: bloodTypes
// // //                     .map((type) =>
// // //                         DropdownMenuItem(value: type, child: Text(type)))
// // //                     .toList(),
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     selectedBloodType = value;
// // //                   });
// // //                 },
// // //                 validator: (value) {
// // //                   if (value == null) {
// // //                     return 'Please select your blood type';
// // //                   }
// // //                   return null;
// // //                 },
// // //               ),
// // //               SizedBox(height: 16),
// // //               DropdownButtonFormField<String>(
// // //                 value: selectedGender,
// // //                 decoration: InputDecoration(
// // //                   labelText: 'Gender',
// // //                   border: OutlineInputBorder(),
// // //                 ),
// // //                 items: genders
// // //                     .map((gender) =>
// // //                         DropdownMenuItem(value: gender, child: Text(gender)))
// // //                     .toList(),
// // //                 onChanged: (value) {
// // //                   setState(() {
// // //                     selectedGender = value;
// // //                   });
// // //                 },
// // //                 validator: (value) {
// // //                   if (value == null) {
// // //                     return 'Please select your gender';
// // //                   }
// // //                   return null;
// // //                 },
// // //               ),
// // //               SizedBox(height: 16),
// // //               Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   ElevatedButton.icon(
// // //                     onPressed: _getLiveLocation,
// // //                     icon: Icon(Icons.my_location),
// // //                     label: Text('Use Live Location'),
// // //                     style: ElevatedButton.styleFrom(primary: Colors.green),
// // //                   ),
// // //                   ElevatedButton.icon(
// // //                     onPressed: _selectLocationOnMap,
// // //                     icon: Icon(Icons.map),
// // //                     label: Text('Pick on Map'),
// // //                     style: ElevatedButton.styleFrom(primary: Colors.blue),
// // //                   ),
// // //                 ],
// // //               ),
// // //               if (selectedLocation != null)
// // //                 Padding(
// // //                   padding: const EdgeInsets.only(top: 8.0),
// // //                   child: Text(
// // //                     'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
// // //                     style: TextStyle(color: Colors.green),
// // //                   ),
// // //                 ),
// // //               SizedBox(height: 20),
// // //               Center(
// // //                 child: ElevatedButton(
// // //                   onPressed: _registerDonor,
// // //                   child: Text('Register'),
// // //                   style: ElevatedButton.styleFrom(
// // //                     primary: Colors.redAccent,
// // //                     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class MapPickerScreen extends StatefulWidget {
// // //   @override
// // //   _MapPickerScreenState createState() => _MapPickerScreenState();
// // // }

// // // class _MapPickerScreenState extends State<MapPickerScreen> {
// // //   LatLng selectedLocation =
// // //       LatLng(20.5937, 78.9629); // Default location (India)

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: Text('Pick Location'),
// // //         backgroundColor: Colors.blue,
// // //       ),
// // //       body: GoogleMap(
// // //         initialCameraPosition: CameraPosition(
// // //           target: selectedLocation,
// // //           zoom: 5.0,
// // //         ),
// // //         onTap: (location) {
// // //           setState(() {
// // //             selectedLocation = location;
// // //           });
// // //         },
// // //         markers: {
// // //           Marker(
// // //             markerId: MarkerId('selected'),
// // //             position: selectedLocation,
// // //           ),
// // //         },
// // //       ),
// // //       floatingActionButton: FloatingActionButton(
// // //         onPressed: () {
// // //           Navigator.pop(context, selectedLocation); // Return selected location
// // //         },
// // //         child: Icon(Icons.check),
// // //         backgroundColor: Colors.green,
// // //       ),
// // //     );
// // //   }
// // // }


// // // // import 'package:flutter/material.dart';
// // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // import 'package:geolocator/geolocator.dart';
// // // // import 'package:google_maps_flutter/google_maps_flutter.dart';

// // // // class DonorRegistrationPage extends StatefulWidget {
// // // //   @override
// // // //   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// // // // }

// // // // class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
// // // //   final _formKey = GlobalKey<FormState>();
// // // //   final _firestore = FirebaseFirestore.instance;

// // // //   final nameController = TextEditingController();
// // // //   final dobController = TextEditingController();
// // // //   String? selectedBloodType;
// // // //   String? selectedGender;

// // // //   LatLng? selectedLocation;

// // // //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
// // // //   List<String> genders = ['Male', 'Female', 'Other'];

// // // //   void _getLiveLocation() async {
// // // //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// // // //     if (!serviceEnabled) {
// // // //       _showSnackBar('Location services are disabled.');
// // // //       return;
// // // //     }

// // // //     LocationPermission permission = await Geolocator.checkPermission();
// // // //     if (permission == LocationPermission.denied) {
// // // //       permission = await Geolocator.requestPermission();
// // // //       if (permission == LocationPermission.denied) {
// // // //         _showSnackBar('Location permissions are denied.');
// // // //         return;
// // // //       }
// // // //     }

// // // //     if (permission == LocationPermission.deniedForever) {
// // // //       _showSnackBar(
// // // //           'Location permissions are permanently denied. Enable them in settings.');
// // // //       return;
// // // //     }

// // // //     Position position = await Geolocator.getCurrentPosition(
// // // //         desiredAccuracy: LocationAccuracy.high);

// // // //     setState(() {
// // // //       selectedLocation = LatLng(position.latitude, position.longitude);
// // // //     });
// // // //   }

// // // //   void _selectLocationOnMap() async {
// // // //     LatLng? chosenLocation = await Navigator.push(
// // // //       context,
// // // //       MaterialPageRoute(
// // // //         builder: (context) => MapPickerScreen(),
// // // //       ),
// // // //     );

// // // //     if (chosenLocation != null) {
// // // //       setState(() {
// // // //         selectedLocation = chosenLocation;
// // // //       });
// // // //     }
// // // //   }

// // // //   Future<bool> _isDonorUnique(String name, String dob) async {
// // // //     final querySnapshot = await _firestore
// // // //         .collection('donors')
// // // //         .where('name', isEqualTo: name)
// // // //         .where('dob', isEqualTo: dob)
// // // //         .get();

// // // //     return querySnapshot.docs.isEmpty; // True if no existing donor is found
// // // //   }

// // // //   void _selectDateOfBirth(BuildContext context) async {
// // // //     DateTime? pickedDate = await showDatePicker(
// // // //       context: context,
// // // //       initialDate: DateTime.now(),
// // // //       firstDate: DateTime(1900),
// // // //       lastDate: DateTime.now(),
// // // //     );

// // // //     if (pickedDate != null) {
// // // //       setState(() {
// // // //         dobController.text =
// // // //             pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
// // // //       });
// // // //     }
// // // //   }

// // // //   void _registerDonor() async {
// // // //     if (_formKey.currentState!.validate()) {
// // // //       if (selectedLocation == null) {
// // // //         _showSnackBar('Please provide your location.');
// // // //         return;
// // // //       }

// // // //       final dob = DateTime.parse(dobController.text);
// // // //       final age = DateTime.now().year - dob.year;
// // // //       if (age < 18) {
// // // //         _showSnackBar('Donor must be at least 18 years old.');
// // // //         return;
// // // //       }

// // // //       final name = nameController.text;
// // // //       final dobText = dobController.text;

// // // //       // Check for unique donor
// // // //       if (!await _isDonorUnique(name, dobText)) {
// // // //         _showSnackBar('Donor with these credentials already exists.');
// // // //         return;
// // // //       }

// // // //       final donorData = {
// // // //         'name': name,
// // // //         'dob': dobText,
// // // //         'age': age,
// // // //         'bloodType': selectedBloodType,
// // // //         'gender': selectedGender,
// // // //         'location':
// // // //             '${selectedLocation!.latitude},${selectedLocation!.longitude}',
// // // //       };

// // // //       await _firestore.collection('donors').add(donorData);
// // // //       _showSnackBar('Donor registered successfully!');
// // // //       _formKey.currentState!.reset();
// // // //       nameController.clear();
// // // //       dobController.clear();
// // // //       setState(() {
// // // //         selectedLocation = null;
// // // //         selectedBloodType = null;
// // // //         selectedGender = null;
// // // //       });
// // // //     }
// // // //   }

// // // //   void _showSnackBar(String message) {
// // // //     ScaffoldMessenger.of(context)
// // // //         .showSnackBar(SnackBar(content: Text(message)));
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Text('Donor Registration',
// // // //             style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
// // // //         backgroundColor: Colors.redAccent,
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         padding: const EdgeInsets.all(16.0),
// // // //         child: Form(
// // // //           key: _formKey,
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               TextFormField(
// // // //                 controller: nameController,
// // // //                 decoration: InputDecoration(
// // // //                   labelText: 'Name',
// // // //                   border: OutlineInputBorder(),
// // // //                 ),
// // // //                 validator: (value) {
// // // //                   if (value == null || value.isEmpty) {
// // // //                     return 'Please enter your name';
// // // //                   }
// // // //                   return null;
// // // //                 },
// // // //               ),
// // // //               SizedBox(height: 16),
// // // //               GestureDetector(
// // // //                 onTap: () => _selectDateOfBirth(context),
// // // //                 child: AbsorbPointer(
// // // //                   child: TextFormField(
// // // //                     controller: dobController,
// // // //                     decoration: InputDecoration(
// // // //                       labelText: 'Date of Birth',
// // // //                       hintText: 'YYYY-MM-DD',
// // // //                       border: OutlineInputBorder(),
// // // //                     ),
// // // //                     validator: (value) {
// // // //                       if (value == null || value.isEmpty) {
// // // //                         return 'Please select your date of birth';
// // // //                       }
// // // //                       return null;
// // // //                     },
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: 16),
// // // //               DropdownButtonFormField<String>(
// // // //                 value: selectedBloodType,
// // // //                 decoration: InputDecoration(
// // // //                   labelText: 'Blood Type',
// // // //                   border: OutlineInputBorder(),
// // // //                 ),
// // // //                 items: bloodTypes
// // // //                     .map((type) =>
// // // //                         DropdownMenuItem(value: type, child: Text(type)))
// // // //                     .toList(),
// // // //                 onChanged: (value) {
// // // //                   setState(() {
// // // //                     selectedBloodType = value;
// // // //                   });
// // // //                 },
// // // //                 validator: (value) {
// // // //                   if (value == null) {
// // // //                     return 'Please select your blood type';
// // // //                   }
// // // //                   return null;
// // // //                 },
// // // //               ),
// // // //               SizedBox(height: 16),
// // // //               DropdownButtonFormField<String>(
// // // //                 value: selectedGender,
// // // //                 decoration: InputDecoration(
// // // //                   labelText: 'Gender',
// // // //                   border: OutlineInputBorder(),
// // // //                 ),
// // // //                 items: genders
// // // //                     .map((gender) =>
// // // //                         DropdownMenuItem(value: gender, child: Text(gender)))
// // // //                     .toList(),
// // // //                 onChanged: (value) {
// // // //                   setState(() {
// // // //                     selectedGender = value;
// // // //                   });
// // // //                 },
// // // //                 validator: (value) {
// // // //                   if (value == null) {
// // // //                     return 'Please select your gender';
// // // //                   }
// // // //                   return null;
// // // //                 },
// // // //               ),
// // // //               SizedBox(height: 16),
// // // //               Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                 children: [
// // // //                   ElevatedButton.icon(
// // // //                     onPressed: _getLiveLocation,
// // // //                     icon: Icon(Icons.my_location),
// // // //                     label: Text('Use Live Location',
// // // //                         style: TextStyle(
// // // //                             color: const Color.fromARGB(255, 237, 243, 238))),
// // // //                     style: ElevatedButton.styleFrom(primary: Colors.green),
// // // //                   ),
// // // //                   ElevatedButton.icon(
// // // //                     onPressed: _selectLocationOnMap,
// // // //                     icon: Icon(Icons.map),
// // // //                     label: Text('Pick on Map',
// // // //                         style: TextStyle(
// // // //                             color: const Color.fromARGB(255, 237, 243, 238))),
// // // //                     style: ElevatedButton.styleFrom(primary: Colors.blue),
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //               if (selectedLocation != null)
// // // //                 Padding(
// // // //                   padding: const EdgeInsets.only(top: 8.0),
// // // //                   child: Text(
// // // //                     'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
// // // //                     style: TextStyle(color: Colors.green),
// // // //                   ),
// // // //                 ),
// // // //               SizedBox(height: 20),
// // // //               Center(
// // // //                 child: ElevatedButton(
// // // //                   onPressed: _registerDonor,
// // // //                   child: Text('Register',
// // // //                       style: TextStyle(
// // // //                           color: const Color.fromARGB(255, 237, 243, 238))),
// // // //                   style: ElevatedButton.styleFrom(
// // // //                     primary: Colors.redAccent,
// // // //                     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class MapPickerScreen extends StatefulWidget {
// // // //   @override
// // // //   _MapPickerScreenState createState() => _MapPickerScreenState();
// // // // }

// // // // class _MapPickerScreenState extends State<MapPickerScreen> {
// // // //   LatLng selectedLocation =
// // // //       LatLng(20.5937, 78.9629); // Default location (India)

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(
// // // //         title: Text('Pick Location',
// // // //             style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
// // // //         backgroundColor: Colors.blue,
// // // //       ),
// // // //       body: GoogleMap(
// // // //         initialCameraPosition: CameraPosition(
// // // //           target: selectedLocation,
// // // //           zoom: 5.0,
// // // //         ),
// // // //         onTap: (location) {
// // // //           setState(() {
// // // //             selectedLocation = location;
// // // //           });
// // // //         },
// // // //         markers: {
// // // //           Marker(
// // // //             markerId: MarkerId('selected'),
// // // //             position: selectedLocation,
// // // //           ),
// // // //         },
// // // //       ),
// // // //       floatingActionButton: FloatingActionButton(
// // // //         onPressed: () {
// // // //           Navigator.pop(context, selectedLocation); // Return selected location
// // // //         },
// // // //         child: Icon(Icons.check),
// // // //         backgroundColor: Colors.green,
// // // //       ),
// // // //     );
// // // //   }
// // // // }



// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // // import 'package:geolocator/geolocator.dart';
// // // // // import 'package:google_maps_flutter/google_maps_flutter.dart';

// // // // // class DonorRegistrationPage extends StatefulWidget {
// // // // //   @override
// // // // //   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// // // // // }

// // // // // class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
// // // // //   final _formKey = GlobalKey<FormState>();
// // // // //   final _firestore = FirebaseFirestore.instance;

// // // // //   final nameController = TextEditingController();
// // // // //   final dobController = TextEditingController();
// // // // //   String? selectedBloodType;
// // // // //   String? selectedGender;

// // // // //   LatLng? selectedLocation;

// // // // //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
// // // // //   List<String> genders = ['Male', 'Female', 'Other'];

// // // // //   void _getLiveLocation() async {
// // // // //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// // // // //     if (!serviceEnabled) {
// // // // //       _showSnackBar('Location services are disabled.');
// // // // //       return;
// // // // //     }

// // // // //     LocationPermission permission = await Geolocator.checkPermission();
// // // // //     if (permission == LocationPermission.denied) {
// // // // //       permission = await Geolocator.requestPermission();
// // // // //       if (permission == LocationPermission.denied) {
// // // // //         _showSnackBar('Location permissions are denied.');
// // // // //         return;
// // // // //       }
// // // // //     }

// // // // //     if (permission == LocationPermission.deniedForever) {
// // // // //       _showSnackBar(
// // // // //           'Location permissions are permanently denied. Enable them in settings.');
// // // // //       return;
// // // // //     }

// // // // //     Position position = await Geolocator.getCurrentPosition(
// // // // //         desiredAccuracy: LocationAccuracy.high);

// // // // //     setState(() {
// // // // //       selectedLocation = LatLng(position.latitude, position.longitude);
// // // // //     });
// // // // //   }

// // // // //   void _selectLocationOnMap() async {
// // // // //     LatLng? chosenLocation = await Navigator.push(
// // // // //       context,
// // // // //       MaterialPageRoute(
// // // // //         builder: (context) => MapPickerScreen(),
// // // // //       ),
// // // // //     );

// // // // //     if (chosenLocation != null) {
// // // // //       setState(() {
// // // // //         selectedLocation = chosenLocation;
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _selectDateOfBirth(BuildContext context) async {
// // // // //     DateTime? pickedDate = await showDatePicker(
// // // // //       context: context,
// // // // //       initialDate: DateTime.now(),
// // // // //       firstDate: DateTime(1900),
// // // // //       lastDate: DateTime.now(),
// // // // //     );

// // // // //     if (pickedDate != null) {
// // // // //       setState(() {
// // // // //         dobController.text =
// // // // //             pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
// // // // //       });
// // // // //     }
// // // // //   }

// // // // //   void _registerDonor() async {
// // // // //     if (_formKey.currentState!.validate()) {
// // // // //       if (selectedLocation == null) {
// // // // //         _showSnackBar('Please provide your location.');
// // // // //         return;
// // // // //       }

// // // // //       final dob = DateTime.parse(dobController.text);
// // // // //       final age = DateTime.now().year - dob.year;
// // // // //       if (age < 18) {
// // // // //         _showSnackBar('Donor must be at least 18 years old.');
// // // // //         return;
// // // // //       }

// // // // //       final donorData = {
// // // // //         'name': nameController.text,
// // // // //         'dob': dobController.text,
// // // // //         'age': age,
// // // // //         'bloodType': selectedBloodType,
// // // // //         'gender': selectedGender,
// // // // //         'location':
// // // // //             '${selectedLocation!.latitude},${selectedLocation!.longitude}',
// // // // //       };

// // // // //       await _firestore.collection('donors').add(donorData);
// // // // //       _showSnackBar('Donor registered successfully!');
// // // // //     }
// // // // //   }

// // // // //   void _showSnackBar(String message) {
// // // // //     ScaffoldMessenger.of(context)
// // // // //         .showSnackBar(SnackBar(content: Text(message)));
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         title: Text('Donor Registration',
// // // // //             style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238))),
// // // // //         backgroundColor: const Color.fromARGB(255, 214, 85, 76),
// // // // //       ),
// // // // //       body: SingleChildScrollView(
// // // // //         padding: const EdgeInsets.all(16.0),
// // // // //         child: Form(
// // // // //           key: _formKey,
// // // // //           child: Column(
// // // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // // //             children: [
// // // // //               TextFormField(
// // // // //                 controller: nameController,
// // // // //                 decoration: InputDecoration(
// // // // //                   labelText: 'Name',
// // // // //                   border: OutlineInputBorder(),
// // // // //                 ),
// // // // //                 validator: (value) {
// // // // //                   if (value == null || value.isEmpty) {
// // // // //                     return 'Please enter your name';
// // // // //                   }
// // // // //                   return null;
// // // // //                 },
// // // // //               ),
// // // // //               SizedBox(height: 16),
// // // // //               GestureDetector(
// // // // //                 onTap: () => _selectDateOfBirth(context),
// // // // //                 child: AbsorbPointer(
// // // // //                   child: TextFormField(
// // // // //                     controller: dobController,
// // // // //                     decoration: InputDecoration(
// // // // //                       labelText: 'Date of Birth',
// // // // //                       hintText: 'YYYY-MM-DD',
// // // // //                       border: OutlineInputBorder(),
// // // // //                     ),
// // // // //                     validator: (value) {
// // // // //                       if (value == null || value.isEmpty) {
// // // // //                         return 'Please select your date of birth';
// // // // //                       }
// // // // //                       return null;
// // // // //                     },
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //               SizedBox(height: 16),
// // // // //               DropdownButtonFormField<String>(
// // // // //                 value: selectedBloodType,
// // // // //                 decoration: InputDecoration(
// // // // //                   labelText: 'Blood Type',
// // // // //                   border: OutlineInputBorder(),
// // // // //                 ),
// // // // //                 items: bloodTypes
// // // // //                     .map((type) =>
// // // // //                         DropdownMenuItem(value: type, child: Text(type)))
// // // // //                     .toList(),
// // // // //                 onChanged: (value) {
// // // // //                   setState(() {
// // // // //                     selectedBloodType = value;
// // // // //                   });
// // // // //                 },
// // // // //                 validator: (value) {
// // // // //                   if (value == null) {
// // // // //                     return 'Please select your blood type';
// // // // //                   }
// // // // //                   return null;
// // // // //                 },
// // // // //               ),
// // // // //               SizedBox(height: 16),
// // // // //               DropdownButtonFormField<String>(
// // // // //                 value: selectedGender,
// // // // //                 decoration: InputDecoration(
// // // // //                   labelText: 'Gender',
// // // // //                   border: OutlineInputBorder(),
// // // // //                 ),
// // // // //                 items: genders
// // // // //                     .map((gender) =>
// // // // //                         DropdownMenuItem(value: gender, child: Text(gender)))
// // // // //                     .toList(),
// // // // //                 onChanged: (value) {
// // // // //                   setState(() {
// // // // //                     selectedGender = value;
// // // // //                   });
// // // // //                 },
// // // // //                 validator: (value) {
// // // // //                   if (value == null) {
// // // // //                     return 'Please select your gender';
// // // // //                   }
// // // // //                   return null;
// // // // //                 },
// // // // //               ),
// // // // //               SizedBox(height: 16),
// // // // //               Row(
// // // // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // // //                 children: [
// // // // //                   ElevatedButton.icon(
// // // // //                     onPressed: _getLiveLocation,
// // // // //                     icon: Icon(Icons.my_location),
// // // // //                     label: Text('Use Live Location',
// // // // //                         style: TextStyle(
// // // // //                             color: const Color.fromARGB(255, 237, 243, 238))),
// // // // //                     style: ElevatedButton.styleFrom(primary: Colors.green),
// // // // //                   ),
// // // // //                   ElevatedButton.icon(
// // // // //                     onPressed: _selectLocationOnMap,
// // // // //                     icon: Icon(Icons.map),
// // // // //                     label: Text('Pick on Map',
// // // // //                         style: TextStyle(
// // // // //                             color: const Color.fromARGB(255, 237, 243, 238))),
// // // // //                     style: ElevatedButton.styleFrom(primary: Colors.blue),
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //               if (selectedLocation != null)
// // // // //                 Padding(
// // // // //                   padding: const EdgeInsets.only(top: 8.0),
// // // // //                   child: Text(
// // // // //                     'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
// // // // //                     style: TextStyle(color: Colors.green),
// // // // //                   ),
// // // // //                 ),
// // // // //               SizedBox(height: 20),
// // // // //               Center(
// // // // //                 child: ElevatedButton(
// // // // //                   onPressed: _registerDonor,
// // // // //                   child: Text(
// // // // //                     'Register',
// // // // //                     style: TextStyle(
// // // // //                         color: const Color.fromARGB(255, 237, 243, 238)),
// // // // //                   ),
// // // // //                   style: ElevatedButton.styleFrom(
// // // // //                     primary: Colors.redAccent,
// // // // //                     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
// // // // //                   ),
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class MapPickerScreen extends StatefulWidget {
// // // // //   @override
// // // // //   _MapPickerScreenState createState() => _MapPickerScreenState();
// // // // // }

// // // // // class _MapPickerScreenState extends State<MapPickerScreen> {
// // // // //   LatLng selectedLocation =
// // // // //       LatLng(20.5937, 78.9629); // Default location (India)

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       appBar: AppBar(
// // // // //         title: Text('Pick Location'),
// // // // //         backgroundColor: Colors.blue,
// // // // //       ),
// // // // //       body: GoogleMap(
// // // // //         initialCameraPosition: CameraPosition(
// // // // //           target: selectedLocation,
// // // // //           zoom: 5.0,
// // // // //         ),
// // // // //         onTap: (location) {
// // // // //           setState(() {
// // // // //             selectedLocation = location;
// // // // //           });
// // // // //         },
// // // // //         markers: {
// // // // //           Marker(
// // // // //             markerId: MarkerId('selected'),
// // // // //             position: selectedLocation,
// // // // //           ),
// // // // //         },
// // // // //       ),
// // // // //       floatingActionButton: FloatingActionButton(
// // // // //         onPressed: () {
// // // // //           Navigator.pop(context, selectedLocation); // Return selected location
// // // // //         },
// // // // //         child: Icon(Icons.check),
// // // // //         backgroundColor: Colors.green,
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }



// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // // // import 'package:geolocator/geolocator.dart';
// // // // // // import 'package:google_maps_flutter/google_maps_flutter.dart';

// // // // // // class DonorRegistrationPage extends StatefulWidget {
// // // // // //   @override
// // // // // //   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// // // // // // }

// // // // // // class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
// // // // // //   final _formKey = GlobalKey<FormState>();
// // // // // //   final _firestore = FirebaseFirestore.instance;

// // // // // //   final nameController = TextEditingController();
// // // // // //   final dobController = TextEditingController();
// // // // // //   String? selectedBloodType;
// // // // // //   String? selectedGender;

// // // // // //   LatLng? selectedLocation;

// // // // // //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
// // // // // //   List<String> genders = ['Male', 'Female', 'Other'];

// // // // // //   void _getLiveLocation() async {
// // // // // //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// // // // // //     if (!serviceEnabled) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text('Location services are disabled.')),
// // // // // //       );
// // // // // //       return;
// // // // // //     }

// // // // // //     LocationPermission permission = await Geolocator.checkPermission();
// // // // // //     if (permission == LocationPermission.denied) {
// // // // // //       permission = await Geolocator.requestPermission();
// // // // // //       if (permission == LocationPermission.denied) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(content: Text('Location permissions are denied.')),
// // // // // //         );
// // // // // //         return;
// // // // // //       }
// // // // // //     }

// // // // // //     if (permission == LocationPermission.deniedForever) {
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(
// // // // // //             content: Text(
// // // // // //                 'Location permissions are permanently denied. Please enable them in settings.')),
// // // // // //       );
// // // // // //       return;
// // // // // //     }

// // // // // //     Position position = await Geolocator.getCurrentPosition(
// // // // // //         desiredAccuracy: LocationAccuracy.high);

// // // // // //     setState(() {
// // // // // //       selectedLocation = LatLng(position.latitude, position.longitude);
// // // // // //     });
// // // // // //   }

// // // // // //   void _selectLocationOnMap() async {
// // // // // //     LatLng? chosenLocation = await Navigator.push(
// // // // // //       context,
// // // // // //       MaterialPageRoute(
// // // // // //         builder: (context) => MapPickerScreen(),
// // // // // //       ),
// // // // // //     );

// // // // // //     if (chosenLocation != null) {
// // // // // //       setState(() {
// // // // // //         selectedLocation = chosenLocation;
// // // // // //       });
// // // // // //     }
// // // // // //   }

// // // // // //   void _selectDateOfBirth(BuildContext context) async {
// // // // // //     DateTime? pickedDate = await showDatePicker(
// // // // // //       context: context,
// // // // // //       initialDate: DateTime.now(),
// // // // // //       firstDate: DateTime(1900),
// // // // // //       lastDate: DateTime.now(),
// // // // // //     );

// // // // // //     if (pickedDate != null) {
// // // // // //       setState(() {
// // // // // //         dobController.text =
// // // // // //             pickedDate.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
// // // // // //       });
// // // // // //     }
// // // // // //   }

// // // // // //   void _registerDonor() async {
// // // // // //     if (_formKey.currentState!.validate()) {
// // // // // //       if (selectedLocation == null) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(content: Text('Please provide your location.')),
// // // // // //         );
// // // // // //         return;
// // // // // //       }

// // // // // //       final dob = DateTime.parse(dobController.text);
// // // // // //       final age = DateTime.now().year - dob.year;
// // // // // //       if (age < 18) {
// // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // //           SnackBar(content: Text('Donor must be at least 18 years old.')),
// // // // // //         );
// // // // // //         return;
// // // // // //       }

// // // // // //       final donorData = {
// // // // // //         'name': nameController.text,
// // // // // //         'dob': dobController.text,
// // // // // //         'age': age,
// // // // // //         'bloodType': selectedBloodType,
// // // // // //         'gender': selectedGender,
// // // // // //         'location':
// // // // // //             '${selectedLocation!.latitude},${selectedLocation!.longitude}',
// // // // // //       };

// // // // // //       await _firestore.collection('donors').add(donorData);
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         SnackBar(content: Text('Donor registered successfully!')),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(title: Text('Donor Registration')),
// // // // // //       body: Padding(
// // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // //         child: Form(
// // // // // //           key: _formKey,
// // // // // //           child: ListView(
// // // // // //             children: [
// // // // // //               TextFormField(
// // // // // //                 controller: nameController,
// // // // // //                 decoration: InputDecoration(labelText: 'Name'),
// // // // // //                 validator: (value) {
// // // // // //                   if (value == null || value.isEmpty) {
// // // // // //                     return 'Please enter your name';
// // // // // //                   }
// // // // // //                   return null;
// // // // // //                 },
// // // // // //               ),
// // // // // //               GestureDetector(
// // // // // //                 onTap: () => _selectDateOfBirth(context),
// // // // // //                 child: AbsorbPointer(
// // // // // //                   child: TextFormField(
// // // // // //                     controller: dobController,
// // // // // //                     decoration: InputDecoration(
// // // // // //                       labelText: 'Date of Birth',
// // // // // //                       hintText: 'YYYY-MM-DD',
// // // // // //                     ),
// // // // // //                     validator: (value) {
// // // // // //                       if (value == null || value.isEmpty) {
// // // // // //                         return 'Please select your date of birth';
// // // // // //                       }
// // // // // //                       return null;
// // // // // //                     },
// // // // // //                   ),
// // // // // //                 ),
// // // // // //               ),
// // // // // //               DropdownButtonFormField<String>(
// // // // // //                 value: selectedBloodType,
// // // // // //                 decoration: InputDecoration(labelText: 'Blood Type'),
// // // // // //                 items: bloodTypes
// // // // // //                     .map((type) =>
// // // // // //                         DropdownMenuItem(value: type, child: Text(type)))
// // // // // //                     .toList(),
// // // // // //                 onChanged: (value) {
// // // // // //                   setState(() {
// // // // // //                     selectedBloodType = value;
// // // // // //                   });
// // // // // //                 },
// // // // // //                 validator: (value) {
// // // // // //                   if (value == null) {
// // // // // //                     return 'Please select your blood type';
// // // // // //                   }
// // // // // //                   return null;
// // // // // //                 },
// // // // // //               ),
// // // // // //               DropdownButtonFormField<String>(
// // // // // //                 value: selectedGender,
// // // // // //                 decoration: InputDecoration(labelText: 'Gender'),
// // // // // //                 items: genders
// // // // // //                     .map((gender) =>
// // // // // //                         DropdownMenuItem(value: gender, child: Text(gender)))
// // // // // //                     .toList(),
// // // // // //                 onChanged: (value) {
// // // // // //                   setState(() {
// // // // // //                     selectedGender = value;
// // // // // //                   });
// // // // // //                 },
// // // // // //                 validator: (value) {
// // // // // //                   if (value == null) {
// // // // // //                     return 'Please select your gender';
// // // // // //                   }
// // // // // //                   return null;
// // // // // //                 },
// // // // // //               ),
// // // // // //               SizedBox(height: 20),
// // // // // //               ElevatedButton.icon(
// // // // // //                 onPressed: _getLiveLocation,
// // // // // //                 icon: Icon(Icons.my_location),
// // // // // //                 label: Text('Use Live Location'),
// // // // // //               ),
// // // // // //               ElevatedButton.icon(
// // // // // //                 onPressed: _selectLocationOnMap,
// // // // // //                 icon: Icon(Icons.map),
// // // // // //                 label: Text('Pick Location on Map'),
// // // // // //               ),
// // // // // //               if (selectedLocation != null)
// // // // // //                 Text(
// // // // // //                   'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
// // // // // //                   style: TextStyle(color: Colors.green),
// // // // // //                 ),
// // // // // //               SizedBox(height: 20),
// // // // // //               ElevatedButton(
// // // // // //                 onPressed: _registerDonor,
// // // // // //                 child: Text('Register'),
// // // // // //               ),
// // // // // //             ],
// // // // // //           ),
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // class MapPickerScreen extends StatefulWidget {
// // // // // //   @override
// // // // // //   _MapPickerScreenState createState() => _MapPickerScreenState();
// // // // // // }

// // // // // // class _MapPickerScreenState extends State<MapPickerScreen> {
// // // // // //   LatLng selectedLocation =
// // // // // //       LatLng(20.5937, 78.9629); // Default location (India)

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     return Scaffold(
// // // // // //       appBar: AppBar(title: Text('Pick Location')),
// // // // // //       body: GoogleMap(
// // // // // //         initialCameraPosition: CameraPosition(
// // // // // //           target: selectedLocation,
// // // // // //           zoom: 5.0,
// // // // // //         ),
// // // // // //         onTap: (location) {
// // // // // //           setState(() {
// // // // // //             selectedLocation = location;
// // // // // //           });
// // // // // //         },
// // // // // //         markers: {
// // // // // //           Marker(
// // // // // //             markerId: MarkerId('selected'),
// // // // // //             position: selectedLocation,
// // // // // //           ),
// // // // // //         },
// // // // // //       ),
// // // // // //       floatingActionButton: FloatingActionButton(
// // // // // //         onPressed: () {
// // // // // //           Navigator.pop(context, selectedLocation); // Return selected location
// // // // // //         },
// // // // // //         child: Icon(Icons.check),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }


// // // // // // ///Correct Code only updating the input time calender for Date of birth 

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:cloud_firestore/cloud_firestore.dart';
// // // // // // // import 'package:geolocator/geolocator.dart';
// // // // // // // import 'package:google_maps_flutter/google_maps_flutter.dart';

// // // // // // // class DonorRegistrationPage extends StatefulWidget {
// // // // // // //   @override
// // // // // // //   _DonorRegistrationPageState createState() => _DonorRegistrationPageState();
// // // // // // // }

// // // // // // // class _DonorRegistrationPageState extends State<DonorRegistrationPage> {
// // // // // // //   final _formKey = GlobalKey<FormState>();
// // // // // // //   final _firestore = FirebaseFirestore.instance;

// // // // // // //   final nameController = TextEditingController();
// // // // // // //   final dobController = TextEditingController();
// // // // // // //   String? selectedBloodType;
// // // // // // //   String? selectedGender;

// // // // // // //   LatLng? selectedLocation;

// // // // // // //   List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
// // // // // // //   List<String> genders = ['Male', 'Female', 'Other'];

// // // // // // //   void _getLiveLocation() async {
// // // // // // //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
// // // // // // //     if (!serviceEnabled) {
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(content: Text('Location services are disabled.')),
// // // // // // //       );
// // // // // // //       return;
// // // // // // //     }

// // // // // // //     LocationPermission permission = await Geolocator.checkPermission();
// // // // // // //     if (permission == LocationPermission.denied) {
// // // // // // //       permission = await Geolocator.requestPermission();
// // // // // // //       if (permission == LocationPermission.denied) {
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           SnackBar(content: Text('Location permissions are denied.')),
// // // // // // //         );
// // // // // // //         return;
// // // // // // //       }
// // // // // // //     }

// // // // // // //     if (permission == LocationPermission.deniedForever) {
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(
// // // // // // //             content: Text(
// // // // // // //                 'Location permissions are permanently denied. Please enable them in settings.')),
// // // // // // //       );
// // // // // // //       return;
// // // // // // //     }

// // // // // // //     Position position = await Geolocator.getCurrentPosition(
// // // // // // //         desiredAccuracy: LocationAccuracy.high);

// // // // // // //     setState(() {
// // // // // // //       selectedLocation = LatLng(position.latitude, position.longitude);
// // // // // // //     });
// // // // // // //   }

// // // // // // //   void _selectLocationOnMap() async {
// // // // // // //     LatLng? chosenLocation = await Navigator.push(
// // // // // // //       context,
// // // // // // //       MaterialPageRoute(
// // // // // // //         builder: (context) => MapPickerScreen(),
// // // // // // //       ),
// // // // // // //     );

// // // // // // //     if (chosenLocation != null) {
// // // // // // //       setState(() {
// // // // // // //         selectedLocation = chosenLocation;
// // // // // // //       });
// // // // // // //     }
// // // // // // //   }

// // // // // // //   void _registerDonor() async {
// // // // // // //     if (_formKey.currentState!.validate()) {
// // // // // // //       if (selectedLocation == null) {
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           SnackBar(content: Text('Please provide your location.')),
// // // // // // //         );
// // // // // // //         return;
// // // // // // //       }

// // // // // // //       final dob = DateTime.parse(dobController.text);
// // // // // // //       final age = DateTime.now().year - dob.year;
// // // // // // //       if (age < 18) {
// // // // // // //         ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //           SnackBar(content: Text('Donor must be at least 18 years old.')),
// // // // // // //         );
// // // // // // //         return;
// // // // // // //       }

// // // // // // //       final donorData = {
// // // // // // //         'name': nameController.text,
// // // // // // //         'dob': dobController.text,
// // // // // // //         'age': age,
// // // // // // //         'bloodType': selectedBloodType,
// // // // // // //         'gender': selectedGender,
// // // // // // //         'location':
// // // // // // //             '${selectedLocation!.latitude},${selectedLocation!.longitude}',
// // // // // // //       };

// // // // // // //       await _firestore.collection('donors').add(donorData);
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         SnackBar(content: Text('Donor registered successfully!')),
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Scaffold(
// // // // // // //       appBar: AppBar(title: Text('Donor Registration')),
// // // // // // //       body: Padding(
// // // // // // //         padding: const EdgeInsets.all(16.0),
// // // // // // //         child: Form(
// // // // // // //           key: _formKey,
// // // // // // //           child: ListView(
// // // // // // //             children: [
// // // // // // //               TextFormField(
// // // // // // //                 controller: nameController,
// // // // // // //                 decoration: InputDecoration(labelText: 'Name'),
// // // // // // //                 validator: (value) {
// // // // // // //                   if (value == null || value.isEmpty) {
// // // // // // //                     return 'Please enter your name';
// // // // // // //                   }
// // // // // // //                   return null;
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //               TextFormField(
// // // // // // //                 controller: dobController,
// // // // // // //                 decoration: InputDecoration(
// // // // // // //                   labelText: 'Date of Birth',
// // // // // // //                   hintText: 'YYYY-MM-DD',
// // // // // // //                 ),
// // // // // // //                 keyboardType: TextInputType.datetime,
// // // // // // //                 validator: (value) {
// // // // // // //                   if (value == null ||
// // // // // // //                       value.isEmpty ||
// // // // // // //                       !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
// // // // // // //                     return 'Please enter a valid date (YYYY-MM-DD)';
// // // // // // //                   }
// // // // // // //                   return null;
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //               DropdownButtonFormField<String>(
// // // // // // //                 value: selectedBloodType,
// // // // // // //                 decoration: InputDecoration(labelText: 'Blood Type'),
// // // // // // //                 items: bloodTypes
// // // // // // //                     .map((type) =>
// // // // // // //                         DropdownMenuItem(value: type, child: Text(type)))
// // // // // // //                     .toList(),
// // // // // // //                 onChanged: (value) {
// // // // // // //                   setState(() {
// // // // // // //                     selectedBloodType = value;
// // // // // // //                   });
// // // // // // //                 },
// // // // // // //                 validator: (value) {
// // // // // // //                   if (value == null) {
// // // // // // //                     return 'Please select your blood type';
// // // // // // //                   }
// // // // // // //                   return null;
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //               DropdownButtonFormField<String>(
// // // // // // //                 value: selectedGender,
// // // // // // //                 decoration: InputDecoration(labelText: 'Gender'),
// // // // // // //                 items: genders
// // // // // // //                     .map((gender) =>
// // // // // // //                         DropdownMenuItem(value: gender, child: Text(gender)))
// // // // // // //                     .toList(),
// // // // // // //                 onChanged: (value) {
// // // // // // //                   setState(() {
// // // // // // //                     selectedGender = value;
// // // // // // //                   });
// // // // // // //                 },
// // // // // // //                 validator: (value) {
// // // // // // //                   if (value == null) {
// // // // // // //                     return 'Please select your gender';
// // // // // // //                   }
// // // // // // //                   return null;
// // // // // // //                 },
// // // // // // //               ),
// // // // // // //               SizedBox(height: 20),
// // // // // // //               ElevatedButton.icon(
// // // // // // //                 onPressed: _getLiveLocation,
// // // // // // //                 icon: Icon(Icons.my_location),
// // // // // // //                 label: Text('Use Live Location'),
// // // // // // //               ),
// // // // // // //               ElevatedButton.icon(
// // // // // // //                 onPressed: _selectLocationOnMap,
// // // // // // //                 icon: Icon(Icons.map),
// // // // // // //                 label: Text('Pick Location on Map'),
// // // // // // //               ),
// // // // // // //               if (selectedLocation != null)
// // // // // // //                 Text(
// // // // // // //                   'Selected Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}',
// // // // // // //                   style: TextStyle(color: Colors.green),
// // // // // // //                 ),
// // // // // // //               SizedBox(height: 20),
// // // // // // //               ElevatedButton(
// // // // // // //                 onPressed: _registerDonor,
// // // // // // //                 child: Text('Register'),
// // // // // // //               ),
// // // // // // //             ],
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // class MapPickerScreen extends StatefulWidget {
// // // // // // //   @override
// // // // // // //   _MapPickerScreenState createState() => _MapPickerScreenState();
// // // // // // // }

// // // // // // // class _MapPickerScreenState extends State<MapPickerScreen> {
// // // // // // //   LatLng selectedLocation =
// // // // // // //       LatLng(20.5937, 78.9629); // Default location (India)

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     return Scaffold(
// // // // // // //       appBar: AppBar(title: Text('Pick Location')),
// // // // // // //       body: GoogleMap(
// // // // // // //         initialCameraPosition: CameraPosition(
// // // // // // //           target: selectedLocation,
// // // // // // //           zoom: 5.0,
// // // // // // //         ),
// // // // // // //         onTap: (location) {
// // // // // // //           setState(() {
// // // // // // //             selectedLocation = location;
// // // // // // //           });
// // // // // // //         },
// // // // // // //         markers: {
// // // // // // //           Marker(
// // // // // // //             markerId: MarkerId('selected'),
// // // // // // //             position: selectedLocation,
// // // // // // //           ),
// // // // // // //         },
// // // // // // //       ),
// // // // // // //       floatingActionButton: FloatingActionButton(
// // // // // // //         onPressed: () {
// // // // // // //           Navigator.pop(context, selectedLocation); // Return selected location
// // // // // // //         },
// // // // // // //         child: Icon(Icons.check),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }
