//correctly deleting it

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewProfilePage extends StatefulWidget {
  @override
  _ViewProfilePageState createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userProfileData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }

      final snapshot = await _firestore
          .collection('donors')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User profile not found in Firestore.');
      }

      setState(() {
        userProfileData = snapshot.docs.first.data();
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserProfile(String field, String newValue) async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }

      final snapshot = await _firestore
          .collection('donors')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User profile not found in Firestore.');
      }

      final docId = snapshot.docs.first.id;

      await _firestore
          .collection('donors')
          .doc(docId)
          .update({field: newValue});

      setState(() {
        userProfileData![field] = newValue;
      });

      _showSuccessSnackBar('$field updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUserProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }

      // Deleting user profile from Firestore
      final snapshot = await _firestore
          .collection('donors')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User profile not found in Firestore.');
      }

      final docId = snapshot.docs.first.id;
      await _firestore.collection('donors').doc(docId).delete();

      // Deleting user from Firebase Authentication
      await currentUser.delete();

      await _auth.signOut(); // Logout user after deletion

      _showSuccessSnackBar('Profile deleted successfully!');
      _reloadApp(); // Reload app or return to login
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        _showErrorSnackBar(
            'Please reauthenticate and try again to delete your profile.');
      } else {
        _showErrorSnackBar('Error deleting profile: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _reloadApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              _reloadApp();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userProfileData == null
              ? Center(child: Text('No profile data available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileField(
                          'Name', userProfileData!['name'], true),
                      _buildProfileField(
                          'Date of Birth', userProfileData!['dob'], true),
                      _buildProfileField(
                          'Age', userProfileData!['age'].toString(), true),
                      _buildProfileField(
                          'Blood Type', userProfileData!['bloodType'], false),
                      _buildProfileField(
                          'Gender', userProfileData!['gender'], false),
                      _buildProfileField(
                          'Location', userProfileData!['location'], true),
                      Spacer(),
                      Center(
                        child: ElevatedButton(
                          onPressed: _deleteUserProfile,
                          style: ElevatedButton.styleFrom(
                              primary: Colors.redAccent),
                          child: Text('Delete Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileField(String label, String value, bool isEditable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: isEditable
                ? GestureDetector(
                    onTap: () => _showEditDialog(label, value),
                    child: Row(
                      children: [
                        Text(
                          value,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        Icon(Icons.edit, color: Colors.grey),
                      ],
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(fontSize: 16.0),
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $field'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateUserProfile(field.toLowerCase(), controller.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
