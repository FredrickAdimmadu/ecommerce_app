import 'package:bloom_wild/shop/shopflowerspage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FavouritesPage extends StatefulWidget {
  final String userId;

  FavouritesPage({required this.userId});

  @override
  _FavouritesPageState createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {

  List<String> _allImages = [];
  Set<String> _favoritedItems = Set<String>();

  Timer? _itemTimer;



  @override
  void initState() {
    super.initState();
    _preloadAllImages();
    _fetchFavoritedItems();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Favorites'),
        ),
        body: _buildFavoritesPage(),
      ),
    );
  }

  Widget _buildFavoritesPage() {
    return SafeArea(
      child: StreamBuilder(
        stream: _fetchFavoritesStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
            if (documents.isEmpty) {
              return Center(
                child: Text('No favorites found.'),
              );
            }
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                QueryDocumentSnapshot document = documents[index];
                return _buildFavoriteCard(context, document);
              },
            );
          }
        },
      ),
    );
  }





  Widget _buildFavoriteCard(BuildContext context, QueryDocumentSnapshot document) {
    bool isFavorited = _favoritedItems.contains(document.id);

    return SafeArea(
      child: GestureDetector(
        onTap: () {
          _itemTimer?.cancel(); // Cancel previous timer
          _itemTimer = Timer(Duration(seconds: 4), () {
            // Trigger action if user spends more than 4 seconds
            _savePersonalizedFlower(document);
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
                    return Image.network(
                      document['images'][0],
                      fit: BoxFit.cover,
                    );
                  } else {
                    return SpinKitFadingCircle(
                      itemBuilder: (BuildContext context, int index) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: index.isEven ? Colors.red : Colors.green,
                          ),
                        );
                      },
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
                    Text('Price: £${double.parse(document['price'].toString())}'),
                    GestureDetector(
                      onTap: () {
                        toggleFavorite(document);
                      },
                      child: Icon(
                        isFavorited ? Icons.remove_circle : Icons.remove_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _fetchFavoritesStream() {
    return FirebaseFirestore.instance.collection('favorites').doc(widget.userId).collection('items').snapshots();
  }

  Future<void> _preloadImage(String imageUrl) {
    return precacheImage(NetworkImage(imageUrl), context);
  }

  void toggleFavorite(QueryDocumentSnapshot document) {
    String productId = document.id;
    if (_favoritedItems.contains(productId)) {
      _removeFromFavorites(productId);
    } else {
      _addToFavorites(document);
    }
    setState(() {
      _favoritedItems.contains(productId) ? _favoritedItems.remove(productId) : _favoritedItems.add(productId);
    });
  }

  void _fetchFavoritedItems() async {
    CollectionReference favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(widget.userId).collection('items');
    QuerySnapshot favoritesSnapshot = await favoritesRef.get();
    for (QueryDocumentSnapshot doc in favoritesSnapshot.docs) {
      String productId = doc.id;
      DocumentSnapshot flowerSnapshot = await FirebaseFirestore.instance.collection('flower_broadcast').doc(productId).get();
      if (!flowerSnapshot.exists) {
        // If the flower doesn't exist in 'flower_broadcast', remove it from favorites
        _removeFromFavorites(productId);
      } else {
        _favoritedItems.add(productId);
      }
    }
  }


  Future<void> _preloadAllImages() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('flower_broadcast').get();
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

  void _removeFromFavorites(String productId) async {
    CollectionReference favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(widget.userId).collection('items');
    await favoritesRef.doc(productId).delete();
  }

  void _addToFavorites(QueryDocumentSnapshot document) async {
    CollectionReference favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(widget.userId).collection('items');
    await favoritesRef.add(document.data());
  }

  void _incrementViewCount(String docId) {
    FirebaseFirestore.instance.collection('flower_broadcast').doc(docId).update({
      'views': FieldValue.increment(1),
    });
  }

  void _savePersonalizedFlower(QueryDocumentSnapshot document) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the email of the current user
    String? userEmail = FirebaseAuth.instance.currentUser!.email;

    // Get a reference to the personalized flowers collection for the current user
    CollectionReference personalizedFlowersRef = FirebaseFirestore.instance.collection('personalized_flowers').doc(userId).collection('items');

    // Get the document ID of the selected flower
    String flowerId = document.id;

    // Check if the flower is already personalized by the user
    DocumentSnapshot personalizedFlowerSnapshot = await personalizedFlowersRef.doc(flowerId).get();
    if (personalizedFlowerSnapshot.exists) {
      // Flower already personalized, handle accordingly (e.g., show message)
      // print('This flower is already personalized by the user.');
      return;
    }

    // Flower not personalized, proceed to copy and save it
    await personalizedFlowersRef.doc(flowerId).set({
      'userId': userId, // Store user ID
      'email': userEmail, // Store user email
      'images': List<String>.from(document['images']),
      'video': document['video'],
      'title': document['title'],
      'price': document['price'],
      'classification': document['classification'],
      'content': document['content'],
    });

  }
}





