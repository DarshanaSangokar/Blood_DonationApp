import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_ese/LoginPage.dart';
import 'package:flutter_application_ese/WisherRegistration/registerPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyByx6dZ6sUT4UUWwB8ru9U60EWA7TcdQws",
      projectId: "flutterbb-11b4b",
      messagingSenderId: "300921520039",
      appId: "1:300921520039:web:04b3276a21ba45a3134082",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Quest',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: LoginPage(), // Set LoginPage as the default screen
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_application_ese/algorithm/homePage.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: FirebaseOptions(
//       apiKey: "AIzaSyByx6dZ6sUT4UUWwB8ru9U60EWA7TcdQws",
//       projectId: "flutterbb-11b4b",
//       messagingSenderId: "300921520039",
//       appId: "1:300921520039:web:04b3276a21ba45a3134082",
//     ),
//   );
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // Assuming you fetch the userId after authentication
//     final String userId = "user123"; // Replace with the actual user ID

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Blood Quest',
//       theme: ThemeData(
//         primarySwatch: Colors.red,
//       ),
//       home: HomePage(userId: userId), // Navigate to the HomePage
//     );
//   }
// }

//  Pahile wali home screen