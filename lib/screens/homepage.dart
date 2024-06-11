import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bloom_wild/screens/useraddresspage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../api/apis.dart';
import '../authentication/login_screen.dart';
import '../helper/dialogs.dart';
import '../shop/favouritespage.dart';
import '../shop/myorders.dart';
import '../shop/shopflowerspage.dart';
import 'change_password_screen.dart';
import 'notificationadmin.dart';
import 'profile_edit_screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';



class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  Set<String> _favoritedItems = Set<String>();


  User? currentUser = FirebaseAuth.instance.currentUser;
  int unreadCount = 0;
  Timer? _userStatusCheckTimer;

  String deviceModel = '';
  String deviceVersion = '';
  String deviceLocation = '';
  String ipAddress = '';

  VideoPlayerController? _videoPlayerController;
  AudioPlayer? _audioPlayer;
  List<String> _allImages = [];


  Timer? _itemTimer;

  String? _userId;





  final PageController _pageController = PageController();
  final List<String> titles = [
    'PROGRAMMING', 'MEDICINE', 'MARKETING', 'DATA ANALYSIS', 'AGRICULTURE', 'POLITICS'
  ];
  final List<String> images = [
    'assets/code.jpeg',
    'assets/medicine.jpeg',
    'assets/marketting.jpeg',
    'assets/dataanalysis.jpeg',
    'assets/agriculture.jpeg',
    'assets/politics.jpeg'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    recordLoginTime();
    getDeviceInfo();
    _preloadAllImages();
    _getCurrentUserId();
    _loadFavorites();
    Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.page == 5) {
        _pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      } else {
        _pageController.nextPage(
          duration: Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });

    if (currentUser != null) {
      _startUserStatusChecks();
    }

    // Listen to changes in notifications
    FirebaseFirestore.instance
        .collection('admin_broadcast')
        .snapshots()
        .listen((snapshot) {
      int tempUnreadCount = 0;
      for (var doc in snapshot.docs) {
        if (!(doc['readBy'] ?? []).contains(currentUser!.uid)) {
          tempUnreadCount++;
        }
      }
      setState(() {
        unreadCount = tempUnreadCount; // Update unreadCount
      });
    });

    fetchIpAddress();
  }


  Future<void> _getCurrentUserId() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _loadFavorites() async {
    if (_userId != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(_userId)
          .collection('items')
          .get();

      setState(() {
        _favoritedItems = snapshot.docs.map((doc) => doc.id).toSet();
      });
    }
  }


  Future<void> _preloadAllImages() async {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('flower_broadcast').get();
    for (var doc in snapshot.docs) {
      if (doc['images'] != null) {
        _allImages.addAll(List<String>.from(doc['images']));
      }
    }
    await precacheImages();
  }

  Future<void> precacheImages() async {
    for (var imageUrl in _allImages) {
      await precacheImage(NetworkImage(imageUrl), context);
    }
  }

  void _incrementViewCount(String docId) {
    FirebaseFirestore.instance.collection('flower_broadcast').doc(docId).update({
      'views': FieldValue.increment(1),
    });
  }



  Future<void> _addToFavorites(QueryDocumentSnapshot document) async {
    if (_userId == null) return;

    CollectionReference favoritesRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(_userId)
        .collection('items');

    // Check if the item is already in favorites
    DocumentSnapshot docSnapshot = await favoritesRef.doc(document.id).get();
    if (!docSnapshot.exists) {
      // Add the document data to the favorites collection
      await favoritesRef.doc(document.id).set(document.data());

      // Update UI by setting the document id as favorited
      setState(() {
        _favoritedItems.add(document.id);
      });
    }
  }

  void _removeFromFavorites(String productId) async {
    if (_userId == null) return;

    CollectionReference favoritesRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(_userId)
        .collection('items');

    // Remove the document from the favorites collection
    await favoritesRef.doc(productId).delete();

    // Update UI by removing the document id from favorited items
    setState(() {
      _favoritedItems.remove(productId);
    });
  }







  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App is being paused (e.g., closed or sent to background)
      APIs.updateActiveStatus(false);
      recordLogoutTime(shouldRecordLogout: true);
    } else if (state == AppLifecycleState.resumed) {
      // App is being resumed (e.g., brought back to foreground)
      APIs.updateActiveStatus(true);
    }
  }









  User? get user => FirebaseAuth.instance.currentUser;

  void getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String modelName = 'Unknown';
    String version = 'Unknown';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        modelName = androidInfo.model ?? 'Unknown';
        version = androidInfo.version.release ?? 'Unknown';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        modelName = iosInfo.model ?? 'Unknown';
        version = iosInfo.systemVersion ?? 'Unknown';
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    setState(() {
      deviceModel = modelName;
      deviceVersion = version;
    });

    await fetchIpAddress(); // Call IP fetching directly here
    await fetchLocationAndIP(); // Fetch location separately
  }

  Future<void> fetchLocationAndIP() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final city = placemark.locality ?? 'Unknown';
        final country = placemark.country ?? 'Unknown';

        deviceLocation = 'Location: $city, $country';
      }
    } catch (e) {
      print('Error getting location: $e');
      deviceLocation = 'Location: Error';
    }

    // Optionally update Firestore here if you want to separate concerns
    saveToDeviceCollection(deviceModel, deviceVersion, deviceLocation, ipAddress);
  }



  Future<void> fetchIpAddress() async {
    try {
      http.Response response = await http.get(Uri.parse('https://api64.ipify.org?format=json'));
      if (response.statusCode == 200) {
        ipAddress = json.decode(response.body)['ip'];
      } else {
        //      print('Failed to fetch IP address with status code: ${response.statusCode}');
        ipAddress = 'IP Address: Error';
      }
    } catch (e) {
//      print('Error fetching IP address: $e');
      ipAddress = 'IP Address: Error';
    }
    // Consider saving to Firestore after fetching IP
    saveToDeviceCollection(deviceModel, deviceVersion, deviceLocation, ipAddress);
  }




  // Function to fetch geolocation data
  Future<Map<String, dynamic>> _fetchGeolocationData(String ipAddress) async {
    var response = await http.get(Uri.parse('https://ipapi.co/$ipAddress/json/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch geolocation data');
    }
  }





  DateTime currentDateTime = DateTime.now();
  // Function to save device information to Firebase Firestore
  Future<void> saveToDeviceCollection(
      String deviceModel,
      String deviceVersion,
      String deviceLocation,
      String ipAddress) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String userName = user.displayName ?? 'Unknown'; // Default value if name not found
      String userEmail = user.email ?? 'Unknown'; // Default value if email not found
      String userImage = user.photoURL ?? 'assets/images/add_image.png'; // Default URL if photoURL not found

      final geolocationData = await _fetchGeolocationData(ipAddress);

      CollectionReference deviceCollection = FirebaseFirestore.instance.collection('hackerrank_users_device');
      await deviceCollection.doc(user.uid).set({
        'deviceModel': deviceModel,
        'deviceVersion': deviceVersion,
        'deviceLocation': deviceLocation,
        'ipAddress': ipAddress,
        'loginTime': FieldValue.serverTimestamp(), // Store login time
        'userName': userName,
        'userEmail': userEmail,
        'userImage': userImage,
        'ip_Country': geolocationData['country_name'] ?? '',
        'ip_City': geolocationData['city'] ?? '',
        'ip_Region': geolocationData['region'] ?? '',
        'ip_Latitude': geolocationData['latitude'].toString(),
        'ip_Longitude': geolocationData['longitude'].toString(),
        'ip_RegionCode': geolocationData['region_code'] ?? '',
        'ip_PostCode': geolocationData['postal'] ?? '',
        'ip_InternetServiceProvider': geolocationData['org'] ?? '',
        'ip_Continent': geolocationData['continent_code'] ?? '',
        'ip_ContinentCode': geolocationData['continent_code'] ?? '',
        'ip_TimeZone': geolocationData['timezone'] ?? '',
        'ip_UTC_time_offset': geolocationData['utc_offset'] ?? '',
        'ip_CountyCode': geolocationData['country_code'] ?? '',
      }, SetOptions(merge: true));
    }
  }


  void recordLoginTime() {
    saveToDeviceCollection(deviceModel, deviceVersion, deviceLocation, ipAddress);
  }

  Future<void> recordLogoutTime({bool shouldRecordLogout = false}) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentReference docRef = FirebaseFirestore.instance.collection('hackerrank_users_device').doc(currentUser.uid);
        DocumentSnapshot docSnapshot = await docRef.get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
          Timestamp? loginTime = data['loginTime'];

          if (loginTime != null) {
            DateTime loginDateTime = loginTime.toDate();
            DateTime logoutDateTime = DateTime.now();
            Duration duration = logoutDateTime.difference(loginDateTime);

            int totalSeconds = duration.inSeconds;
            int totalMinutes = duration.inMinutes;
            int totalHours = duration.inHours;
            String durationString = '${totalHours}h ${totalMinutes % 60}m ${totalSeconds % 60}s';

            // Update the current document with logout information
            await docRef.update({
              'logoutTime': FieldValue.serverTimestamp(),
              'durationSeconds': totalSeconds,
              'durationMinutes': totalMinutes,
              'durationHours': totalHours,
              'durationReadable': durationString,
              'logoutDate': logoutDateTime
            });

            // Save a copy of the data to the new collection by date
            String dateKey = DateFormat('yyyyMMdd').format(logoutDateTime);
            DocumentReference dayDocRef = FirebaseFirestore.instance.collection('hackerrank_users_device_days').doc('${currentUser.uid}_$dateKey');
            await dayDocRef.set({
              ...data,
              'logoutTime': logoutDateTime,
              'durationSeconds': totalSeconds,
              'durationMinutes': totalMinutes,
              'durationHours': totalHours,
              'durationReadable': durationString,
              'logoutDate': logoutDateTime,
              'documentDate': dateKey  // Include the specific date key for easy querying
            }, SetOptions(merge: true));


            // Decide whether to store in top_users or low_users based on duration
            String collectionName;
            // Assuming threshold of 3600 seconds (1 hour) for top users
            if (totalSeconds >= 30) {
              collectionName = 'hackerrank_top_users';
            } else {
              collectionName = 'hackerrank_low_users';
            }

            // Save session data into the respective collection
            DocumentReference userDocRef = FirebaseFirestore.instance.collection(collectionName).doc('${currentUser.uid}_${DateFormat('yyyyMMdd').format(logoutDateTime)}');
            await userDocRef.set({
              ...data,
              'logoutTime': logoutDateTime,
              'durationSeconds': totalSeconds,
              'durationMinutes': totalMinutes,
              'durationHours': totalHours,
              'durationReadable': durationString,
              'documentDate': DateFormat('yyyyMMdd').format(logoutDateTime)
            }, SetOptions(merge: true));


            if (shouldRecordLogout) {
              // Handle any additional logic when app is being closed
            }
          }
        }
      } catch (e) {
        // Handle or log error appropriately
      }
    }
  }






  void _startUserStatusChecks() {
    _userStatusCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!await _isUserValid(currentUser!.uid)) {
        _logoutUser();
      }
    });
  }

  Future<bool> _isUserValid(String userId) async {
    // Fetch user data from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('hackerrank_users')
        .doc(userId)
        .get();

    if (!userSnapshot.exists) return false;

    var userData = userSnapshot.data() as Map<String, dynamic>;
    List<Future<bool>> checks = [
      _isInCollection('banned_users', 'email', userData['email']),
      _isInCollection('banned_continent', 'email', userData['ip_Continent']),
      _isInCollection('banned_country', 'email', userData['ip_Country']),
      _isInCollection('banned_city', 'email', userData['ip_City']),
      _isInCollection('banned_region', 'email', userData['ip_Region']),
      _isInCollection('banned_postcode', 'email', userData['ip_PostCode']),
    ];

    // Await all checks to complete
    var results = await Future.wait(checks);
    // If any check returns true, the user is not valid
    return !results.contains(true);
  }

  Future<bool> _isInCollection(String collectionName, String fieldName, String fieldValue) async {
    var result = await FirebaseFirestore.instance
        .collection(collectionName)
        .where(fieldName, isEqualTo: fieldValue)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  void _logoutUser() {
    _userStatusCheckTimer?.cancel();
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }


  Stream<int> getUnreadCountStream() {
    return FirebaseFirestore.instance
        .collection('admin_broadcast')
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      snapshot.docs.forEach((doc) {
        List<dynamic> readBy = doc.data()['readBy'] ?? [];
        if (!readBy.contains(currentUser?.uid)) {
          unreadCount++;
        }
      });
      return unreadCount;
    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text('Bloom&Wild'),
              ),
            ],
          ),
          actions: [
            StreamBuilder<int>(
              stream: getUnreadCountStream(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationPage(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile Update'),
                onTap: () async {
                  await APIs.fetchAndSetCurrentUser();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIs.me),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.assignment),
                title: Text('Orders'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyOrdersPage(currentUserEmail: currentUser?.email ?? ''),
                    ),
                  );
                },
              ),




              ListTile(
                leading: Icon(Icons.bookmark_added_rounded),
                title: Text('Favourites'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavouritesPage(userId: FirebaseAuth.instance.currentUser!.uid),
                    ),
                  );
                },
              ),






              ListTile(
                leading: Icon(Icons.location_city),
                title: Text('Address'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserAddressPage(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.lock),
                title: Text('Change Password'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordScreen(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  Dialogs.showProgressBar(context);
                  await recordLogoutTime();  // Record logout time first
                  await APIs.updateActiveStatus1(false);
                  FirebaseAuth.instance.signOut().then((value) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  }).catchError((error) {
//                    print('Error during logout: $error');
                  });
                },
              ),

            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trending Flowers', style: Theme.of(context).textTheme.headlineMedium),
                    TextButton(
                      onPressed: () {},
                      child: Text('VIEW ALL', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200, // Set a height for the PageView
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: titles.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {},
                      child: Card(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Image.asset(
                              images[index],
                              fit: BoxFit.cover,
                            ),
                            Center(
                              child: Text(
                                titles[index],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('flower_broadcast')
              .where('classification', whereIn: ['BIRTHDAY', 'ALL', 'WEDDING', 'ANNIVERSARY', 'GIFT', 'BURIAL', 'CELEBRATION'])
              .snapshots(),
          builder: (context, broadcastSnapshot) {
            if (!broadcastSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            List<QueryDocumentSnapshot> broadcastDocuments = broadcastSnapshot.data!.docs;

            // Fetch personalized flowers
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('personalized_flowers')
                  .doc(currentUser!.uid)
                  .collection('items')
                  .where('email', isEqualTo: currentUser!.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                // Filter broadcast documents based on personalized flower classifications
                List<QueryDocumentSnapshot> filteredBroadcastDocuments = [];
                for (var document in broadcastDocuments) {
                  // Check if any classification matches
                  if (documents.any((doc) => doc['classification'] == document['classification'])) {
                    filteredBroadcastDocuments.add(document);
                  }
                }

                // Display filtered broadcast documents
                // Delete items from personalized_flowers if they no longer exist in flower_broadcast
                for (var document in documents) {
                  // Check if the classification of the document exists in filteredBroadcastDocuments
                  if (!filteredBroadcastDocuments.any((doc) => doc['classification'] == document['classification'])) {
                    // Remove the document from personalized_flowers if not found in filteredBroadcastDocuments
                    FirebaseFirestore.instance
                        .collection('personalized_flowers')
                        .doc(currentUser!.uid)
                        .collection('items')
                        .doc(document.id)
                        .delete();
                  }
                }

                return _buildPersonalizedFlowersList(filteredBroadcastDocuments);
              },
            );
          },
        ),




        ],
          ),
        ),
      ),
    );
  }


  Widget _buildPersonalizedFlowersList(List<QueryDocumentSnapshot> documents) {
    return GridView.builder(
      shrinkWrap: true, // Ensure GridView does not take infinite height
      physics: NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return _buildPersonalizedFlowerCard(documents[index]);
      },
    );
  }





  Widget _buildPersonalizedFlowerCard(QueryDocumentSnapshot document) {
    bool isFavorited = _favoritedItems.contains(document.id); // Check if the flower is already favorited by the user





    return GestureDetector(
      onTap: () async {
        await _preloadResources(document);
        _itemTimer?.cancel(); // Cancel previous timer
        _itemTimer = Timer(Duration(seconds: 10), () {

        });
        // Increment view count when user views the flower card
        _incrementViewCount(document.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DescriptionPage(document: document),
          ),
        );
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: _preloadImage(document['images'][0]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Expanded(
                    child: Image.network(
                      document['images'][0],
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return Expanded(
                    child: SpinKitFadingCircle(
                      itemBuilder: (BuildContext context, int index) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: index.isEven ? Colors.red : Colors.green,
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Price: \£${double.parse(document['price'].toString())}'),
                  if (!isFavorited) // Only show the icon if not favorited
                    GestureDetector(
                      onTap: () {
                        _addToFavorites(document);
                      },
                      child: Icon(
                        Icons.favorite_border, // Show empty heart icon if not favorited
                        color: null, // No color by default
                      ),
                    ),
                  if (isFavorited) // Only show the icon if favorited
                    GestureDetector(
                      onTap: () {
                        _removeFromFavorites(document.id);
                      },
                      child: Icon(
                        Icons.favorite, // Show filled heart icon if favorited
                        color: Colors.blue, // Set color to blue if favorited
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _preloadImage(String imageUrl) {
    return precacheImage(NetworkImage(imageUrl), context);
  }

  Future<void> _preloadResources(QueryDocumentSnapshot document) async {
    final List<Future<void>> preloadFutures = [];
    if (document['images'] != null) {
      for (var url in document['images']) {
        preloadFutures.add(precacheImage(NetworkImage(url), context));
      }
    }
    if (document['video'] != null && document['video'].isNotEmpty) {
      final videoPlayerController = VideoPlayerController.network(document['video']);
      preloadFutures.add(videoPlayerController.initialize());
    }
    await Future.wait(preloadFutures);
  }




  List<Widget> _buildCarouselItems(QueryDocumentSnapshot document) {
    List<Widget> carouselItems = [];

    if (document['images'] != null) {
      carouselItems.addAll(
        document['images'].map<Widget>((url) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      );
    }

    if (document['video'] != null) {
      VideoPlayerController _videoPlayerController = VideoPlayerController.network(document['video']);
      _videoPlayerController.initialize().then((_) {
        setState(() {});
      });
      carouselItems.add(
        AspectRatio(
          aspectRatio: _videoPlayerController.value.aspectRatio,
          child: VideoPlayer(_videoPlayerController),
        ),
      );
    }

    return carouselItems;
  }




  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    recordLogoutTime();
    _pageController.dispose();
    _videoPlayerController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

}
