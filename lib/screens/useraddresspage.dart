import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAddressPage extends StatefulWidget {
  @override
  _UserAddressPageState createState() => _UserAddressPageState();
}

class _UserAddressPageState extends State<UserAddressPage> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController =
  TextEditingController();

  String _currentUserEmail = "";

  @override
  void initState() {
    super.initState();
    _getCurrentUserEmail();
    _getUserAddress();
  }

  Future<void> _getCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email ?? "";
        _emailController.text = _currentUserEmail;
      });
    }
  }

  Future<void> _getUserAddress() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_address')
          .doc(_currentUserEmail)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _countryController.text = data['country'] ?? '';
        _postCodeController.text = data['postCode'] ?? '';
        _cityController.text = data['city'] ?? '';
        _countyController.text = data['county'] ?? '';
        _phoneNumberController.text = data['phoneNumber'] ?? '';
      }
    } catch (e) {
      print('Error fetching user address: $e');
    }
  }

  Future<void> _saveUserData() async {
    try {
      await FirebaseFirestore.instance.collection('user_address').doc(_currentUserEmail).set({
        'country': _countryController.text,
        'postCode': _postCodeController.text,
        'city': _cityController.text,
        'county': _countyController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Address saved successfully!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save address.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('User Address'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(labelText: 'Country'),
              ),
              TextFormField(
                controller: _postCodeController,
                decoration: InputDecoration(labelText: 'Post Code'),
              ),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City'),
              ),
              TextFormField(
                controller: _countyController,
                decoration: InputDecoration(labelText: 'County'),
              ),
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveUserData,
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
