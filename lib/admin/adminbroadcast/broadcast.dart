import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io';

class AdminBroadcastPage extends StatefulWidget {
  @override
  _AdminBroadcastPageState createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles;
  XFile? _videoFile;
  VideoPlayerController? _videoPlayerController;
  DateTime _broadcastDateTime = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles;
      });
    }
  }

  void _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: Duration(seconds: 60));
    if (pickedFile != null) {
      _videoPlayerController?.dispose();
      setState(() {
        _videoFile = pickedFile;
        _videoPlayerController = VideoPlayerController.file(File(pickedFile.path))
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController!.play();
          });
      });
    }
  }

  Future<void> _broadcast() async {
    String title = _titleController.text;
    String content = _contentController.text;

    List<String> imageUrls = [];
    String? videoUrl;

    for (var imageFile in _imageFiles ?? []) {
      File file = File(imageFile.path);
      String fileName = 'broadcast_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    if (_videoFile != null) {
      File video = File(_videoFile!.path);
      String videoName = 'broadcast_videos/${DateTime.now().millisecondsSinceEpoch}_${_videoFile!.name}';
      TaskSnapshot videoSnapshot = await FirebaseStorage.instance.ref(videoName).putFile(video);
      videoUrl = await videoSnapshot.ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('admin_broadcast').add({
      'title': title,
      'content': content,
      'images': imageUrls,
      'video': videoUrl,
      'dateTime': _broadcastDateTime,
      'views': 0,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Broadcast')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _contentController, decoration: InputDecoration(labelText: 'Content')),
            ElevatedButton(onPressed: _pickImages, child: Text('Pick Images')),
            ElevatedButton(onPressed: _pickVideo, child: Text('Pick Video')),
            if (_imageFiles != null && _imageFiles!.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  aspectRatio: 2.0,
                  enlargeCenterPage: true,
                ),
                items: _imageFiles!.map((file) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                        ),
                        child: Image.file(File(file.path), fit: BoxFit.cover),
                      );
                    },
                  );
                }).toList(),
              ),
            if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _broadcast, child: Text('Broadcast')),
          ],
        ),
      ),
    );
  }
}








class AdminBroadcastDeletePage extends StatefulWidget {
  @override
  _AdminBroadcastDeletePageState createState() => _AdminBroadcastDeletePageState();
}

class _AdminBroadcastDeletePageState extends State<AdminBroadcastDeletePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Broadcasts"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admin_broadcast').orderBy('dateTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot broadcast = snapshot.data!.docs[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(broadcast['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(broadcast['content']),
                      SizedBox(height: 10),
                      if (broadcast['images'] != null) _buildImageSlider(broadcast['images']),
                      if (broadcast['video'] != null) VideoPlayerWidget(videoUrl: broadcast['video']),
                      Text('Views: ${broadcast['views'].toString()}'),
                      TextButton(
                        onPressed: () => _deleteBroadcast(broadcast.id),
                        child: Text('DELETE', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageSlider(List<dynamic> imageUrls) {
    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        aspectRatio: 2.0,
        enlargeCenterPage: true,
      ),
      items: imageUrls.map((item) => Container(
          child: Center(
              child: Image.network(item, fit: BoxFit.cover, width: 1000)
          )
      )).toList(),
    );
  }

  void _deleteBroadcast(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this broadcast?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('admin_broadcast').doc(docId).delete();
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}


class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    } else {
      return Center(child: CircularProgressIndicator());
    }
  }
}