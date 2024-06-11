import 'package:bloom_wild/admin/pushnotification/pushnotification.dart';
import 'package:bloom_wild/admin/pushnotification/pushnotificationcounts.dart';
import 'package:flutter/material.dart';
import 'adminbroadcast/broadcast.dart';
import 'admindeliveryaction/admindeliveyaction.dart';
import 'ecommerce/adminalluserorders.dart';
import 'ecommerce/ecommercepostpage.dart';



class AdminPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard'),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: <Widget>[
            _createCard('BROADCAST', Colors.grey, Icons.broadcast_on_personal, context, BroadcastPage()),
            _createCard('E-COMMERCE', Colors.purple, Icons.sell, context, ECommercePage()),

          ],
        ),
      ),
    );
  }

  Widget _createCard(String title, Color color, IconData icon, BuildContext context, Widget destinationPage) {
    return SafeArea(
      child: Card(
        color: color,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationPage),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 40.0, color: Colors.white),
                Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BroadcastPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Broadcast'),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: <Widget>[
            _createCard('MAKE BROADCAST', Colors.tealAccent, Icons.broadcast_on_personal, context, AdminBroadcastPage()),
            _createCard('BROADCAST ACTION', Colors.brown, Icons.broadcast_on_personal, context, AdminBroadcastDeletePage()),
          ],
        ),
      ),
    );
  }






  Widget _createCard(String title, Color color, IconData icon, BuildContext context, Widget destinationPage) {
    return SafeArea(
      child: Card(
        color: color,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationPage),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 40.0, color: Colors.white),
                Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ECommercePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('E-Commerce'),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(20),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: <Widget>[
            _createCard('SEND PUSH NOTIFICATION', Colors.lightBlue, Icons.doorbell_outlined, context, PushNotificationPage()),
            _createCard('PUSH NOTIFICATION DATA', Colors.lightBlue, Icons.doorbell_outlined, context, PushNotificationCountsPage()),
            _createCard('DELIVERY DATA INPUT', Colors.greenAccent, Icons.admin_panel_settings_sharp, context, AdminDeliveryInputPage()),
            _createCard('POST FLOWERS', Colors.purple, Icons.sell, context, ECommercePostPage()),
            _createCard('ACTION', Colors.purple, Icons.dashboard, context, FlowerBroadcastDeletePage()),
            _createCard('USERS ORDERS', Colors.red, Icons.shopping_cart, context, AdminAllUsersOrderPage()),
          ],
        ),
      ),
    );
  }














  Widget _createCard(String title, Color color, IconData icon, BuildContext context, Widget destinationPage) {
    return SafeArea(
      child: Card(
        color: color,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destinationPage),
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 40.0, color: Colors.white),
                Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

