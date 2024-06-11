import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PushNotificationCountsPage extends StatefulWidget {
  @override
  _PushNotificationCountsPageState createState() =>
      _PushNotificationCountsPageState();
}

class _PushNotificationCountsPageState
    extends State<PushNotificationCountsPage> {
  int androidCount = 0;
  int iosCount = 0;
  bool _isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    fetchNotificationCounts();
  }

  Future<void> fetchNotificationCounts() async {
    try {
      QuerySnapshot<Map<String, dynamic>> tokenSnapshot =
      await FirebaseFirestore.instance.collection('deviceTokens').get();
      for (var doc in tokenSnapshot.docs) {
        String? platform = doc.data()?['platform'] as String?;
        if (platform != null) {
          if (platform == 'android') {
            setState(() {
              androidCount++;
            });
          } else if (platform == 'ios') {
            setState(() {
              iosCount++;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching notification counts: $e');
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false when finished
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Push Notification Counts'),
        ),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator() // Show loading indicator when fetching data
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Android: $androidCount'),
              SizedBox(height: 20),
              Text('iOS: $iosCount'),
            ],
          ),
        ),
      ),
    );
  }
}
