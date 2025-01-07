// updating for ui.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRequestPage extends StatefulWidget {
  @override
  _CreateRequestPageState createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitsController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _hospitalAddressController =
      TextEditingController();
  final TextEditingController _hospitalContactController =
      TextEditingController();
  String _selectedBloodType = 'A+';
  bool _isSubmitting = false;

  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  // Regular expression to allow only letters and spaces
  final RegExp _nameRegExp = RegExp(r'^[a-zA-Z\s]+$');

  // Regular expression to validate 10-digit phone number
  final RegExp _phoneRegExp = RegExp(r'^\d{10}$');

  void _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      await FirebaseFirestore.instance.collection('blood_requests').add({
        'bloodType': _selectedBloodType,
        'units': int.parse(_unitsController.text),
        'note': _noteController.text,
        'hospitalName': _hospitalNameController.text,
        'hospitalAddress': _hospitalAddressController.text,
        'hospitalContact': _hospitalContactController.text,
        'status': 'scheduled',
        'createdAt': DateTime.now(),
      });

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request created successfully!')),
      );
      _formKey.currentState!.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Blood Request',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 216, 69, 69),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Blood Type Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  items: bloodTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type, style: TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBloodType = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Blood Type',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a blood type';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Units Input Field
              _buildTextField(
                controller: _unitsController,
                label: 'Units (ml)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of units';
                  }
                  return null;
                },
              ),

              // Note Input Field (Optional)
              _buildTextField(
                controller: _noteController,
                label: 'Note (Optional)',
                keyboardType: TextInputType.text,
              ),

              // Hospital Name Input Field
              _buildTextField(
                controller: _hospitalNameController,
                label: 'Hospital Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the hospital name';
                  }
                  if (!_nameRegExp.hasMatch(value)) {
                    return 'Please enter a valid hospital name (letters only)';
                  }
                  return null;
                },
              ),

              // Hospital Address Input Field
              _buildTextField(
                controller: _hospitalAddressController,
                label: 'Hospital Address',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the hospital address';
                  }
                  // if (!_nameRegExp.hasMatch(value)) {
                  //   return 'Please enter a valid address (letters and spaces only)';
                  // }
                  return null;
                },
              ),

              // Hospital Contact Input Field
              _buildTextField(
                controller: _hospitalContactController,
                label: 'Hospital Contact',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the hospital contact number';
                  }
                  if (!_phoneRegExp.hasMatch(value)) {
                    return 'Please enter a valid 10-digit contact number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Submit Button
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 216, 69, 69),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            border: InputBorder.none,
          ),
          keyboardType: keyboardType,
          validator: validator,
        ),
      ),
    );
  }
}
