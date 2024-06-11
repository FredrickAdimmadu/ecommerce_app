import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/apis.dart';
import '../models/hackerrank_user.dart';
import '../helper/dialogs.dart';

class ProfileScreen extends StatefulWidget {
  final HackerrankUser user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  TextEditingController _birthdayController = TextEditingController();

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Profile Settings Screen')),
          body: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.size.width * 0.05),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: mq.size.height * 0.03),
                    Stack(
                      children: [
                        _image != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(mq.size.height * 0.1),
                          child: Image.file(
                            File(_image!),
                            width: mq.size.height * 0.2,
                            height: mq.size.height * 0.2,
                            fit: BoxFit.cover,
                          ),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(mq.size.height * 0.1),
                          child: CachedNetworkImage(
                            width: mq.size.height * 0.2,
                            height: mq.size.height * 0.2,
                            fit: BoxFit.cover,
                            imageUrl: widget.user.image,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const CircleAvatar(
                              child: Icon(Icons.error),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MaterialButton(
                            elevation: 1,
                            onPressed: () => _showBottomSheet(),
                            shape: const CircleBorder(),
                            color: Colors.white,
                            child: const Icon(Icons.edit, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mq.size.height * 0.03),
                    Text(
                      widget.user.email,
                      style: const TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    SizedBox(height: mq.size.height * 0.03),
                    Text(
                      'Joined On: ' + widget.user.createdAt,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: mq.size.height * 0.05),
                    _buildTextFormField('Name', widget.user.name, Icons.person, (val) => APIs.me.name = val),
                    _buildTextFormField('About', widget.user.about, Icons.info_outline, (val) => APIs.me.about = val),
                    _buildTextFormField('Phone Number', widget.user.number, Icons.call, (val) => APIs.me.number = val, TextInputType.number),
                    _buildTextFormField('Country', widget.user.country, Icons.flag, (val) => APIs.me.country = val),
                    _buildTextFormField('Gender', widget.user.gender, Icons.person_3_rounded, (val) => APIs.me.gender = val),
                    _buildTextFormField('Language', widget.user.language, Icons.language, (val) => APIs.me.language = val),
                    _buildBirthdayTextFormField('Birthday', widget.user.birthday, Icons.cake, (val) => APIs.me.birthday = val),
                    SizedBox(height: mq.size.height * 0.05),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: Size(mq.size.width * 0.5, mq.size.height * 0.06),
                      ),
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save, size: 28),
                      label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      APIs.updateUserInfo().then((value) {
        Dialogs.showSnackbar(context, 'Profile Updated Successfully!');
      }).catchError((error) {
        Dialogs.showSnackbar(context, 'Error updating profile: $error');
      });
    }
  }

  Widget _buildTextFormField(String label, String initialValue, IconData icon, Function(String) onSave, [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        onSaved: (val) => onSave(val ?? ''),
        validator: (val) => val != null && val.isNotEmpty ? null : 'Required Field',
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: 'eg. ' + label,
          label: Text(label),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildBirthdayTextFormField(String label, String initialValue, IconData icon, Function(String) onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          _selectDate(context, onSave);
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: TextEditingController(text: initialValue), // Update the controller with the initial value
            readOnly: true, // Make the text field read-only
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'eg. ' + label,
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, Function(String) onSave) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formattedDate = "${picked.day}-${picked.month.toString().padLeft(2, '0')}-${picked.year.toString().padLeft(2, '0')}";

      // Save the formatted date into the 'Birthday' field
      onSave(formattedDate);

      // Save picked day into 'birthday_day' field
      APIs.me.birthday_day = picked.day.toString();

      // Save picked month into 'birthday_month' field
      APIs.me.birthday_month = picked.month.toString();

      // Save picked year into 'birthday_year' field
      APIs.me.birthday_year = picked.year.toString();
    }
  }





  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _image = image.path);
      APIs.updateProfilePicture(File(_image!)).catchError((e) {
        Dialogs.showSnackbar(context, 'Error updating image: $e');
      });
      Navigator.pop(context);
    }
  }
}
