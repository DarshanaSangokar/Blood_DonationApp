import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DonorWisherRegistrationPage extends StatefulWidget {
  @override
  _DonorWisherRegistrationPageState createState() =>
      _DonorWisherRegistrationPageState();
}

class _DonorWisherRegistrationPageState
    extends State<DonorWisherRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String? bloodType;
  String? gender;
  DateTime? dateOfBirth;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerDonorWisher() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Check if email already exists in the database
        final querySnapshot = await _firestore
            .collection('donor_wishers')
            .where('email', isEqualTo: emailController.text.trim())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Email already exists. Please use a different email.'),
          ));
          return;
        }

        // Store data in Firestore
        await _firestore.collection('donor_wishers').add({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'mobile': mobileController.text.trim(),
          'bloodType': bloodType,
          'gender': gender,
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'registrationDate': DateTime.now(),
        });

        // Send email (Integration needed)
        await _sendEmail(
            emailController.text.trim(), 'Donor Wisher Registration', '''
          Dear ${nameController.text.trim()},
          
          Thank you for registering as a Donor Wisher. Please visit our center between 10 AM to 4 PM with all the required documents for verification.

          Regards,
          Blood Quest
          ''');

        // Send SMS (Integration needed)
        await _sendSMS(mobileController.text.trim(),
            'Thank you for registering as a Donor Wisher. Please visit our center with the required documents for verification.');

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registration successful! Email and SMS sent.'),
        ));
        _formKey.currentState!.reset();
        setState(() {
          bloodType = null;
          gender = null;
          dateOfBirth = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
        ));
      }
    }
  }

  Future<void> _sendEmail(String to, String subject, String body) async {
    print('Email sent to $to');
  }

  Future<void> _sendSMS(String to, String message) async {
    print('SMS sent to $to');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donor Wisher Registration',
            style: TextStyle(
                fontSize: 23, color: const Color.fromARGB(255, 237, 243, 238))),
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Full Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                ),
                SizedBox(height: 15),

                // Email Field
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a valid email' : null,
                ),
                SizedBox(height: 15),

                // Mobile Number Field
                TextFormField(
                  controller: mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    if (value.length != 10) {
                      return 'Phone number must be 10 digits long';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Blood Type Dropdown
                DropdownButtonFormField<String>(
                  value: bloodType,
                  decoration: InputDecoration(
                    labelText: 'Blood Type',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      bloodType = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select your blood type' : null,
                ),
                SizedBox(height: 15),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                  items: ['Female', 'Male', 'Other']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      gender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select your gender' : null,
                ),
                SizedBox(height: 15),

                // Date of Birth Picker
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    suffixIcon:
                        Icon(Icons.calendar_today, color: Colors.redAccent),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        dateOfBirth = pickedDate;
                      });
                    }
                  },
                  controller: TextEditingController(
                    text: dateOfBirth == null
                        ? ''
                        : DateFormat('yyyy-MM-dd').format(dateOfBirth!),
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Please select your date of birth'
                      : null,
                ),
                SizedBox(height: 30),

                // Register Button
                ElevatedButton(
                  onPressed: _registerDonorWisher,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                        fontSize: 16,
                        //fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 237, 243, 238)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// updating the ui in above code this


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class DonorWisherRegistrationPage extends StatefulWidget {
//   @override
//   _DonorWisherRegistrationPageState createState() =>
//       _DonorWisherRegistrationPageState();
// }

// class _DonorWisherRegistrationPageState
//     extends State<DonorWisherRegistrationPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//   String? bloodType;
//   String? gender;
//   DateTime? dateOfBirth;

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> _registerDonorWisher() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         // Check if email already exists in the database
//         final querySnapshot = await _firestore
//             .collection('donor_wishers')
//             .where('email', isEqualTo: emailController.text.trim())
//             .get();

//         if (querySnapshot.docs.isNotEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//             content:
//                 Text('Email already exists. Please use a different email.'),
//           ));
//           return;
//         }

//         // Store data in Firestore
//         await _firestore.collection('donor_wishers').add({
//           'name': nameController.text.trim(),
//           'email': emailController.text.trim(),
//           'mobile': mobileController.text.trim(),
//           'bloodType': bloodType,
//           'gender': gender,
//           'dateOfBirth': dateOfBirth?.toIso8601String(),
//           'registrationDate': DateTime.now(),
//         });

//         // Send email (Integration needed)
//         await _sendEmail(
//             emailController.text.trim(), 'Donor Wisher Registration', '''
//           Dear ${nameController.text.trim()},
          
//           Thank you for registering as a Donor Wisher. Please visit our center between 10 AM to 4 PM with all the required documents for verification.

//           Regards,
//           Blood Quest
//           ''');

//         // Send SMS (Integration needed)
//         await _sendSMS(mobileController.text.trim(),
//             'Thank you for registering as a Donor Wisher. Please visit our center with the required documents for verification.');

//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Registration successful! Email and SMS sent.'),
//         ));
//         _formKey.currentState!.reset();
//         setState(() {
//           bloodType = null;
//           gender = null;
//           dateOfBirth = null;
//         });
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Error: ${e.toString()}'),
//         ));
//       }
//     }
//   }

//   Future<void> _sendEmail(String to, String subject, String body) async {
//     // Integrate with your email service provider here, e.g., SendGrid or Firebase Functions.
//     print('Email sent to $to');
//   }

//   Future<void> _sendSMS(String to, String message) async {
//     // Integrate with your SMS service provider here, e.g., Twilio API.
//     print('SMS sent to $to');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Donor Wisher Registration'),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: nameController,
//                   decoration: InputDecoration(labelText: 'Full Name'),
//                   validator: (value) =>
//                       value!.isEmpty ? 'Please enter your name' : null,
//                 ),
//                 TextFormField(
//                   controller: emailController,
//                   decoration: InputDecoration(labelText: 'Email'),
//                   validator: (value) =>
//                       value!.isEmpty ? 'Please enter a valid email' : null,
//                 ),
//                 TextFormField(
//                   controller: mobileController,
//                   decoration: InputDecoration(labelText: 'Mobile Number'),
//                   validator: (value) =>
//                       value!.isEmpty ? 'Please enter your mobile number' : null,
//                 ),
//                 DropdownButtonFormField<String>(
//                   value: bloodType,
//                   decoration: InputDecoration(labelText: 'Blood Type'),
//                   items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
//                       .map((type) => DropdownMenuItem(
//                             value: type,
//                             child: Text(type),
//                           ))
//                       .toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       bloodType = value;
//                     });
//                   },
//                   validator: (value) =>
//                       value == null ? 'Please select your blood type' : null,
//                 ),
//                 DropdownButtonFormField<String>(
//                   value: gender,
//                   decoration: InputDecoration(labelText: 'Gender'),
//                   items: ['Female', 'Male', 'Other']
//                       .map((gender) => DropdownMenuItem(
//                             value: gender,
//                             child: Text(gender),
//                           ))
//                       .toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       gender = value;
//                     });
//                   },
//                   validator: (value) =>
//                       value == null ? 'Please select your gender' : null,
//                 ),
//                 SizedBox(height: 20),
//                 TextFormField(
//                   readOnly: true,
//                   decoration: InputDecoration(
//                     labelText: 'Date of Birth',
//                     suffixIcon: Icon(Icons.calendar_today),
//                   ),
//                   onTap: () async {
//                     DateTime? pickedDate = await showDatePicker(
//                       context: context,
//                       initialDate: DateTime(2000),
//                       firstDate: DateTime(1900),
//                       lastDate: DateTime.now(),
//                     );
//                     if (pickedDate != null) {
//                       setState(() {
//                         dateOfBirth = pickedDate;
//                       });
//                     }
//                   },
//                   controller: TextEditingController(
//                     text: dateOfBirth == null
//                         ? ''
//                         : DateFormat('yyyy-MM-dd').format(dateOfBirth!),
//                   ),
//                   validator: (value) => value!.isEmpty
//                       ? 'Please select your date of birth'
//                       : null,
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _registerDonorWisher,
//                   child: Text('Register'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
