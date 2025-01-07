import 'package:flutter/material.dart';
import 'package:flutter_application_ese/LoginPage.dart';
import 'package:flutter_application_ese/Requests/donorViewRequestPage.dart';
import 'package:flutter_application_ese/Requests/hospitalCreateBloodRequest.dart';
import 'package:flutter_application_ese/algorithm/donorReg.dart';
import 'package:flutter_application_ese/algorithm/donor_search.dart';
import 'package:flutter_application_ese/algorithm/bloodRequest.dart';

class HomePage extends StatelessWidget {
  final String userId; // Pass the current user's ID

  HomePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Redirect to Logi3.00.n Page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LoginPage(), // Replace with your login page widget
              ),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Hospital Dashboard',
              style: TextStyle(color: const Color.fromARGB(255, 237, 243, 238)),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.red.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Donor Registration Button
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.person_add,
                      color: Colors.red[800],
                      size: 40,
                    ),
                    title: Text(
                      'Register as Donor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Navigate to the Register Donor Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorRegistrationPage(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                // Donor Search Button
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.search,
                      color: Colors.red[800],
                      size: 40,
                    ),
                    title: Text(
                      'Search Nearby Donors',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Navigate to the Search Nearby Donor Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorSearchPage(userId: userId),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                // Create Blood Request Button
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.bloodtype,
                      color: Colors.red[800],
                      size: 40,
                    ),
                    title: Text(
                      'Create Blood Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Navigate to the Blood Request Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateRequestPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
