import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bloom_wild/models/hackerrank_user.dart' as model;

class AuthMethods {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  static User get user => auth.currentUser!;

  Future<model.HackerrankUser> getUserDetails() async {
    User? currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in.');
    }
    try {
      DocumentSnapshot documentSnapshot =
      await firestore.collection('hackerrank_users').doc(currentUser.uid).get();

      if (!documentSnapshot.exists) {
        throw Exception('User data does not exist.');
      }

      return model.HackerrankUser.fromJson(documentSnapshot.data()! as Map<String, dynamic>);
    } catch (e) {
      // Log error, handle or rethrow as needed
      throw Exception('Failed to fetch user details: $e');
    }
  }
}
