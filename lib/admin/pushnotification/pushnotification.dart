import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationPage extends StatefulWidget {
  @override
  _PushNotificationPageState createState() => _PushNotificationPageState();
}

class _PushNotificationPageState extends State<PushNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false; // Add a loading state

  Future<void> sendPushNotification(String title, String message) async {
    setState(() {
      _isLoading = true; // Set loading to true when starting
    });

    try {
      // Retrieve all push tokens from 'deviceTokens' collection
      QuerySnapshot<Map<String, dynamic>> tokenSnapshot =
      await FirebaseFirestore.instance.collection('deviceTokens').get();

      // Iterate through all documents in the collection to get the tokens
      for (var doc in tokenSnapshot.docs) {
        String? pushToken = doc.data()['token'] as String?;

        if (pushToken != null && pushToken.isNotEmpty) {
          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'AAAAYhFxutM:APA91bHmaaAAEPBXDOqMfMhcZknLRMvL6HKk8FBuXcoxvcNDo7ELi-Hb_UpgTTuM4gB0L4n1W3Tuut3V2TsijQZKZngl-Y6pmShg0cyCQdtAngGMGlVLCScDImpH4AgmhBbZrp3y7Uvj', //  Firebase Cloud Messaging server key
            },
            body: jsonEncode(<String, dynamic>{
              'notification': <String, dynamic>{
                'body': message,
                'title': title,
              },
              'priority': 'high',
              'data': <String, dynamic>{
                'click_action': 'CLICK',
                'id': '1',
                'status': 'done',
              },
              'to': pushToken,
            }),
          );

          if (response.statusCode == 200) {
            // Notification sent successfully
            print('Notification sent to $pushToken');
          } else {
            // Failed to send notification
            print('Failed to send notification to $pushToken');
          }
        }
      }
    } catch (e) {
      print('Error sending push notification: $e');
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
          title: Text('Send Push Notification'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(labelText: 'Message'),
              ),
              SizedBox(height: 16.0),
              _isLoading // Show CircularProgressIndicator when loading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () {
                  String title = _titleController.text;
                  String message = _messageController.text;
                  if (title.isNotEmpty && message.isNotEmpty) {
                    sendPushNotification(title, message);
                  }
                },
                child: Text('Send Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
