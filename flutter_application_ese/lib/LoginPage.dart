//All connected wal donor page.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_ese/algorithm/homePage.dart';
import 'package:flutter_application_ese/donorScreen/donor_home_page.dart';
import 'package:flutter_application_ese/WisherRegistration/registerPage.dart';
//import 'package:flutter_application_ese/register_page.dart';
import 'forgot_password_page.dart'; // Forgot password page

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _errorMessage = "";
  String _selectedRole = 'donor'; // Default role

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        _showError("User not found. Please register first.");
        return;
      }

      final userRole = userDoc['role'];
      if (userRole != _selectedRole) {
        _showError("Role mismatch! Please select the correct role.");
        return;
      }

      // Navigate based on role
      if (userRole == 'hospital') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(userId: userCredential.user!.uid)),
        );
      } else if (userRole == 'donor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DonorHomePage(userId: userCredential.user!.uid)),
        );
      }
    } catch (e) {
      _showError("Login failed. Please check your credentials.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade300, Colors.red.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  // radius: 50,
                  // backgroundColor: Colors.white,
                  // child: Icon(Icons.favorite, color: Colors.red, size: 60),
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.jpg', // Replace with actual image path
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Blood Quest',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 40),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.email, color: Colors.red),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.lock, color: Colors.red),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          onChanged: (newValue) =>
                              setState(() => _selectedRole = newValue!),
                          items: [
                            DropdownMenuItem(
                                value: 'donor', child: Text('Donor')),
                            DropdownMenuItem(
                                value: 'hospital', child: Text('Hospital')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Select Role',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.person, color: Colors.red),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgotPasswordPage()),
                              );
                            },
                            child: Text('Forgot Password?',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        SizedBox(height: 10),
                        _isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Login',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white)),
                              ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  RegisterPage()), // RegisterPage()),
                        );
                      },
                      child: Text('Register',
                          style: TextStyle(color: Colors.yellow, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_ese/algorithm/homePage.dart';
// import 'package:flutter_application_ese/forgot_password_page.dart';
// import 'package:flutter_application_ese/register_page.dart';

// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   bool _isLoading = false;
//   String _errorMessage = "";
//   String _selectedRole = 'donor'; // Default role is set to 'donor'

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.red.shade300, Colors.red.shade900],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.symmetric(horizontal: 20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // App Logo or Icon
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.white,
//                   child: Icon(
//                     Icons.favorite,
//                     color: Colors.red,
//                     size: 60,
//                   ),
//                 ),
//                 SizedBox(height: 20),

//                 // App Title
//                 Text(
//                   'Blood Quest',
//                   style: TextStyle(
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     letterSpacing: 2,
//                   ),
//                 ),
//                 SizedBox(height: 40),

//                 // Login Card
//                 Card(
//                   elevation: 8,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(20),
//                     child: Column(
//                       children: [
//                         // Email Input Field
//                         TextField(
//                           controller: _emailController,
//                           decoration: InputDecoration(
//                             labelText: 'Email',
//                             labelStyle: TextStyle(color: Colors.red),
//                             prefixIcon: Icon(Icons.email, color: Colors.red),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           keyboardType: TextInputType.emailAddress,
//                         ),
//                         SizedBox(height: 20),

//                         // Password Input Field
//                         TextField(
//                           controller: _passwordController,
//                           decoration: InputDecoration(
//                             labelText: 'Password',
//                             labelStyle: TextStyle(color: Colors.red),
//                             prefixIcon: Icon(Icons.lock, color: Colors.red),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           obscureText: true,
//                         ),
//                         SizedBox(height: 20),

//                         // Role Selection Dropdown
//                         DropdownButtonFormField<String>(
//                           value: _selectedRole,
//                           onChanged: (newValue) {
//                             setState(() {
//                               _selectedRole = newValue!;
//                             });
//                           },
//                           items: [
//                             DropdownMenuItem(
//                               value: 'donor',
//                               child: Text('Donor'),
//                             ),
//                             DropdownMenuItem(
//                               value: 'hospital',
//                               child: Text('Hospital'),
//                             ),
//                           ],
//                           decoration: InputDecoration(
//                             labelText: 'Select Role',
//                             labelStyle: TextStyle(color: Colors.red),
//                             prefixIcon: Icon(Icons.person, color: Colors.red),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 20),

//                         // Forgot Password Link
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => ForgotPasswordPage()),
//                               );
//                             },
//                             child: Text(
//                               'Forgot Password?',
//                               style: TextStyle(color: Colors.red),
//                             ),
//                           ),
//                         ),

//                         // Login Button
//                         _isLoading
//                             ? CircularProgressIndicator()
//                             : ElevatedButton(
//                                 onPressed: _login,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red,
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 50, vertical: 15),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   'Login',
//                                   style: TextStyle(
//                                       fontSize: 18, color: Colors.white),
//                                 ),
//                               ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),

//                 // Don't have an account? Register link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Don't have an account? ",
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => RegisterPage()),
//                         );
//                       },
//                       child: Text(
//                         'Register',
//                         style: TextStyle(color: Colors.yellow, fontSize: 16),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _login() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = "";
//     });

//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: _emailController.text,
//         password: _passwordController.text,
//       );

//       FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .get()
//           .then((doc) {
//         if (doc.exists) {
//           var userRole = doc['role'];
//           if (userRole == _selectedRole) {
//             // Navigate to respective HomePage based on role
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => HomePage(
//                         userId: '',
//                       )), // change here
//             );
//           } else {
//             setState(() {
//               _errorMessage = "Role mismatch! Please select the correct role.";
//             });
//           }
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to login. Please try again!";
//       });
//     }
//   }
// }


// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_application_ese/home_page.dart';
// // import 'package:flutter_application_ese/forgot_password_page.dart';
// // import 'package:flutter_application_ese/register_page.dart';

// // class LoginPage extends StatefulWidget {
// //   @override
// //   _LoginPageState createState() => _LoginPageState();
// // }

// // class _LoginPageState extends State<LoginPage> {
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   bool _isLoading = false;
// //   String _errorMessage = "";

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Colors.red.shade300, Colors.red.shade900],
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //           ),
// //         ),
// //         child: Center(
// //           child: SingleChildScrollView(
// //             padding: EdgeInsets.symmetric(horizontal: 20.0),
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: [
// //                 // App Logo or Icon
// //                 CircleAvatar(
// //                   radius: 50,
// //                   backgroundColor: Colors.white,
// //                   child: Icon(
// //                     Icons.favorite,
// //                     color: Colors.red,
// //                     size: 60,
// //                   ),
// //                 ),
// //                 SizedBox(height: 20),

// //                 // App Title
// //                 Text(
// //                   'Blood Quest',
// //                   style: TextStyle(
// //                     fontSize: 36,
// //                     fontWeight: FontWeight.bold,
// //                     color: Colors.white,
// //                     letterSpacing: 2,
// //                   ),
// //                 ),
// //                 SizedBox(height: 40),

// //                 // Login Card
// //                 Card(
// //                   elevation: 8,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(15),
// //                   ),
// //                   child: Padding(
// //                     padding: EdgeInsets.all(20),
// //                     child: Column(
// //                       children: [
// //                         // Email Input Field
// //                         TextField(
// //                           controller: _emailController,
// //                           decoration: InputDecoration(
// //                             labelText: 'Email',
// //                             labelStyle: TextStyle(color: Colors.red),
// //                             prefixIcon: Icon(Icons.email, color: Colors.red),
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                             ),
// //                           ),
// //                           keyboardType: TextInputType.emailAddress,
// //                         ),
// //                         SizedBox(height: 20),

// //                         // Password Input Field
// //                         TextField(
// //                           controller: _passwordController,
// //                           decoration: InputDecoration(
// //                             labelText: 'Password',
// //                             labelStyle: TextStyle(color: Colors.red),
// //                             prefixIcon: Icon(Icons.lock, color: Colors.red),
// //                             border: OutlineInputBorder(
// //                               borderRadius: BorderRadius.circular(10),
// //                             ),
// //                           ),
// //                           obscureText: true,
// //                         ),
// //                         SizedBox(height: 20),

// //                         // Forgot Password Link
// //                         Align(
// //                           alignment: Alignment.centerRight,
// //                           child: TextButton(
// //                             onPressed: () {
// //                               Navigator.push(
// //                                 context,
// //                                 MaterialPageRoute(
// //                                     builder: (context) => ForgotPasswordPage()),
// //                               );
// //                             },
// //                             child: Text(
// //                               'Forgot Password?',
// //                               style: TextStyle(color: Colors.red),
// //                             ),
// //                           ),
// //                         ),

// //                         // Login Button
// //                         _isLoading
// //                             ? CircularProgressIndicator()
// //                             : ElevatedButton(
// //                                 onPressed: _login,
// //                                 style: ElevatedButton.styleFrom(
// //                                   backgroundColor: Colors.red,
// //                                   padding: EdgeInsets.symmetric(
// //                                       horizontal: 50, vertical: 15),
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(10),
// //                                   ),
// //                                 ),
// //                                 child: Text(
// //                                   'Login',
// //                                   style: TextStyle(
// //                                       fontSize: 18, color: Colors.white),
// //                                 ),
// //                               ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(height: 20),

// //                 // Don't have an account? Register link
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Text(
// //                       "Don't have an account? ",
// //                       style: TextStyle(color: Colors.white, fontSize: 16),
// //                     ),
// //                     TextButton(
// //                       onPressed: () {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                               builder: (context) => RegisterPage()),
// //                         );
// //                       },
// //                       child: Text(
// //                         'Register',
// //                         style: TextStyle(color: Colors.yellow, fontSize: 16),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Future<void> _login() async {
// //     setState(() {
// //       _isLoading = true;
// //       _errorMessage = "";
// //     });

// //     try {
// //       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
// //         email: _emailController.text,
// //         password: _passwordController.text,
// //       );

// //       FirebaseFirestore.instance
// //           .collection('users')
// //           .doc(userCredential.user!.uid)
// //           .get()
// //           .then((doc) {
// //         if (doc.exists) {
// //           var userRole = doc['role'];
// //           if (userRole == 'donor') {
// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(builder: (context) => HomePage()),
// //             );
// //           } else if (userRole == 'hospital') {
// //             Navigator.pushReplacement(
// //               context,
// //               MaterialPageRoute(builder: (context) => HomePage()),
// //             );
// //           }
// //         }
// //       });
// //     } catch (e) {
// //       setState(() {
// //         _isLoading = false;
// //         _errorMessage = "Failed to login. Please try again!";
// //       });
// //     }
// //   }
// // }
