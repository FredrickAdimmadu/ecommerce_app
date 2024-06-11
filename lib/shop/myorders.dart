import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';

class MyOrdersPage extends StatelessWidget {
  final String currentUserEmail;

  MyOrdersPage({required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Orders'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user_orders').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
      
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
      
            final orders = snapshot.data!.docs;
            final userOrders = orders.where((order) => order['userEmail'] == currentUserEmail).toList();
      
            if (userOrders.isEmpty) {
              return Center(
                child: Text('No orders found for this user.'),
              );
            }
      
            return ListView.builder(
              itemCount: userOrders.length,
              itemBuilder: (context, index) {
                final orderData = userOrders[index].data() as Map<String, dynamic>;
      
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8.0),
                        Text('User Email: ${orderData['userEmail']}'),
                        Text('Total Price: ${orderData['totalPrice']}'),
                        Text('Payment Method: ${orderData['paymentMethod']}'),
                        Text('Order Date: ${orderData['orderDate']}'),
                        Text('Order Time: ${orderData['orderTime']}'),
                        SizedBox(height: 8.0),
                        Text('Address Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Country: ${orderData['addressDetails']['Country']}'),
                        Text('Post Code: ${orderData['addressDetails']['Post Code']}'),
                        Text('City: ${orderData['addressDetails']['City']}'),
                        Text('County: ${orderData['addressDetails']['County']}'),
                        SizedBox(height: 8.0),
                        Text('Cart Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(orderData['cartItems'].length, (index) {
                            var cartItem = orderData['cartItems'][index];
                            var quantity = orderData['quantities'][index];
      
                            return InkWell(
                              onTap: () {
                                // Display item details dialog box
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(cartItem['document']['title'] ?? 'No Title'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            // Display images in a carousel
                                            if (cartItem['document']['images'] != null &&
                                                cartItem['document']['images'] is List &&
                                                cartItem['document']['images'].isNotEmpty)
                                              Container(
                                                height: 200, // Adjust height as needed
                                                child: CarouselSlider(
                                                  options: CarouselOptions(
                                                    aspectRatio: 16 / 9,
                                                    viewportFraction: 0.9,
                                                    autoPlay: true,
                                                    autoPlayInterval: Duration(seconds: 5),
                                                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                                                    autoPlayCurve: Curves.fastOutSlowIn,
                                                  ),
                                                  items: List.generate(
                                                    cartItem['document']['images'].length,
                                                        (index) => Image.network(
                                                      cartItem['document']['images'][index],
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
      
                                            // Display video if available
                                            if (cartItem['document']['video'] != null &&
                                                cartItem['document']['video'] is String &&
                                                _isValidUrl(cartItem['document']['video']))
                                              Container(
                                                height: 200, // Adjust height as needed
                                                child: VideoPlayerWidget(videoUrl: cartItem['document']['video']),
                                              ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Close'),
                                        ),
                                      ],
                                    );
      
                                  },
                                );
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_cart),
                                  SizedBox(width: 8.0),
                                  Text((cartItem != null && cartItem['document'] != null) ? cartItem['document']['title'] ?? 'No Title' : 'No Title'),
      
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

bool _isValidUrl(String? url) {
  if (url == null) return false;
  final RegExp urlRegExp = RegExp(
    r"^(http|https):\/\/[a-zA-Z0-9\-\.]+(:[0-9]+)?([a-zA-Z0-9\/\-\._~:?#[\]@!$&'()*+,;=%]*)*$",
    caseSensitive: false,
    multiLine: false,
  );
  return urlRegExp.hasMatch(url);
}
