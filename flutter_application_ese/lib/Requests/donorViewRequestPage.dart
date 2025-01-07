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
