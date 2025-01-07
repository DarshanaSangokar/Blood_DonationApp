import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_ese/LoginPage.dart';
import 'package:flutter_application_ese/Requests/donorViewRequestPage.dart';
import 'package:flutter_application_ese/donorScreen/viewProfilePage.dart';

class DonorHomePage extends StatelessWidget {
  final String userId;

  const DonorHomePage({Key? key, required this.userId}) : super(key: key);

  Stream<QuerySnapshot<Map<String, dynamic>>> fetchScheduledRequests() {
    try {
      return FirebaseFirestore.instance
          .collection('blood_requests')
          .where('status', isEqualTo: 'scheduled')
          .orderBy('created_at', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
        title: const Text(
          'Donor Home',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 237, 243, 238),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 216, 69, 69),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 235, 144, 144),
              const Color.fromARGB(255, 242, 117, 117),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.jpg',
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Welcome, Donor!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewProfilePage()),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text('View Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 236, 40, 40),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewRequestPage()),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('View Donation Requests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 236, 40, 40),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
