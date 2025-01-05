import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _message = "";

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
                // App Icon or Logo
                CircleAvatar(
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

                // Title
                Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),

                // Instruction Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Enter your email address below, and we will send you a link to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Input Field for Email
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: Colors.red),
                        prefixIcon: Icon(Icons.email, color: Colors.red),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Reset Button
                _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Send Reset Link',
                          style: TextStyle(
                              fontSize: 18, color: Colors.red.shade900),
                        ),
                      ),
                SizedBox(height: 20),

                // Feedback Message
                Text(
                  _message,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reset password function
  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      setState(() {
        _message = "Password reset link has been sent to your email!";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = "Failed to reset password. Please try again.";
        _isLoading = false;
      });
    }
  }
}
