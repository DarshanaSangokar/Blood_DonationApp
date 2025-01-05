import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_ese/LoginPage.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _errorMessage = "";
  String _selectedRole = 'donor'; // Default role

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
                // App Logo
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                SizedBox(height: 20),

                // App Title
                Text(
                  'Blood Quest - Register',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 40),

                // Register Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Email Field
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.email, color: Colors.red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.lock, color: Colors.red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 20),

                        // Confirm Password Field
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: TextStyle(color: Colors.red),
                            prefixIcon: Icon(Icons.lock, color: Colors.red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(height: 20),

                        // Role Selection
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          items: [
                            DropdownMenuItem(
                              value: 'donor',
                              child: Text('Donor'),
                            ),
                            DropdownMenuItem(
                              value: 'hospital',
                              child: Text('Hospital'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Select Role',
                            labelStyle: TextStyle(color: Colors.red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Error Message
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),

                        // Register Button
                        _isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Already have an account? Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.yellow, fontSize: 16),
                      ),
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

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Passwords do not match!";
      });
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text,
        'role': _selectedRole, // Use selected role
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to register. Please try again!";
      });
    }
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_ese/LoginPage.dart';

// class RegisterPage extends StatefulWidget {
//   @override
//   _RegisterPageState createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   bool _isLoading = false;
//   String _errorMessage = "";

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
//                 // App Logo
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
//                   'Blood Quest - Register',
//                   style: TextStyle(
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     letterSpacing: 2,
//                   ),
//                 ),
//                 SizedBox(height: 40),

//                 // Register Card
//                 Card(
//                   elevation: 8,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(20),
//                     child: Column(
//                       children: [
//                         // Email Field
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

//                         // Password Field
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

//                         // Confirm Password Field
//                         TextField(
//                           controller: _confirmPasswordController,
//                           decoration: InputDecoration(
//                             labelText: 'Confirm Password',
//                             labelStyle: TextStyle(color: Colors.red),
//                             prefixIcon: Icon(Icons.lock, color: Colors.red),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           obscureText: true,
//                         ),
//                         SizedBox(height: 20),

//                         // Error Message
//                         if (_errorMessage.isNotEmpty)
//                           Text(
//                             _errorMessage,
//                             style: TextStyle(
//                               color: Colors.red,
//                               fontSize: 14,
//                             ),
//                           ),

//                         // Register Button
//                         _isLoading
//                             ? CircularProgressIndicator()
//                             : ElevatedButton(
//                                 onPressed: _register,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red,
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 50, vertical: 15),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                 ),
//                                 child: Text(
//                                   'Register',
//                                   style: TextStyle(
//                                       fontSize: 18, color: Colors.white),
//                                 ),
//                               ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),

//                 // Already have an account? Login link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Already have an account? ",
//                       style: TextStyle(color: Colors.white, fontSize: 16),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(builder: (context) => LoginPage()),
//                         );
//                       },
//                       child: Text(
//                         'Login',
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

//   Future<void> _register() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = "";
//     });

//     if (_passwordController.text != _confirmPasswordController.text) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Passwords do not match!";
//       });
//       return;
//     }

//     try {
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: _emailController.text,
//         password: _passwordController.text,
//       );

//       // Save user data to Firestore
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .set({
//         'email': _emailController.text,
//         'role': 'donor', // Default role
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => LoginPage()),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = "Failed to register. Please try again!";
//       });
//     }
//   }
// }
