import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../api/apis.dart';
import '../models/hackerrank_user.dart';
import '../navigate.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      if (password.length < 7) {
        throw 'Password must be at least 7 characters';
      }

      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final deviceInfo = await _getDeviceInfo();
        final ipAddress = await _getIpAddress();
        await _saveUserData(
          userCredential.user!.uid,
          _nameController.text.trim(),
          password,
          email,
          deviceInfo,
          ipAddress,
        );

        APIs.updateActiveStatus(true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NavigatePage(),
          ),
        );
      }
    } catch (e) {
      print('Error creating account: $e');
      _showErrorDialog('Failed to create an account: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic>? deviceInfo;

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo = {
          'deviceModel': androidInfo.model,
          'deviceVersion': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo = {
          'deviceModel': iosInfo.model,
          'deviceVersion': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return deviceInfo;
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['ip'];
      }
    } catch (e) {
      print('Error getting IP address: $e');
    }

    return '';
  }

  Future<void> _saveUserData(
      String id,
      String name,
      String password,
      String email,
      Map<String, dynamic>? deviceInfo,
      String ipAddress,
      ) async {
    final DateTime now = DateTime.now();
    final String createdAt = now.toIso8601String();
    final String lastActive = createdAt;


      final geolocationData = await _fetchGeolocationData(ipAddress);

      final HackerrankUser hackerrankUser = HackerrankUser(
        id: id,
        name: name,
        email: email,
        about: "Hey, I'm using Bloom&Wild",
        image: '',
        createdAt: createdAt,
        isOnline: true,
        lastActive: lastActive,
        pushToken: '',
        number: '',
        relationship: '',
        country: '',
        gender: '',
        language: '',
        password: password,
        deviceModel: deviceInfo?['deviceModel'] ?? '',
        deviceVersion: deviceInfo?['deviceVersion'] ?? '',
        deviceLocation: '',
        ipAddress: ipAddress,
        currentDateTime: DateTime.now().toIso8601String(),
        ip_Country: geolocationData['country_name'] ?? '',
        ip_City: geolocationData['city'] ?? '',
        ip_Region: geolocationData['region'] ?? '',
        ip_Latitude: geolocationData['latitude'].toString(),
        ip_Longitude: geolocationData['longitude'].toString(),
        ip_RegionCode: geolocationData['region_code'] ?? '',
        ip_PostCode: geolocationData['postal'] ?? '',
        ip_InternetServiceProvider: geolocationData['org'] ?? '',
        ip_Continent: geolocationData['continent_code'] ?? '',
        ip_ContinentCode: geolocationData['continent_code'] ?? '',
        ip_TimeZone: geolocationData['timezone'] ?? '',
        ip_UTC_time_offset: geolocationData['utc_offset'] ?? '',
        ip_CountyCode: geolocationData['country_code'] ?? '',
        birthday: '',
        birthday_day: '',
        birthday_month: '',
        birthday_year: '',
      );
      await _firestore.collection('hackerrank_users').doc(id).set(hackerrankUser.toJson());

  }

  Future<Map<String, dynamic>> _fetchGeolocationData(String ipAddress) async {
    final response = await http.get(Uri.parse('https://ipapi.co/$ipAddress/json/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch geolocation data');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Bloom&Wild'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    keyboardType: TextInputType.name,
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 7) {
                        return 'Password must be at least 7 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  InkWell(
                    onTap: _isLoading ? null : _createAccount,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _isLoading ? Colors.grey : Colors.blue, // Change color based on your design
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        'Sign up',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text(
                          'Already have an account?',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            ' Login.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}