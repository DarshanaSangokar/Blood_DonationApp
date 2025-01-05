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


// import 'package:flutter/material.dart';
// import 'package:flutter_application_ese/LoginPage.dart';
// import 'package:flutter_application_ese/donorScreen/viewProfilePage.dart';
// import 'package:flutter_application_ese/donorScreen/viewRequestsPage.dart';

// class DonorHomePage extends StatelessWidget {
//   final String userId;

//   const DonorHomePage({Key? key, required this.userId}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             // Redirect to Login Page
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>
//                     LoginPage(), // Replace with your login page widget
//               ),
//             );
//           },
//         ),
//         title: const Text(
//           'Donor Home',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Color.fromARGB(255, 237, 243, 238),
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: const Color.fromARGB(255, 220, 61, 61),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               const Color.fromARGB(255, 235, 144, 144),
//               Color.fromARGB(255, 242, 117, 117)
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Center(
//                 child: CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.white,
//                   child: ClipOval(
//                     child: Image.asset(
//                       'assets/logo.jpg', // Replace with actual image path
//                       fit: BoxFit.cover,
//                       width: 80,
//                       height: 80,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Center(
//                 child: Text(
//                   'Welcome, Donor!',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               // Buttons arranged with better spacing
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   // Your existing code for fetching data and navigating
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ViewProfilePage(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.person),
//                 label: const Text('View Profile'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 236, 40, 40),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 16,
//                     horizontal: 24,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20), // Spacing between buttons
//               ElevatedButton.icon(
//                 onPressed: () {
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         ViewBloodRequestPage(userId: 'your_user_id'),
//                   );
//                 },
//                 icon: const Icon(Icons.list),
//                 label: const Text('View Donation Requests'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 236, 40, 40),
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     vertical: 16,
//                     horizontal: 24,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Additional information or action can be placed below
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Text(
//                   'Thank you for contributing to save lives!',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.white,
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


// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_application_ese/LoginPage.dart';

// // // class DonorHomePage extends StatelessWidget {
// // //   final String userId;

// // //   const DonorHomePage({Key? key, required this.userId}) : super(key: key);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back),
// // //           onPressed: () {
// // //             // Redirect to Login Page
// // //             Navigator.pushReplacement(
// // //               context,
// // //               MaterialPageRoute(
// // //                 builder: (context) =>
// // //                     LoginPage(), // Replace with your login page widget
// // //               ),
// // //             );
// // //           },
// // //         ),
// // //         title: const Text(
// // //           'Donor Home',
// // //           style: TextStyle(
// // //             fontSize: 24,
// // //             fontWeight: FontWeight.bold,
// // //             color: Color.fromARGB(255, 237, 243, 238),
// // //           ),
// // //         ),
// // //         centerTitle: true,
// // //         backgroundColor: const Color.fromARGB(255, 220, 61, 61),
// // //       ),
// // //       body: Container(
// // //         decoration: BoxDecoration(
// // //           gradient: LinearGradient(
// // //             colors: [
// // //               Colors.red.shade300,
// // //               const Color.fromARGB(255, 191, 76, 76)
// // //             ],
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //           ),
// // //         ),
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(16.0),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               const SizedBox(height: 20),
// // //               Center(
// // //                 child: CircleAvatar(
// // //                   radius: 50,
// // //                   backgroundColor: Colors.white,
// // //                   child: ClipOval(
// // //                     child: Image.asset(
// // //                       'assets/logo.jpg', // Replace with actual image path
// // //                       fit: BoxFit.cover,
// // //                       width: 80,
// // //                       height: 80,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 20),
// // //               Center(
// // //                 child: Text(
// // //                   'Welcome, Donor!',
// // //                   style: TextStyle(
// // //                     fontSize: 20,
// // //                     fontWeight: FontWeight.bold,
// // //                     color: Colors.white,
// // //                   ),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 30),
// // //               const SizedBox(height: 15),
// // //               ElevatedButton.icon(
// // //                 onPressed: () async {
// // //                   // Your existing code for fetching data and navigating
// // //                 },
// // //                 icon: const Icon(Icons.person),
// // //                 label: const Text('View Profile'),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: Colors.red.shade900,
// // //                   foregroundColor: Colors.white,
// // //                   padding: const EdgeInsets.symmetric(
// // //                     vertical: 12,
// // //                     horizontal: 20,
// // //                   ),
// // //                 ),
// // //               ),
// // //               ElevatedButton.icon(
// // //                 onPressed: () {
// // //                   // Handle view donation requests
// // //                 },
// // //                 icon: const Icon(Icons.list),
// // //                 label: const Text('View Donation Requests'),
// // //                 style: ElevatedButton.styleFrom(
// // //                   backgroundColor: Colors.red.shade900,
// // //                   foregroundColor: Colors.white,
// // //                   padding: const EdgeInsets.symmetric(
// // //                     vertical: 12,
// // //                     horizontal: 20,
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



// // // import 'package:flutter/material.dart';
// // // import 'profile_page.dart';
// // // import 'settings_page.dart';

// // // class DonorHomePage extends StatelessWidget {
// // //   final String userId;

// // //   const DonorHomePage({Key? key, required this.userId}) : super(key: key);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Donor Home Page'),
// // //         centerTitle: true,
// // //         backgroundColor: Colors.red.shade900,
// // //       ),
// // //       body: SingleChildScrollView(
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(16.0),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               // Welcome Section
// // //               Container(
// // //                 padding: const EdgeInsets.all(20.0),
// // //                 decoration: BoxDecoration(
// // //                   color: Colors.red.shade100,
// // //                   borderRadius: BorderRadius.circular(15),
// // //                 ),
// // //                 child: Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(
// // //                       'Welcome, Donor!',
// // //                       style: TextStyle(
// // //                         fontSize: 24,
// // //                         fontWeight: FontWeight.bold,
// // //                         color: Colors.red.shade900,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 10),
// // //                     Text(
// // //                       'Your User ID: $userId',
// // //                       style:
// // //                           TextStyle(fontSize: 16, color: Colors.grey.shade700),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 20),

// // //               // Actions Section
// // //               const Text(
// // //                 'Quick Actions',
// // //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// // //               ),
// // //               const SizedBox(height: 10),
// // //               Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   _buildActionCard(
// // //                     icon: Icons.search,
// // //                     label: 'Find Requests',
// // //                     onTap: () {
// // //                       Navigator.pushNamed(context, '/findRequests');
// // //                     },
// // //                   ),
// // //                   _buildActionCard(
// // //                     icon: Icons.history,
// // //                     label: 'Donation History',
// // //                     onTap: () {
// // //                       Navigator.pushNamed(context, '/donationHistory');
// // //                     },
// // //                   ),
// // //                   _buildActionCard(
// // //                     icon: Icons.location_on,
// // //                     label: 'Nearby Drives',
// // //                     onTap: () {
// // //                       Navigator.pushNamed(context, '/nearbyDrives');
// // //                     },
// // //                   ),
// // //                 ],
// // //               ),
// // //               const SizedBox(height: 20),

// // //               // Notifications Section
// // //               const Text(
// // //                 'Notifications',
// // //                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// // //               ),
// // //               const SizedBox(height: 10),
// // //               ListView.builder(
// // //                 itemCount: 3, // Replace with actual notification count
// // //                 shrinkWrap: true,
// // //                 physics: const NeverScrollableScrollPhysics(),
// // //                 itemBuilder: (context, index) {
// // //                   return Card(
// // //                     margin: const EdgeInsets.symmetric(vertical: 8.0),
// // //                     child: ListTile(
// // //                       leading: const Icon(Icons.notification_important,
// // //                           color: Colors.red),
// // //                       title: const Text('Blood Donation Drive Scheduled'),
// // //                       subtitle: const Text('Drive at XYZ Hospital on 28th Dec'),
// // //                       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
// // //                       onTap: () {
// // //                         // Handle notification tap
// // //                       },
// // //                     ),
// // //                   );
// // //                 },
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //       bottomNavigationBar: BottomNavigationBar(
// // //         items: const [
// // //           BottomNavigationBarItem(
// // //             icon: Icon(Icons.home),
// // //             label: 'Home',
// // //           ),
// // //           BottomNavigationBarItem(
// // //             icon: Icon(Icons.person),
// // //             label: 'Profile',
// // //           ),
// // //           BottomNavigationBarItem(
// // //             icon: Icon(Icons.settings),
// // //             label: 'Settings',
// // //           ),
// // //         ],
// // //         selectedItemColor: Colors.red.shade900,
// // //         unselectedItemColor: Colors.grey,
// // //         onTap: (index) {
// // //           if (index == 1) {
// // //             Navigator.push(
// // //               context,
// // //               MaterialPageRoute(builder: (context) => const ProfilePage()),
// // //             );
// // //           } else if (index == 2) {
// // //             Navigator.push(
// // //               context,
// // //               MaterialPageRoute(builder: (context) => const SettingsPage()),
// // //             );
// // //           }
// // //         },
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildActionCard({
// // //     required IconData icon,
// // //     required String label,
// // //     required Function() onTap,
// // //   }) {
// // //     return GestureDetector(
// // //       onTap: onTap,
// // //       child: Container(
// // //         width: 100,
// // //         height: 120,
// // //         decoration: BoxDecoration(
// // //           color: Colors.red.shade50,
// // //           borderRadius: BorderRadius.circular(10),
// // //           border: Border.all(color: Colors.red.shade200),
// // //         ),
// // //         child: Column(
// // //           mainAxisAlignment: MainAxisAlignment.center,
// // //           children: [
// // //             Icon(icon, size: 40, color: Colors.red.shade900),
// // //             const SizedBox(height: 10),
// // //             Text(
// // //               label,
// // //               textAlign: TextAlign.center,
// // //               style: TextStyle(fontSize: 14, color: Colors.red.shade900),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
