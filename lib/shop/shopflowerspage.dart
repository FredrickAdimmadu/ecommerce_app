import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'cartpage.dart';

class ShopFlowersPage extends StatefulWidget {
  @override
  _ShopFlowersPageState createState() => _ShopFlowersPageState();
}

class _ShopFlowersPageState extends State<ShopFlowersPage> {

  Set<String> _favoritedItems = Set<String>();


  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  Timer? _itemTimer;
  List<String> _allImages = [];
  bool _isConnected = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _getCurrentUserId();
    _loadFavorites();
    _preloadAllImages();
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

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isConnected = false;
      });
    } else {
      setState(() {
        _isConnected = true;
      });
    }
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _isConnected = false;
        });
      } else {
        setState(() {
          _isConnected = true;
        });
        // Refresh the page if connected
        _reloadPage();
      }
    });
  }

  Future<void> _reloadPage() async {
    setState(() {
      _selectedCategory = 'ALL'; // Reset category
    });
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Shop Flowers'),
        ),
        body: _isConnected
            ? _buildShopPage()
            : Center(
          child: Text('NO INTERNET CONNECTION'),
        ),
      ),
    );
  }




  Widget _buildShopPage() {
    return Column(
      children: [
        SizedBox(height: 10),
        _buildCategoryButtons(),
        SizedBox(height: 10),
        _buildSearchBar(),
        SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFlowerStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              return _buildFlowerList(snapshot.data!.docs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(width: 10),
          _buildCategoryButton('ALL'),
          _buildCategoryButton('BIRTHDAY'),
          _buildCategoryButton('WEDDING'),
          _buildCategoryButton('ANNIVERSARY'),
          _buildCategoryButton('GIFT'),
          _buildCategoryButton('BURIAL'),
          _buildCategoryButton('CELEBRATION'),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedCategory =
          category == _selectedCategory ? 'ALL' : category;
        });
      },
      child: Text(category),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getFlowerStream() {
    return _selectedCategory == 'ALL'
        ? FirebaseFirestore.instance.collection('flower_broadcast').snapshots()
        : FirebaseFirestore.instance
        .collection('flower_broadcast')
        .where('classification', isEqualTo: _selectedCategory)
        .snapshots();
  }

  Widget _buildFlowerList(List<QueryDocumentSnapshot> documents) {
    final filteredDocuments = _searchQuery.isEmpty
        ? documents
        : documents
        .where((doc) =>
        doc['title'].toLowerCase().contains(_searchQuery))
        .toList();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredDocuments.length,
      itemBuilder: (context, index) {
        return _buildFlowerCard(filteredDocuments[index]);
      },
    );
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

  Widget _buildFlowerCard(QueryDocumentSnapshot document) {
    bool isFavorited = _favoritedItems.contains(document.id); // Check if the flower is already favorited by the user

    return GestureDetector(
      onTap: () async {
        await _preloadResources(document);
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




class DescriptionPage extends StatefulWidget {
  final QueryDocumentSnapshot document;

  DescriptionPage({required this.document});

  @override
  _DescriptionPageState createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  VideoPlayerController? _videoPlayerController;
  int _quantity = 1;

  Set<String> _favoritedItems = Set<String>();

  String? _userId;

  @override
  void initState() {
    super.initState();
    final documentData = widget.document.data() as Map<String, dynamic>?;
    if (documentData != null && documentData.containsKey('video')) {
      final video = documentData['video'];
      if (video != null && video.isNotEmpty) {
        _initializeVideoPlayer(video);
        _getCurrentUserId();
        _loadFavorites();
      }
    }
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



  void _initializeVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    _videoPlayerController!.initialize().then((_) {
      setState(() {});
    });
  }

  Widget _buildCarousel() {
    final documentData = widget.document.data() as Map<String, dynamic>?;
    List<Widget> carouselItems = [];

    if (documentData != null && documentData.containsKey('images')) {
      carouselItems.addAll(
        (documentData['images'] as List<dynamic>).map<Widget>((url) {
          return Image.network(url, fit: BoxFit.cover);
        }).toList(),
      );
    }

    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      carouselItems.add(
        AspectRatio(
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          child: VideoPlayer(_videoPlayerController!),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: false,
        aspectRatio: 16 / 9,
        enlargeCenterPage: true,
      ),
      items: carouselItems,
    );
  }


  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _shareItem() {
    final String deepLink = widget.document.id;
    final String title = widget.document['title'];

    Share.share('$title: $deepLink');
  }

  void _addToCart(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final documentData = widget.document.data() as Map<String, dynamic>?;
      if (documentData != null) {
        double totalPrice = double.parse(documentData['price'].toString()) * _quantity;

        DocumentReference userCart = FirebaseFirestore.instance.collection('user_carts').doc(user.uid);
        QuerySnapshot cartSnapshot = await userCart.collection('cartItems')
            .where('productId', isEqualTo: widget.document.id)
            .limit(1)
            .get();

        if (cartSnapshot.docs.isNotEmpty) {
          // If the item is already in the cart, update its quantity
          DocumentSnapshot cartItem = cartSnapshot.docs.first;
          int currentQuantity = cartItem['quantity'];
          int updatedQuantity = currentQuantity + _quantity;
          double updatedTotalPrice = double.parse(documentData['price'].toString()) * updatedQuantity;

          cartItem.reference.update({
            'quantity': updatedQuantity,
            'totalPrice': updatedTotalPrice,
          }).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item quantity updated in the cart')));
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update item quantity')));
          });
        } else {
          // If the item is not in the cart, add it as a new item
          String cartItemId = FirebaseFirestore.instance.collection('user_carts').doc().id;

          userCart.collection('cartItems').doc(cartItemId).set({
            'id': cartItemId,
            'productId': widget.document.id,
            'document': documentData,
            'quantity': _quantity,
            'totalPrice': totalPrice,
          }).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to cart!')));
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to cart')));
          });
        }
      }
    }
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
  Widget build(BuildContext context) {
    final documentData = widget.document.data() as Map<String, dynamic>?;

    double totalPrice = 0;

    if (documentData != null && documentData['price'] != null) {
      totalPrice = double.parse(documentData['price'].toString()) * _quantity;
    }



    bool isFavorited = _favoritedItems.contains(widget.document.id); // Check if the flower is already favorited by the user



    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Description'),
          actions: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                _shareItem();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: documentData != null
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(documentData['title'] ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Check for null title
              Text('Category: ${documentData['classification'] ?? ''}'), // Check for null classification
              if (!isFavorited) // Only show the icon if not favorited
                GestureDetector(
                  onTap: () {
                    _addToFavorites(widget.document);
                  },
                  child: Icon(
                    Icons.favorite_border, // Show empty heart icon if not favorited
                    color: null, // No color by default
                  ),
                ),
              if (isFavorited) // Only show the icon if favorited
                GestureDetector(
                  onTap: () {
                    _removeFromFavorites(widget.document.id);
                  },
                  child: Icon(
                    Icons.favorite, // Show filled heart icon if favorited
                    color: Colors.blue, // Set color to blue if favorited
                  ),
                ),
              SizedBox(height: 10),
              _buildCarousel(),
              SizedBox(height: 10),
              Text('Price: \£${documentData['price'] ?? 0}'), // Provide a default value if price is null
              SizedBox(height: 10),
              Row(
                children: [
                  Text('Quantity:'),
                  SizedBox(width: 10),
                  DropdownButton<int>(
                    value: _quantity,
                    items: List.generate(6, (index) => index + 1)
                        .map((value) => DropdownMenuItem<int>(child: Text('$value'), value: value))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _quantity = value!;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text('Total: \£${totalPrice.toStringAsFixed(2)}'),
              SizedBox(height: 20),
              SingleChildScrollView(
                child: Text(
                  documentData['content'] ?? '', // Check for null content
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressPage(
                            cartItems: [widget.document],
                            quantities: [_quantity],
                            totalPrice: totalPrice,
                          ),
                        ),
                      );
                    },
                    child: Text('BUY NOW'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),

                  ElevatedButton(
                    onPressed: () => _addToCart(context),
                    child: Text('ADD TO CART'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          )
              : Center(child: Text('No data available')),
        ),
      ),
    );
  }

}
