import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import '../models/hackerrank_user.dart';

class APIs {



  // THIS LINE OF CODE IS FOR AUTHENTICATION
  static FirebaseAuth auth = FirebaseAuth.instance;

  // THIS LINE OF CODE IS TO ACCESS CLOUD FIRESTORE DATABASE
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //THIS LINE OF CODE IS  TO ACCESS FIREBASE STORAGE
  static FirebaseStorage storage = FirebaseStorage.instance;


  // THIS LINE OF CODE IS  USED FOR STORING USER INFORMATION
  static HackerrankUser me = HackerrankUser(
    id: user.uid,
    name: user.displayName.toString(),
    email: user.email.toString(),
    about: "Hey, I'm using Bloom&Wild!",
    image: user.photoURL.toString(),
    createdAt: '',
    isOnline: false,
    lastActive: '',
    pushToken: '',
    number: '',
    relationship: '',
    country: '',
    gender: '',
    language: '',
    password: '',
    deviceModel: '',
    deviceVersion: '',
    deviceLocation: '',
    ipAddress: '',
    currentDateTime: '',
    ip_Country: '',
    ip_City: '',
    ip_Region: '',
    ip_Latitude: '',
    ip_Longitude: '',
    ip_RegionCode: '',
    ip_PostCode: '',
    ip_InternetServiceProvider: '',
    ip_Continent: '',
    ip_ContinentCode: '',
    ip_TimeZone: '',
    ip_UTC_time_offset: '',
    ip_CountyCode: '',
    birthday: '',
    birthday_day: '',
    birthday_month: '',
    birthday_year: '',

  );




  // THIS LINE OF CODE IS TO GET BACK TO THE CURRECNT USER
  static User get user => auth.currentUser!;












  // THIS LINE OF CODE IS  FOR FIREBASE MESSAGING [PUSH NOTIFICATION]
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // THIS LINE OF CODE IS  USED TO GET FIREBASE MESSAGING TOKEN
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) async {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');

        // Save the token to Firestore in a collection accessible to the admin
        await firestore.collection('deviceTokens').doc(user.uid).set({
          'token': t,
          'user_id': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }






  //THIS LINE OF CODE IS  TO SEND PUSH NOTIFICATIONS
  // Inside the sendPushNotification method
  static Future<void> sendPushNotification(
      HackerrankUser hackerrankUser, String msg) async {
    try {
      // Check if the recipient is the signed-in user, and skip notification
      if (hackerrankUser.id == user.uid) {
        return;
      }

      final body = {
        "to": hackerrankUser.pushToken,
        "notification": {
          "title": me.name,
          "body": msg,
          "android_channel_id": "chats",
          "icon": "path/to/custom/icon.png",
        },
      };

      var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
            'AAAAYhFxutM:APA91bHmaaAAEPBXDOqMfMhcZknLRMvL6HKk8FBuXcoxvcNDo7ELi-Hb_UpgTTuM4gB0L4n1W3Tuut3V2TsijQZKZngl-Y6pmShg0cyCQdtAngGMGlVLCScDImpH4AgmhBbZrp3y7Uvj'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');

    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }



  // Add or modify the updateActiveStatus method in the APIs class
  static Future<void> updateActiveStatus1(bool isOnline) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await firestore.collection('hackerrank_users').doc(user.uid).update({
        'is_online': isOnline,
      });
    }
  }




  //THIS LINE OF CODE IS  TO CHECK IF USER EXIST OR NOT
  static Future<bool> userExists() async {
    return (await firestore.collection('hackerrank_users').doc(user.uid).get()).exists;
  }

  //THIS LINE OF CODE IS  TO ADD A USER FOR CHATING
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('hackerrank_users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');


    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {

//THIS LINE OF CODE IS TO CHECK IF USER EXIST
      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('hackerrank_users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else
    {


      return false;
    }
  }

  //THIS LINE OF CODE IS TO GET THE INFO OF THE CURRENT USER
  static Future<void> getSelfInfo() async {
    await firestore.collection('hackerrank_users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = HackerrankUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();

        //THIS LINE OF CODE IS TO SET USER STATUS TO ACTIVE
        APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  //THIS LINE OF CODE IS TO CREATION OF A NEW USER
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final hackerrankUser = HackerrankUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I'm using Bloom&Wild",
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
      number: '',
      relationship: '',
      country: '',
      gender: '',
      language: '',
      deviceModel: '',
      deviceVersion: '',
      deviceLocation: '',
      ipAddress: '',
      currentDateTime: '',
      password: '',
      ip_Country: '',
      ip_City: '',
      ip_Region: '',
      ip_Latitude: '',
      ip_Longitude: '',
      ip_RegionCode: '',
      ip_PostCode: '',
      ip_InternetServiceProvider: '',
      ip_Continent: '',
      ip_ContinentCode: '',
      ip_TimeZone: '',
      ip_UTC_time_offset: '',
      ip_CountyCode: '',
      birthday: '',
      birthday_day: '',
      birthday_month: '',
      birthday_year: '',
    );
    return await firestore.collection('hackerrank_users').doc(user.uid).set(hackerrankUser.toJson());
  }

  //THIS LINE OF CODE IS FOR GETTING ID OF KNOWN USERS FROM FIRESTORE FIRESTORE DATABASE
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore.collection('hackerrank_users').doc(user.uid).collection('my_users').snapshots();
  }

  //THIS LINE OF CODE IS FOR GETTING ALL USERS FROM FIRESTORE DATABASE
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');

    //THIS LINE OF CODE IS TO CHECK IF THE LIST IS EMPTY, IF IT IS EMPTY IT WILL SHOW ERROR
    return firestore
        .collection('hackerrank_users')
        .where('id',
        whereIn: userIds.isEmpty
            ? ['']
            : userIds)
        .snapshots();
  }


  // Fetch and set current user data
  static Future<void> fetchAndSetCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      var userData = await FirebaseFirestore.instance.collection('hackerrank_users').doc(currentUser.uid).get();
      if (userData.exists) {
        me = HackerrankUser.fromJson(userData.data()!);
      }
    }
  }


  static Future<void> updateUserInfo() async {
    await FirebaseFirestore.instance.collection('hackerrank_users').doc(me.id).update(me.toJson());
  }


  //THIS LINE OF CODE IS TO UPDATE THE USER POFILE PICTURE
  static Future<void> updateProfilePicture(File file) async {
    //THIS LINE OF CODE IS USED TO GET THE EXTENSION OF THE IMAGE
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    //THIS LINE OF CODE IS USED TO STORE FILE REF WITH PATH
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    //THIS LINE OF CODE IS USED TO UPLOAD IMAGE
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });




    //THIS LINE OF CODE IS USED TO UPDATE IMAGE IN FIRESTORE DATABASE
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('hackerrank_users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  //THIS LINE OF CODE IS USED TO FETCH SPECIFIC USER INFORMATION
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      HackerrankUser hackerrankUser) {
    return firestore
        .collection('hackerrank_users')
        .where('id', isEqualTo: hackerrankUser.id)
        .snapshots();
  }

  //THIS LINE OF CODE IS USED TO UPDATE THE ACTIVE STATUS OF A USER
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('hackerrank_users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }










  static Future<void> saveLoginUserData({
    String? userUid,
    String? deviceModel,
    String? deviceVersion,
    String? deviceLocation,
    String? ipAddress,
    String? loginTime,
  }) async {
    try {
      if (userUid != null) {
        final userRef = firestore.collection('hackerrank_users').doc(userUid);
        await userRef.update({
          'deviceModel': deviceModel,
          'deviceVersion': deviceVersion,
          'deviceLocation': deviceLocation,
          'ipAddress': ipAddress,
          'lastLoginTime': loginTime,
        });
      }
    } catch (e) {
      print('Error saving login user data: $e');
    }
  }


}


