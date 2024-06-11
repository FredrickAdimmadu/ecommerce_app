import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDeliveryInputPage extends StatefulWidget {
  @override
  _AdminDeliveryInputPageState createState() => _AdminDeliveryInputPageState();
}

class _AdminDeliveryInputPageState extends State<AdminDeliveryInputPage> {
  TextEditingController countryController = TextEditingController();
  TextEditingController dateTimeController = TextEditingController();

  final List<String> countries = [];
  final List<String> dateTimes = [];

  @override
  void initState() {
    super.initState();
    fetchCountries();
    fetchDateTimes();
  }

  void fetchCountries() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('countries').get();
    List<String> fetchedCountries = snapshot.docs.map((doc) => doc['country'].toString()).toList();
    setState(() {
      countries.addAll(fetchedCountries);
    });
  }

  void fetchDateTimes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('dateTimes').get();
    List<String> fetchedDateTimes = snapshot.docs.map((doc) => doc['dateTime'].toString()).toList();
    setState(() {
      dateTimes.addAll(fetchedDateTimes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Delivery Input'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: countryController,
              decoration: InputDecoration(
                labelText: 'Add Country',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                saveCountry();
              },
              child: Text('Save Country'),
            ),
            SizedBox(height: 20.0),
            Text('Manage Countries:'),
            ...countries.map((country) {
              return ListTile(
                title: Text(country),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.update),
                      onPressed: () {
                        updateCountry(country);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteCountry(country);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 20.0),
            TextFormField(
              controller: dateTimeController,
              readOnly: true,
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      dateTimeController.text =
                      '${pickedDate.year}-${pickedDate.month}-${pickedDate.day} ${pickedTime.hour}:${pickedTime.minute}';
                    });
                  }
                }
              },
              decoration: InputDecoration(
                labelText: 'Select Date and Time',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                saveDateTime();
              },
              child: Text('Save DateTime'),
            ),
            SizedBox(height: 20.0),
            Text('Manage DateTimes:'),
            ...dateTimes.map((dateTime) {
              return ListTile(
                title: Text(dateTime),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.update),
                      onPressed: () {
                        updateDateTime(dateTime);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteDateTime(dateTime);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void updateCountry(String oldCountry) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController updateController = TextEditingController(text: oldCountry);
        return AlertDialog(
          title: Text('Update Country'),
          content: TextFormField(
            controller: updateController,
            decoration: InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newCountry = updateController.text;
                if (newCountry.isNotEmpty) {
                  FirebaseFirestore.instance.collection('countries')
                      .where('country', isEqualTo: oldCountry).get().then((snapshot) {
                    snapshot.docs.first.reference.update({
                      'country': newCountry,
                    }).then((_) {
                      setState(() {
                        int index = countries.indexOf(oldCountry);
                        countries[index] = newCountry;
                      });
                      Navigator.pop(context);
                      showMessage('Country updated successfully');
                    }).catchError((error) {
                      print('Failed to update country: $error');
                    });
                  });
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void deleteCountry(String country) {
    FirebaseFirestore.instance.collection('countries')
        .where('country', isEqualTo: country).get().then((snapshot) {
      snapshot.docs.first.reference.delete().then((_) {
        setState(() {
          countries.remove(country);
        });
        showMessage('Country deleted successfully');
      }).catchError((error) {
        print('Failed to delete country: $error');
      });
    });
  }

  void saveCountry() {
    String country = countryController.text;
    if (country.isNotEmpty && !countries.contains(country)) {
      FirebaseFirestore.instance.collection('countries').add({
        'country': country,
      }).then((value) {
        setState(() {
          countries.add(country);
        });
        countryController.clear();
        showMessage('Country saved successfully');
      }).catchError((error) {
        print('Failed to save country: $error');
      });
    }
  }

  void saveDateTime() {
    String dateTime = dateTimeController.text;
    if (dateTime.isNotEmpty && !dateTimes.contains(dateTime)) {
      FirebaseFirestore.instance.collection('dateTimes').add({
        'dateTime': dateTime,
      }).then((value) {
        setState(() {
          dateTimes.add(dateTime);
        });
        dateTimeController.clear();
        showMessage('DateTime saved successfully');
      }).catchError((error) {
        print('Failed to save dateTime: $error');
      });
    }
  }

  void updateDateTime(String oldDateTime) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController updateController = TextEditingController(text: oldDateTime);
        return AlertDialog(
          title: Text('Update DateTime'),
          content: TextFormField(
            controller: updateController,
            readOnly: true,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  updateController.text =
                  '${pickedDate.year}-${pickedDate.month}-${pickedDate.day} ${pickedTime.hour}:${pickedTime.minute}';
                }
              }
            },
            decoration: InputDecoration(
              labelText: 'Date and Time',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newDateTime = updateController.text;
                if (newDateTime.isNotEmpty) {
                  FirebaseFirestore.instance.collection('dateTimes')
                      .where('dateTime', isEqualTo: oldDateTime).get().then((snapshot) {
                    snapshot.docs.first.reference.update({
                      'dateTime': newDateTime,
                    }).then((_) {
                      setState(() {
                        int index = dateTimes.indexOf(oldDateTime);
                        dateTimes[index] = newDateTime;
                      });
                      Navigator.pop(context);
                      showMessage('DateTime updated successfully');
                    }).catchError((error) {
                      print('Failed to update dateTime: $error');
                    });
                  });
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void deleteDateTime(String dateTime) {
    FirebaseFirestore.instance.collection('dateTimes')
        .where('dateTime', isEqualTo: dateTime).get().then((snapshot) {
      snapshot.docs.first.reference.delete().then((_) {
        setState(() {
          dateTimes.remove(dateTime);
        });
        showMessage('DateTime deleted successfully');
      }).catchError((error) {
        print('Failed to delete dateTime: $error');
      });
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
