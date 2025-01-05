//redirect to login page
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_ese/LoginPage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ViewRequestPage extends StatefulWidget {
  @override
  _ViewRequestPageState createState() => _ViewRequestPageState();
}

class _ViewRequestPageState extends State<ViewRequestPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? selectedBloodType;
  DateTime? lastDonationDate;

  final Map<String, List<String>> bloodCompatibility = {
    'A+': ['A+', 'AB+'],
    'A-': ['A+', 'A-', 'AB+', 'AB-'],
    'B+': ['B+', 'AB+'],
    'B-': ['B+', 'B-', 'AB+', 'AB-'],
    'AB+': ['AB+'],
    'AB-': ['AB+', 'AB-'],
    'O+': ['A+', 'B+', 'AB+', 'O+'],
    'O-': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
  };

  Future<void> fetchDonorDetails() async {
    if (currentUser == null) return;

    try {
      DocumentSnapshot donorDoc = await FirebaseFirestore.instance
          .collection('donors')
          .doc(currentUser!.uid)
          .get();

      if (donorDoc.exists) {
        setState(() {
          selectedBloodType = donorDoc.get('bloodType');
          lastDonationDate = donorDoc.get('lastDonationDate')?.toDate();
        });
      }
    } catch (e) {
      print('Error fetching donor details: $e');
    }
  }

  Future<void> saveBloodType(String bloodType) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('donors')
          .doc(currentUser!.uid)
          .set({'bloodType': bloodType}, SetOptions(merge: true));

      setState(() {
        selectedBloodType = bloodType;
      });
    } catch (e) {
      print('Error saving blood type: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDonorDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Requests',
            style: TextStyle(
                fontSize: 24, color: Color.fromARGB(255, 237, 243, 238))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: selectedBloodType == null
          ? buildBloodTypeSelection()
          : buildRequestList(),
    );
  }

  Widget buildBloodTypeSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select Your Blood Type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: selectedBloodType,
                isExpanded: true,
                underline: SizedBox(),
                items: bloodCompatibility.keys
                    .map(
                      (bloodType) => DropdownMenuItem(
                        value: bloodType,
                        child: Text(bloodType, style: TextStyle(fontSize: 18)),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value != null) {
                    await saveBloodType(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRequestList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('blood_requests')
          .where('status', isEqualTo: 'scheduled')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs.where((request) {
          final requestBloodType = request['bloodType'];
          return bloodCompatibility[selectedBloodType]!
              .contains(requestBloodType);
        }).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sentiment_dissatisfied,
                    size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text('No compatible requests found.',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Type: ${request['bloodType']}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Units: ${request['units']} ml'),
                    Text('Note: ${request['note']}'),
                    Divider(),
                    Text(
                      'Hospital Details:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text('Name: ${request['hospitalName']}'),
                    Text('Address: ${request['hospitalAddress']}'),
                    Text('Contact: ${request['hospitalContact']}'),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (lastDonationDate == null ||
                            DateTime.now()
                                    .difference(lastDonationDate!)
                                    .inDays >=
                                91) {
                          await respondToRequest(request.id, true, context);
                        } else {
                          final remainingDays = 91 -
                              DateTime.now()
                                  .difference(lastDonationDate!)
                                  .inDays;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'You can donate again in $remainingDays days.'),
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text('Accept',
                          style: TextStyle(
                              color: const Color.fromARGB(255, 237, 243, 238))),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> respondToRequest(
      String requestId, bool isAccepted, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId)
          .update({
        'status': 'completed',
        'donorId': currentUser!.uid,
      });

      await FirebaseFirestore.instance
          .collection('donors')
          .doc(currentUser!.uid)
          .update({'lastDonationDate': DateTime.now()});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request accepted!')),
      );

      // Redirect to login page after accepting
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing request: $e')),
      );
    }
  }
}



//once login -one or more request selected want to update that.
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ViewRequestPage extends StatefulWidget {
//   @override
//   _ViewRequestPageState createState() => _ViewRequestPageState();
// }

// class _ViewRequestPageState extends State<ViewRequestPage> {
//   final User? currentUser = FirebaseAuth.instance.currentUser;
//   String? selectedBloodType;
//   DateTime? lastDonationDate;

//   final Map<String, List<String>> bloodCompatibility = {
//     'A+': ['A+', 'AB+'],
//     'A-': ['A+', 'A-', 'AB+', 'AB-'],
//     'B+': ['B+', 'AB+'],
//     'B-': ['B+', 'B-', 'AB+', 'AB-'],
//     'AB+': ['AB+'],
//     'AB-': ['AB+', 'AB-'],
//     'O+': ['A+', 'B+', 'AB+', 'O+'],
//     'O-': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
//   };

//   Future<void> fetchDonorDetails() async {
//     if (currentUser == null) return;

//     try {
//       DocumentSnapshot donorDoc = await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .get();

//       if (donorDoc.exists) {
//         setState(() {
//           selectedBloodType = donorDoc.get('bloodType');
//           lastDonationDate = donorDoc.get('lastDonationDate')?.toDate();
//         });
//       }
//     } catch (e) {
//       print('Error fetching donor details: $e');
//     }
//   }

//   Future<void> saveBloodType(String bloodType) async {
//     if (currentUser == null) return;

//     try {
//       await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .set({'bloodType': bloodType}, SetOptions(merge: true));

//       setState(() {
//         selectedBloodType = bloodType;
//       });
//     } catch (e) {
//       print('Error saving blood type: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchDonorDetails();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Blood Requests', style: TextStyle(fontSize: 22)),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: selectedBloodType == null
//           ? buildBloodTypeSelection()
//           : buildRequestList(),
//     );
//   }

//   Widget buildBloodTypeSelection() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Select Your Blood Type',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 2,
//                     blurRadius: 4,
//                   ),
//                 ],
//               ),
//               child: DropdownButton<String>(
//                 value: selectedBloodType,
//                 isExpanded: true,
//                 underline: SizedBox(),
//                 items: bloodCompatibility.keys
//                     .map(
//                       (bloodType) => DropdownMenuItem(
//                         value: bloodType,
//                         child: Text(bloodType, style: TextStyle(fontSize: 18)),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) async {
//                   if (value != null) {
//                     await saveBloodType(value);
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildRequestList() {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection('blood_requests')
//           .where('status', isEqualTo: 'scheduled')
//           .snapshots(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }

//         final requests = snapshot.data!.docs.where((request) {
//           final requestBloodType = request['bloodType'];
//           return bloodCompatibility[selectedBloodType]!
//               .contains(requestBloodType);
//         }).toList();

//         if (requests.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.sentiment_dissatisfied,
//                     size: 50, color: Colors.grey),
//                 SizedBox(height: 10),
//                 Text('No compatible requests found.',
//                     style: TextStyle(fontSize: 18, color: Colors.grey)),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           itemCount: requests.length,
//           itemBuilder: (context, index) {
//             final request = requests[index];
//             return Card(
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Blood Type: ${request['bloodType']}',
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Text('Units: ${request['units']} ml'),
//                     Text('Note: ${request['note']}'),
//                     Divider(),
//                     Text(
//                       'Hospital Details:',
//                       style:
//                           TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                     Text('Name: ${request['hospitalName']}'),
//                     Text('Address: ${request['hospitalAddress']}'),
//                     Text('Contact: ${request['hospitalContact']}'),
//                     SizedBox(height: 10),
//                     ElevatedButton(
//                       onPressed: () async {
//                         if (lastDonationDate == null ||
//                             DateTime.now()
//                                     .difference(lastDonationDate!)
//                                     .inDays >=
//                                 91) {
//                           await respondToRequest(request.id, true, context);
//                         } else {
//                           final remainingDays = 91 -
//                               DateTime.now()
//                                   .difference(lastDonationDate!)
//                                   .inDays;
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text(
//                                 'You can donate again in $remainingDays days.'),
//                           ));
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                       ),
//                       child: Text('Accept'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> respondToRequest(
//       String requestId, bool isAccepted, BuildContext context) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('blood_requests')
//           .doc(requestId)
//           .update({
//         'status': 'completed',
//         'donorId': currentUser!.uid,
//       });

//       await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .update({'lastDonationDate': DateTime.now()});

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Request accepted!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error processing request: $e')),
//       );
//     }
//   }
// }



// wokring fine with blood type  compatiblity.
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ViewRequestPage extends StatefulWidget {
//   @override
//   _ViewRequestPageState createState() => _ViewRequestPageState();
// }

// class _ViewRequestPageState extends State<ViewRequestPage> {
//   final User? currentUser = FirebaseAuth.instance.currentUser;
//   String? selectedBloodType;

//   final Map<String, List<String>> bloodCompatibility = {
//     'A+': ['A+', 'AB+'],
//     'A-': ['A+', 'A-', 'AB+', 'AB-'],
//     'B+': ['B+', 'AB+'],
//     'B-': ['B+', 'B-', 'AB+', 'AB-'],
//     'AB+': ['AB+'],
//     'AB-': ['AB+', 'AB-'],
//     'O+': ['A+', 'B+', 'AB+', 'O+'],
//     'O-': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
//   };

//   Future<void> fetchDonorBloodType() async {
//     if (currentUser == null) return;

//     try {
//       DocumentSnapshot donorDoc = await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .get();

//       if (donorDoc.exists && donorDoc.get('bloodType') != null) {
//         setState(() {
//           selectedBloodType = donorDoc.get('bloodType');
//         });
//       }
//     } catch (e) {
//       print('Error fetching donor blood type: $e');
//     }
//   }

//   Future<void> saveBloodType(String bloodType) async {
//     if (currentUser == null) return;

//     try {
//       await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .set({'bloodType': bloodType}, SetOptions(merge: true));

//       setState(() {
//         selectedBloodType = bloodType;
//       });
//     } catch (e) {
//       print('Error saving blood type: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchDonorBloodType();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Blood Requests', style: TextStyle(fontSize: 22)),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: selectedBloodType == null
//           ? buildBloodTypeSelection()
//           : buildRequestList(),
//     );
//   }

//   Widget buildBloodTypeSelection() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Select Your Blood Type',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 2,
//                     blurRadius: 4,
//                   ),
//                 ],
//               ),
//               child: DropdownButton<String>(
//                 value: selectedBloodType,
//                 isExpanded: true,
//                 underline: SizedBox(),
//                 items: bloodCompatibility.keys
//                     .map(
//                       (bloodType) => DropdownMenuItem(
//                         value: bloodType,
//                         child: Text(bloodType, style: TextStyle(fontSize: 18)),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) async {
//                   if (value != null) {
//                     await saveBloodType(value);
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildRequestList() {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection('blood_requests')
//           .where('status', isEqualTo: 'scheduled')
//           .snapshots(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }

//         final requests = snapshot.data!.docs.where((request) {
//           final requestBloodType = request['bloodType'];
//           return bloodCompatibility[selectedBloodType]!
//               .contains(requestBloodType);
//         }).toList();

//         if (requests.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.sentiment_dissatisfied,
//                     size: 50, color: Colors.grey),
//                 SizedBox(height: 10),
//                 Text('No compatible requests found.',
//                     style: TextStyle(fontSize: 18, color: Colors.grey)),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           itemCount: requests.length,
//           itemBuilder: (context, index) {
//             final request = requests[index];
//             return Card(
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Blood Type: ${request['bloodType']}',
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Text('Units: ${request['units']} ml'),
//                     Text('Note: ${request['note']}'),
//                     Divider(),
//                     Text(
//                       'Hospital Details:',
//                       style:
//                           TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                     Text('Name: ${request['hospitalName']}'),
//                     Text('Address: ${request['hospitalAddress']}'),
//                     Text('Contact: ${request['hospitalContact']}'),
//                     SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () => respondToRequest(request.id, true),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                           ),
//                           child: Text('Accept'),
//                         ),
//                         ElevatedButton(
//                           onPressed: () => respondToRequest(request.id, false),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                           ),
//                           child: Text('Reject'),
//                         ),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void respondToRequest(String requestId, bool isAccepted) async {
//     if (isAccepted) {
//       await FirebaseFirestore.instance
//           .collection('blood_requests')
//           .doc(requestId)
//           .update({
//         'status': 'completed',
//         'donorId': currentUser?.uid,
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Request accepted!')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Request rejected.')),
//       );
//     }
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ViewRequestPage extends StatefulWidget {
//   @override
//   _ViewRequestPageState createState() => _ViewRequestPageState();
// }

// class _ViewRequestPageState extends State<ViewRequestPage> {
//   final User? currentUser = FirebaseAuth.instance.currentUser;
//   String? selectedBloodType;

//   // Blood compatibility map
//   final Map<String, List<String>> bloodCompatibility = {
//     'A+': ['A+', 'AB+'],
//     'A-': ['A+', 'A-', 'AB+', 'AB-'],
//     'B+': ['B+', 'AB+'],
//     'B-': ['B+', 'B-', 'AB+', 'AB-'],
//     'AB+': ['AB+'],
//     'AB-': ['AB+', 'AB-'],
//     'O+': ['A+', 'B+', 'AB+', 'O+'],
//     'O-': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
//   };

//   // Fetch the donor's blood type from Firestore
//   Future<void> fetchDonorBloodType() async {
//     if (currentUser == null) return;

//     try {
//       DocumentSnapshot donorDoc = await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .get();

//       if (donorDoc.exists && donorDoc.get('bloodType') != null) {
//         setState(() {
//           selectedBloodType = donorDoc.get('bloodType');
//         });
//       }
//     } catch (e) {
//       print('Error fetching donor blood type: $e');
//     }
//   }

//   // Save the donor's selected blood type to Firestore
//   Future<void> saveBloodType(String bloodType) async {
//     if (currentUser == null) return;

//     try {
//       await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .set({'bloodType': bloodType}, SetOptions(merge: true));

//       setState(() {
//         selectedBloodType = bloodType;
//       });
//     } catch (e) {
//       print('Error saving blood type: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchDonorBloodType();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Available Requests')),
//       body: selectedBloodType == null
//           ? buildBloodTypeSelection()
//           : buildRequestList(),
//     );
//   }

//   // Widget for blood type selection
//   Widget buildBloodTypeSelection() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text('Select your blood type', style: TextStyle(fontSize: 18)),
//           SizedBox(height: 20),
//           DropdownButton<String>(
//             value: selectedBloodType,
//             items: bloodCompatibility.keys
//                 .map((bloodType) => DropdownMenuItem(
//                       value: bloodType,
//                       child: Text(bloodType),
//                     ))
//                 .toList(),
//             onChanged: (value) async {
//               if (value != null) {
//                 await saveBloodType(value);
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget to display compatible blood requests
//   Widget buildRequestList() {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection('blood_requests')
//           .where('status', isEqualTo: 'scheduled')
//           .snapshots(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }

//         final requests = snapshot.data!.docs.where((request) {
//           final requestBloodType = request['bloodType'];
//           return bloodCompatibility[selectedBloodType]!
//               .contains(requestBloodType);
//         }).toList();

//         if (requests.isEmpty) {
//           return Center(child: Text('No compatible requests available.'));
//         }

//         return ListView.builder(
//           itemCount: requests.length,
//           itemBuilder: (context, index) {
//             final request = requests[index];
//             return Card(
//               margin: EdgeInsets.all(10),
//               child: ListTile(
//                 title: Text('Blood Type: ${request['bloodType']}'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('Units: ${request['units']} ml'),
//                     Text('Note: ${request['note']}'),
//                     Text('Hospital: ${request['hospitalName']}'),
//                     Text('Address: ${request['hospitalAddress']}'),
//                     Text('Contact: ${request['hospitalContact']}'),
//                   ],
//                 ),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.check, color: Colors.green),
//                       onPressed: () => respondToRequest(request.id, true),
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close, color: Colors.red),
//                       onPressed: () => respondToRequest(request.id, false),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // Respond to a blood request
//   void respondToRequest(String requestId, bool isAccepted) async {
//     if (isAccepted) {
//       await FirebaseFirestore.instance
//           .collection('blood_requests')
//           .doc(requestId)
//           .update({
//         'status': 'completed',
//         'donorId': currentUser?.uid,
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Request accepted!')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Request rejected.')),
//       );
//     }
//   }
// }



// //this code totally work fine just updating & trying that
// // it showing all request to all donor no matter what is there blood type.

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ViewRequestPage extends StatefulWidget {
//   @override
//   _ViewRequestPageState createState() => _ViewRequestPageState();
// }

// class _ViewRequestPageState extends State<ViewRequestPage> {
//   final User? currentUser = FirebaseAuth.instance.currentUser;

//   Future<Map<String, String>> _fetchDonorDetails() async {
//     if (currentUser == null) {
//       return {
//         'donorName': 'Anonymous Donor',
//         'donorId': 'Unknown',
//       };
//     }

//     try {
//       // Fetch donor details from the 'donors' collection
//       DocumentSnapshot donorDoc = await FirebaseFirestore.instance
//           .collection('donors')
//           .doc(currentUser!.uid)
//           .get();

//       if (donorDoc.exists) {
//         return {
//           'donorName': donorDoc.get('name') ?? 'Anonymous Donor',
//           'donorId': currentUser!.uid,
//         };
//       } else {
//         return {
//           'donorName': 'Anonymous Donor',
//           'donorId': currentUser!.uid,
//         };
//       }
//     } catch (e) {
//       print('Error fetching donor details: $e');
//       return {
//         'donorName': 'Anonymous Donor',
//         'donorId': currentUser!.uid,
//       };
//     }
//   }

//   void _respondToRequest(String requestId, bool isAccepted) async {
//     if (isAccepted) {
//       // Fetch donor details
//       Map<String, String> donorDetails = await _fetchDonorDetails();

//       await FirebaseFirestore.instance
//           .collection('blood_requests')
//           .doc(requestId)
//           .update({
//         'status': 'completed',
//         'donorName': donorDetails['donorName'],
//         'donorId': donorDetails['donorId'],
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Text('Request accepted! Donor details have been updated.')),
//       );
//     } else {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Request rejected.')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Available Requests')),
//       body: StreamBuilder(
//         stream: FirebaseFirestore.instance
//             .collection('blood_requests')
//             .where('status', isEqualTo: 'scheduled')
//             .snapshots(),
//         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (!snapshot.hasData) {
//             return Center(child: CircularProgressIndicator());
//           }
//           final requests = snapshot.data!.docs;

//           if (requests.isEmpty) {
//             return Center(child: Text('No scheduled requests available.'));
//           }

//           return ListView.builder(
//             itemCount: requests.length,
//             itemBuilder: (context, index) {
//               final request = requests[index];
//               return Card(
//                 margin: EdgeInsets.all(10),
//                 child: ListTile(
//                   title: Text('Blood Type: ${request['bloodType']}'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Units: ${request['units']} ml'),
//                       Text('Note: ${request['note']}'),
//                       Text('Hospital: ${request['hospitalName']}'),
//                       Text('Address: ${request['hospitalAddress']}'),
//                       Text('Contact: ${request['hospitalContact']}'),
//                     ],
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.check, color: Colors.green),
//                         onPressed: () => _respondToRequest(request.id, true),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.close, color: Colors.red),
//                         onPressed: () => _respondToRequest(request.id, false),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';

// // class ViewRequestPage extends StatefulWidget {
// //   @override
// //   _ViewRequestPageState createState() => _ViewRequestPageState();
// // }

// // class _ViewRequestPageState extends State<ViewRequestPage> {
// //   final User? currentUser = FirebaseAuth.instance.currentUser;

// //   Future<Map<String, String>> _fetchDonorDetails() async {
// //     if (currentUser == null) {
// //       return {
// //         'donorName': 'Anonymous Donor',
// //         'donorId': 'Unknown',
// //       };
// //     }

// //     try {
// //       // Fetch donor details from the 'donors' collection
// //       DocumentSnapshot donorDoc = await FirebaseFirestore.instance
// //           .collection('donors')
// //           .doc(currentUser!.uid)
// //           .get();

// //       if (donorDoc.exists) {
// //         return {
// //           'donorName': donorDoc.get('name') ?? 'Anonymous Donor',
// //           'donorId': currentUser!.uid,
// //         };
// //       } else {
// //         return {
// //           'donorName': 'Anonymous Donor',
// //           'donorId': currentUser!.uid,
// //         };
// //       }
// //     } catch (e) {
// //       print('Error fetching donor details: $e');
// //       return {
// //         'donorName': 'Anonymous Donor',
// //         'donorId': currentUser!.uid,
// //       };
// //     }
// //   }

// //   void _respondToRequest(String requestId, bool isAccepted) async {
// //     if (isAccepted) {
// //       // Fetch donor details
// //       Map<String, String> donorDetails = await _fetchDonorDetails();

// //       await FirebaseFirestore.instance
// //           .collection('blood_requests')
// //           .doc(requestId)
// //           .update({
// //         'status': 'completed',
// //         'donorName': donorDetails['donorName'],
// //         'donorId': donorDetails['donorId'],
// //       });

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //             content:
// //                 Text('Request accepted! Donor details have been updated.')),
// //       );
// //     } else {
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(SnackBar(content: Text('Request rejected.')));
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Available Requests')),
// //       body: StreamBuilder(
// //         stream: FirebaseFirestore.instance
// //             .collection('blood_requests')
// //             .where('status', isEqualTo: 'scheduled')
// //             .snapshots(),
// //         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
// //           if (!snapshot.hasData) {
// //             return Center(child: CircularProgressIndicator());
// //           }
// //           final requests = snapshot.data!.docs;

// //           if (requests.isEmpty) {
// //             return Center(child: Text('No scheduled requests available.'));
// //           }

// //           return ListView.builder(
// //             itemCount: requests.length,
// //             itemBuilder: (context, index) {
// //               final request = requests[index];
// //               return Card(
// //                 margin: EdgeInsets.all(10),
// //                 child: ListTile(
// //                   title: Text('Blood Type: ${request['bloodType']}'),
// //                   subtitle: Text(
// //                       'Units: ${request['units']} ml\nNote: ${request['note']}'),
// //                   trailing: Row(
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       IconButton(
// //                         icon: Icon(Icons.check, color: Colors.green),
// //                         onPressed: () => _respondToRequest(request.id, true),
// //                       ),
// //                       IconButton(
// //                         icon: Icon(Icons.close, color: Colors.red),
// //                         onPressed: () => _respondToRequest(request.id, false),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // // import 'package:flutter/material.dart';
// // // import 'package:cloud_firestore/cloud_firestore.dart';

// // // class ViewRequestPage extends StatefulWidget {
// // //   @override
// // //   _ViewRequestPageState createState() => _ViewRequestPageState();
// // // }

// // // class _ViewRequestPageState extends State<ViewRequestPage> {
// // //   void _respondToRequest(String requestId, bool isAccepted) async {
// // //     if (isAccepted) {
// // //       await FirebaseFirestore.instance
// // //           .collection('blood_requests')
// // //           .doc(requestId)
// // //           .update({
// // //         'status': 'completed',
// // //       });
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(content: Text('Request marked as completed!')));
// // //     } else {
// // //       ScaffoldMessenger.of(context)
// // //           .showSnackBar(SnackBar(content: Text('Request rejected.')));
// // //     }
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: Text('Available Requests')),
// // //       body: StreamBuilder(
// // //         stream: FirebaseFirestore.instance
// // //             .collection('blood_requests')
// // //             .where('status', isEqualTo: 'scheduled')
// // //             .snapshots(),
// // //         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
// // //           if (!snapshot.hasData) {
// // //             return Center(child: CircularProgressIndicator());
// // //           }
// // //           final requests = snapshot.data!.docs;

// // //           if (requests.isEmpty) {
// // //             return Center(child: Text('No scheduled requests available.'));
// // //           }

// // //           return ListView.builder(
// // //             itemCount: requests.length,
// // //             itemBuilder: (context, index) {
// // //               final request = requests[index];
// // //               return Card(
// // //                 margin: EdgeInsets.all(10),
// // //                 child: ListTile(
// // //                   title: Text('Blood Type: ${request['bloodType']}'),
// // //                   subtitle: Text(
// // //                       'Units: ${request['units']} ml\nNote: ${request['note']}'),
// // //                   trailing: Row(
// // //                     mainAxisSize: MainAxisSize.min,
// // //                     children: [
// // //                       IconButton(
// // //                         icon: Icon(Icons.check, color: Colors.green),
// // //                         onPressed: () => _respondToRequest(request.id, true),
// // //                       ),
// // //                       IconButton(
// // //                         icon: Icon(Icons.close, color: Colors.red),
// // //                         onPressed: () => _respondToRequest(request.id, false),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }
// // // }
