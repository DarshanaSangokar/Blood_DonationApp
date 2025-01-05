import 'package:flutter/material.dart';
import 'package:flutter_application_ese/WisherRegistration/WhoCanDonatePage.dart';
import 'package:flutter_application_ese/WisherRegistration/donor_wisher.dart';
import 'hospital_registration_page.dart'; // Import the hospital registration page

class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blood Quest',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 214, 85, 76),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // App Logo
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: CircleAvatar(
              radius: isMobile ? 40 : 60, // Smaller for mobile
              backgroundImage:
                  AssetImage('assets/logo.jpg'), // Add your logo here
            ),
          ),
          SizedBox(height: isMobile ? 10 : 20),

          // Welcome Text
          Text(
            'Welcome to Blood Donation App',
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 10 : 20),
          Text(
            'Join us to save lives by donating blood',
            style: TextStyle(
              fontSize: isMobile ? 12 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 20 : 30),

          // Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHomeButton(
                  context,
                  'Register as Donor',
                  Icons.volunteer_activism,
                  Colors.red,
                  isMobile,
                  () {
                    // Navigate to Donor Registration
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DonorWisherRegistrationPage()), //DonorRegistrationPage()),
                    );
                  },
                ),
                _buildHomeButton(
                  context,
                  'Register as Hospital',
                  Icons.local_hospital,
                  Colors.blue,
                  isMobile,
                  () {
                    // Navigate to Hospital Registration
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HospitalWisherRegistrationPage()),
                    );
                  },
                ),
                _buildHomeButton(
                  context,
                  'Who Can Donate',
                  Icons.help_outline,
                  Colors.green,
                  isMobile,
                  () {
                    // Navigate to "Who is Eligible" page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WhoCanDonatePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Button Builder
  Widget _buildHomeButton(BuildContext context, String title, IconData icon,
      Color color, bool isMobile, VoidCallback onPressed) {
    return SizedBox(
      width: isMobile ? 80 : 120, // Smaller width for mobile
      height: isMobile ? 100 : 140, // Smaller height for mobile
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.white,
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.all(10),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: isMobile ? 30 : 40, color: color), // Icon size adjusts
            SizedBox(height: isMobile ? 5 : 10),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 10 : 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
