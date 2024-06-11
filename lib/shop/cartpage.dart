import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
import 'package:bloom_wild/shop/shopflowerspage.dart';
import '../navigate.dart';
import '../payment/stripe_service.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late double _totalPrice;
  late List<QueryDocumentSnapshot> _cartItems;
  late List<int> _quantities;
  final ValueNotifier<int> _itemCountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _cartItems = [];
    _quantities = [];
    _totalPrice = 0;
    _loadCartItems();
  }

  void _loadCartItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
          .collection('user_carts')
          .doc(user.uid)
          .collection('cartItems')
          .get();

      setState(() {
        _cartItems = cartSnapshot.docs;
        _quantities = _cartItems.map((item) => item['quantity'] as int).toList();
        _itemCountNotifier.value = _cartItems.length; // Update the item count
        _calculateTotalPrice();
      });
    }
  }

  void _calculateTotalPrice() {
    _totalPrice = 0;
    for (int i = 0; i < _cartItems.length; i++) {
      double price = double.parse(_cartItems[i]['document']['price'].toString());
      _totalPrice += price * _quantities[i];
    }
  }

  void _updateCartItemQuantity(int index, int quantity) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference cartItemRef = _cartItems[index].reference;
      double price = double.parse(_cartItems[index]['document']['price'].toString());
      double updatedTotalPrice = price * quantity;

      await cartItemRef.update({
        'quantity': quantity,
        'totalPrice': updatedTotalPrice,
      });

      setState(() {
        _quantities[index] = quantity;
        _calculateTotalPrice();
      });
    }
  }

  void _removeCartItem(QueryDocumentSnapshot document) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('user_carts')
          .doc(user.uid)
          .collection('cartItems')
          .doc(document.id)
          .delete();

      setState(() {
        _cartItems.remove(document);
        _itemCountNotifier.value = _cartItems.length; // Update the item count
        _calculateTotalPrice();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _itemCountNotifier,
            builder: (context, itemCount, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart),
                    onPressed: () {
                      // Optionally, navigate to the cart page if needed
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$itemCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  QueryDocumentSnapshot item = _cartItems[index];
                  return _buildCartItem(item, _quantities[index], index);
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Total: \£${_totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Iterate over each cart item and update quantity
                for (int i = 0; i < _cartItems.length; i++) {
                  _updateCartItemQuantity(i, _quantities[i]);
                }
                // Proceed with navigation or any other action
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddressPage(
                      cartItems: _cartItems,
                      quantities: _quantities,
                      totalPrice: _totalPrice,
                    ),
                  ),
                );
              },
              child: Text('SUBMIT'),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(QueryDocumentSnapshot document, int quantity, int index) {
    List<dynamic> images = document['document']['images'] as List<dynamic>;
    String imageUrl = '';

    if (images != null && images.isNotEmpty) {
      imageUrl = images.firstWhere(
            (image) => image is String,
        orElse: () => '',
      );
    }

    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => DescriptionPage(document: document),
        //   ),
        // );
      },
      child: Card(
        child: ListTile(
          leading: SizedBox(
            width: 100,
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
            )
                : Container(), // Placeholder if images list is empty
          ),
          title: Text(document['document']['title']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price: \£${document['document']['price']}'),
              Text('Total Price: \£${(quantity * double.parse(document['document']['price'].toString())).toStringAsFixed(2)}'),
              Row(
                children: [
                  Text('Quantity:'),
                  SizedBox(width: 10),
                  DropdownButton<int>(
                    value: quantity,
                    items: List.generate(6, (index) => index + 1)
                        .map((value) => DropdownMenuItem<int>(child: Text('$value'), value: value))
                        .toList(),
                    onChanged: (value) {
                      _updateCartItemQuantity(index, value!);
                    },
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _removeCartItem(document);
            },
          ),
        ),
      ),
    );
  }
}




class AddressPage extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final List<int> quantities;
  final double totalPrice;

  AddressPage({required this.cartItems, required this.quantities, required this.totalPrice});

  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();

  List<String> countries = [];
  List<String> dates = [];


  bool useMyAddress = false;

  void _fetchData() async {
    final countrySnapshot = await FirebaseFirestore.instance.collection('countries').get();
    final dateSnapshot = await FirebaseFirestore.instance.collection('dateTimes').get();

    setState(() {
      countries = countrySnapshot.docs.map((doc) => doc['country']).toList().cast<String>();
      dates = dateSnapshot.docs.map((doc) => doc['dateTime']).toList().cast<String>();
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchData();
  }


  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: countries.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(countries[index]),
              onTap: () {
                _countryController.text = countries[index];
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: dates.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(dates[index]),
              onTap: () {
                _dateTimeController.text = dates[index];
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    _postCodeController.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cartItems: widget.cartItems,
          quantities: widget.quantities,
          totalPrice: widget.totalPrice,
          addressDetails: {
            'Country': _countryController.text,
            'Post Code': _postCodeController.text,
            'City': _cityController.text,
            'County': _countyController.text,
            'Email': _emailController.text,
            'Phone Number': _phoneNumberController.text,
            'Delivery Date': _dateTimeController.text,
          },
        ),
      ),
    );
  }



  void _useMyAddress() async {
    // Fetch the current user
    User? user = FirebaseAuth.instance.currentUser;

    // Ensure a user is signed in
    if (user != null) {
      // Fetch user address data
      final userData = await FirebaseFirestore.instance.collection('user_address').doc(user.email).get();

      // Check if user's email matches doc(user.email)
      if (userData.exists && userData['email'] == user.email) {
        setState(() {
          useMyAddress = true;
          _countryController.text = userData['country'];
          _postCodeController.text = userData['postCode'];
          _cityController.text = userData['city'];
          _countyController.text = userData['county'];
          _emailController.text = userData['email'];
          _phoneNumberController.text = userData['phoneNumber'];
        });
      }
    }
  }


  void _clearAddressFields() {
    setState(() {
      useMyAddress = false;
      _countryController.clear();
      _postCodeController.clear();
      _cityController.clear();
      _countyController.clear();
      _emailController.clear();
      _phoneNumberController.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Address'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextField(
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_drop_down),
                    onPressed: _showCountryPicker,
                  ),
                ),
                readOnly: true,
              ),
              TextField(
                controller: _postCodeController,
                decoration: InputDecoration(labelText: 'Post Code'),
              ),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: _countyController,
                decoration: InputDecoration(labelText: 'County'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _dateTimeController,
                decoration: InputDecoration(
                  labelText: 'Delivery Date',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_drop_down),
                    onPressed: _showDatePicker,
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _clearAddressFields,
                    child: Text('GIFT ADDRESS'),
                  ),
                  ElevatedButton(
                    onPressed: _useMyAddress,
                    child: Text('USE MY ADDRESS'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _proceedToPayment,
                child: Text('PROCEED TO PAYMENT'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class PaymentPage extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final List<int> quantities;
  final double totalPrice;
  final Map<String, String> addressDetails;

  PaymentPage({
    required this.cartItems,
    required this.quantities,
    required this.totalPrice,
    required this.addressDetails,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late TextEditingController priceController;
  String _paymentMethod = '';
  String _userEmail = '';

  bool _paymentSuccessful = false;




  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(text: widget.totalPrice.toString());
    _fetchUserEmail();
  }

  void _fetchUserEmail() async {
    // Fetch user's email from Firestore collection 'hackerrank_users'
    String currentUserUID = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('hackerrank_users').doc(currentUserUID).get();
    setState(() {
      _userEmail = userSnapshot['email'];
    });
  }


  void _saveOrderToFirestore() {
    // Get the current date and time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);

    // Prepare the order data
    Map<String, dynamic> orderData = {
      'cartItems': widget.cartItems.map((item) => item.data()).toList(),
      'quantities': widget.quantities,
      'totalPrice': widget.totalPrice,
      'addressDetails': widget.addressDetails,
      'paymentMethod': _paymentMethod, // Payment method determined here
      'userEmail': _userEmail, // Add user's email to order data
      'orderDate': formattedDate, // Add date of the order
      'orderTime': formattedTime // Add time of the order
    };

    // Save the order data to user_orders collection
    FirebaseFirestore.instance.collection('user_orders').add(orderData)
        .then((value) {
      //print('Order saved to user_orders collection successfully!');
      // Optionally, send email copy to user
      _sendEmailCopy(orderData);
    })
        .catchError((error) {
      //print('Failed to save order to user_orders collection: $error');
      // Handle error
    });


    // Set payment successful
    setState(() {
      _paymentSuccessful = true;
    });

    // Navigate to the next page after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NavigatePage(), // Replace with your NavigatePage
        ),
      );
    });

    // Save a copy of the order data to admin_all_user_order collection
    FirebaseFirestore.instance.collection('admin_all_user_order').add(orderData)
        .then((value) {
      //print('Copy of order saved to admin_all_user_order collection successfully!');
      // Optionally, perform other actions
    })
        .catchError((error) {
      //print('Failed to save copy of order to admin_all_user_order collection: $error');
      // Handle error
    });
  }


  void _sendEmailCopy(Map<String, dynamic> orderData) async {
    User? user = FirebaseAuth.instance.currentUser;

    final Email email = Email(
      body: 'Your order has been placed successfully.\n\nOrder Details:\n${widget.cartItems.map((item) => item['title']).join('\n')}\n\nTotal Price: \£${widget.totalPrice}\n\nThank you for shopping with us!',
      subject: 'Order Confirmation',
      recipients: [user?.email ?? ''],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      //print('Email copy sent successfully to $_userEmail');
    } catch (error) {
      //print('Failed to send email copy: $error');
      // Handle error
    }
  }


  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }


  Widget _buildCartItem(QueryDocumentSnapshot document, int quantity) {
    final Map<String, dynamic>? documentData = document.data() as Map<String, dynamic>?;

    if (documentData != null && documentData.containsKey('document')) {
      List<dynamic> images = documentData['document']['images'] as List<dynamic>;
      String imageUrl = '';

      if (images != null && images.isNotEmpty) {
        imageUrl = images.firstWhere(
              (image) => image is String,
          orElse: () => '',
        );
      }

      return Card(
        child: ListTile(
          leading: SizedBox(
            width: 100,
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
            )
                : Container(), // Placeholder if images list is empty
          ),
          title: Text(documentData['document']['title'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price: \£${documentData['document']['price'] ?? ''}'),
              Text('Total Price: \£${document['totalPrice'] ?? ''}'),
            ],
          ),
          trailing: Text('Quantity: ${document['quantity'] ?? ''}'),
        ),
      );
    } else {
      return Container(); // Return an empty container if the document or its data is null
    }
  }





  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Payment'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.addressDetails.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text('${entry.key}: ${entry.value}'),
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    QueryDocumentSnapshot item = widget.cartItems[index];
                    return _buildCartItem(item, widget.quantities[index]);
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Checkout: \£${widget.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              // Show payment status
              _paymentSuccessful
                  ? Text(
                'PAYMENT SUCCESSFUL',
                style: TextStyle(color: Colors.green, fontSize: 24),
              )
         :     Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => PaypalCheckout(
                          sandboxMode: true,
                          clientId: "Ab99Av6a70Az6C-DpXoAuI3rHiLtjWEPTmrtZLCO4wVyZ5tnYPcyU4vOKxttFQtvpqIQ8qdn2ON-4BFy",
                          secretKey: "EPsBQSP1Xfcj4v_8f29WNRnkDU-S8lHeFqsBzMHlLyoAdiRQgOIYvYBq752_fhflhkTKcTI9e7ZZTSJE",
                          returnURL: "success.snippetcoder.com",
                          cancelURL: "cancel.snippetcoder.com",
                          transactions:  [
                            {
                              "amount": {
                                "total": priceController.text, // Use the passed price
                                "currency": "GBP",

                              },
                              "description": "Thank you.",


                            }
                          ],
                          note: "Contact us for any questions on your order.",
                          onSuccess: (Map params) async {
                            print("onSuccess: $params");
                            _paymentMethod = 'PayPal'; // Set payment method to PayPal
                            // Save order data to Firestore
                            _saveOrderToFirestore();
                          },
                          onError: (error) {
                            print("onError: $error");
                            Navigator.pop(context);
                          },
                          onCancel: () {
                            print('cancelled:');
                          },
                        ),
                      ));
                    },
                    child: Text('Pay with PAYPAL'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),



                  ElevatedButton(
                    onPressed: () async {
                      // Assuming promotionPrice is the price for the selected duration
                      final double promotionPrice = double.tryParse(priceController.text) ?? 0.0;
                      //final int qty = int.tryParse(qtyPrice ?? "1") ?? 1; // Assuming qtyPrice is the quantity, defaulting to 1 if not set

                      // Prepare the items list for Stripe payment checkout
                      final items = [
                        {
                          "productPrice": promotionPrice,
                          "productName": "Checkout", // Name/description of the product based on selected duration
                          "qty": 1,
                        },
                      ];

                      // Calculate the total amount
                      final totalAmount = promotionPrice * 1;


                      // Now call StripeService to handle the payment
                      StripeService.stripePaymentCheckout(
                        items,
                        totalAmount, // Pass the calculated total amount
                        context,
                        mounted,
                        onSuccess: () {
                          print("SUCCESS");
                          _paymentMethod = 'Stripe'; // Set payment method to Stripe
                          // Save order data to Firestore
                          _saveOrderToFirestore();
                        },
                        onCancel: () {
                          print("Cancel");
                          // Handle cancellation
                        },
                        onError: (e) {
                          print("Error: " + e.toString());
                          // Handle error
                        },
                      );
                    },
                    child: Text('Pay with STRIPE'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

