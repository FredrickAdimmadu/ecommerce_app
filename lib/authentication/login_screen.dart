
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bloom_wild/authentication/password_reset_screen.dart';
import 'package:bloom_wild/authentication/signup_screen.dart';
import '../../api/apis.dart';
import '../admin/adminpage.dart';
import '../navigate.dart';
import '../screens/homepage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static User get user => auth.currentUser!;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    await checkIfBannedAndLogin(_emailController.text.trim(), _passwordController.text.trim(), context);
    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  Future<void> checkIfBannedAndLogin(String email, String password, BuildContext context) async {
    // Check if user is in banned_users collection
    final bannedUser = await firestore.collection('banned_users')
        .where('email', isEqualTo: email)
        .get();

    if (bannedUser.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Access Denied'),
          content: Text('Your account has been banned.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If not banned, proceed to further geographical checks
    await signIn(email, password, context);
  }


  Future<void> sendCustomizedEmail(String email) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('hackerrank_users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        final deviceModel = userData['deviceModel'];
        final deviceVersion = userData['deviceVersion'];
        final ipCity = userData['ip_City'];
        final ipCountry = userData['ip_Country'];
        final loginTime = userData['lastLoginTime'];

        final resetPasswordToken = DateTime.now().millisecondsSinceEpoch.toString();
        //final resetPasswordLink = 'https://fivum-73ed0.firebaseapp.com/reset_password?email=$email&token=$resetPasswordToken';

        final smtpServer = gmail('bloom&wild@gmail.com', 'My Key');
        final message = Message()
          ..from = Address('bloomandwild@gmail.com', 'Bloom&Wild')
          ..recipients.add(email)
          ..subject = 'Bloom&Wild Login Details'
          ..html =
              '<p>Hi!, $email</p>'
              '<p>Below are the details of a successful login into your Bloom&Wild account.</p>'
              '<p> </p>'
              '<p>Login Date and Time: $loginTime</p>'
              '<p>Device Model: $deviceModel</p>'
              '<p>Device Version: $deviceVersion</p>'
              '<p>City: $ipCity</p>'
              '<p>Country: $ipCountry</p>';
              //'<p><a href="$resetPasswordLink">Click here to reset your password</a></p>';

        await send(message, smtpServer);
      }
    } catch (e) {
      // Handle error
      print('Error sending email: $e');
    }
  }






  Future<void> signIn(String email, String password, BuildContext context) async {
    var userSnapshot = await firestore.collection('hackerrank_users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Error'),
          content: Text('No user found with that email.'),
        ),
      );
      return;
    }

    var userData = userSnapshot.docs.first.data();
    String userContinent = userData['ip_Continent'];
    String userCountry = userData['ip_Country'];
    String userCity = userData['ip_City'];
    String userRegion = userData['ip_Region'];
    String userPostCode = userData['ip_PostCode'];

    // Checking ban status in a sequence of Continent, Country, City, Region, and PostCode
    if (await isBanned('banned_continent', userContinent, context) ||
        await isBanned('banned_country', userCountry, context) ||
        await isBanned('banned_city', userCity, context) ||
        await isBanned('banned_region', userRegion, context) ||
        await isBanned('banned_postcode', userPostCode, context)) {
      return; // If any condition is true, return and do not continue with login
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        String ipAddress = await _getIpAddress(); // Get IP address
        await _saveLoginUserData(ipAddress); // Pass IP address to save login user data
        await sendCustomizedEmail(email);
        APIs.updateActiveStatus(true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NavigatePage()));
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Error'),
          content: Text('Failed to log in: ${e.toString()}'),
        ),
      );
    }
  }

  Future<bool> isBanned(String collection, String value, BuildContext context) async {
    var snapshot = await firestore.collection(collection).doc(value).get();
    if (snapshot.exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Access Denied'),
          content: Text('$value has been banned from accessing this service.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return true;
    }
    return false;
  }


  DateTime currentDateTime = DateTime.now();

  Future<void> _saveLoginUserData(String ipAddress) async {
    final deviceInfo = await _getDeviceInfo();

    if (user != null) {
      await APIs.saveLoginUserData(
        userUid: user.uid,
        deviceModel: deviceInfo?['deviceModel'] ?? '',
        deviceVersion: deviceInfo?['deviceVersion'] ?? '',
        deviceLocation: '', // Set device location to empty string or null
        ipAddress: ipAddress ?? '',
        loginTime: currentDateTime.toString(),
      );
    }
  }



  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceInfo = {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
        deviceInfo = {
          'deviceModel': androidInfo.model,
          'deviceVersion': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
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
        return response.body;
      }
    } catch (e) {
      print('Error getting IP address: $e');
    }

    return '';
  }

  Future<String> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return '';
      }

      Position position = await Geolocator.getCurrentPosition();
      return '${position.latitude},${position.longitude}';
    } catch (e) {
      print('Error getting location: $e');
      return '';
    }
  }


  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isAnimate = true);
    });
  }


  @override
  Widget build(BuildContext context) {
   var mq = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bloom&Wild'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedPositioned(
              top: mq.height * .10,
              right: _isAnimate ? mq.width * .25 : -mq.width * .5,
              width: mq.width * .5,
              duration: const Duration(seconds: 1),
              child: Image.asset('assets/bwicon.png'),
            ),
            Positioned(
              top: mq.height * 0.3,
              left: mq.width * 0.1,
              right: mq.width * 0.1,
              child: Column(
                children: [
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
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Log in'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50), // make button wider
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PasswordResetScreen(),
                              ),
                            );
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Text(
                                'Password Reset',
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SignupScreen(),
                            ),
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              'Create Account',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AdminPage(),
                            ),
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              'ADMIN',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
