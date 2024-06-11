import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Broadcast Notifications'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('admin_broadcast').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot broadcast = snapshot.data!.docs[index];
                Map<String, dynamic>? data = broadcast.data() as Map<String, dynamic>?;

                // Safely check if 'readBy' exists and extract its value
                List<dynamic> readBy = data != null && data.containsKey('readBy') ? List.from(data['readBy']) : [];
                bool isRead = readBy.contains(currentUser?.uid);

                return ListTile(
                  title: Text(broadcast['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  subtitle: Text(broadcast['content'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  tileColor: isRead ? null : Colors.lightGreen,  // Highlight unread items
                  onTap: () {
                    if (!isRead) {
                      markAsRead(broadcast.id);
                    }
                    incrementViewCount(broadcast.id);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => BroadcastDetailPage(broadcast: broadcast)
                    ));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void markAsRead(String broadcastId) {
    if (currentUser != null) {
      FirebaseFirestore.instance.collection('admin_broadcast').doc(broadcastId).update({
        'readBy': FieldValue.arrayUnion([currentUser!.uid])
      });
    }
  }

  void incrementViewCount(String broadcastId) {
    FirebaseFirestore.instance.collection('admin_broadcast').doc(broadcastId).update({
      'views': FieldValue.increment(1)
    });
  }
}



class BroadcastDetailPage extends StatefulWidget {
  final DocumentSnapshot broadcast;

  BroadcastDetailPage({required this.broadcast});

  @override
  _BroadcastDetailPageState createState() => _BroadcastDetailPageState();
}

class _BroadcastDetailPageState extends State<BroadcastDetailPage> {
  VideoPlayerController? videoController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  void initializeVideo() {
    String? videoUrl = widget.broadcast['video'];
    if (videoUrl != null) {
      videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            videoController!.play();
            videoController!.setLooping(true);
          });
        }).catchError((e) {
          print("Error initializing video player: $e");
        });
      _initializeVideoPlayerFuture = videoController!.initialize();
    }
  }

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = List<String>.from(widget.broadcast['images'] ?? []);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.broadcast['title'])),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.broadcast['title'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.broadcast['content']),
              ),
              if (images.isNotEmpty) CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16/9,
                ),
                items: images.map((item) => Container(
                  child: Center(
                      child: Image.network(item, fit: BoxFit.cover, width: 1000)
                  ),
                )).toList(),
              ),
              if (videoController != null && videoController!.value.isInitialized) FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      height: 200, // Fixed height for video
                      child: AspectRatio(
                        aspectRatio: videoController!.value.aspectRatio,
                        child: VideoPlayer(videoController!),
                      ),
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}