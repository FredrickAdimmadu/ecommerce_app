import 'package:flutter/widgets.dart';
import 'package:bloom_wild/resources/auth_methods.dart';

import '../models/hackerrank_user.dart';

class UserProvider with ChangeNotifier {
  HackerrankUser? _user;
  final AuthMethods _authMethods = AuthMethods();



  HackerrankUser get getUser => _user ?? HackerrankUser(
    image: '',
    about: '',
    name: '',
    createdAt: '',
    isOnline: false,
    id: '',
    lastActive: '',
    email: '',
    pushToken: '',
    number: '',
    relationship: '',
    country: '',
    gender: '',
    language: '',
    deviceModel: '',
    deviceVersion: '',
    deviceLocation: '',
    ipAddress: '',
    currentDateTime: '',
    password: '',
    ip_Country: '',
    ip_City: '',
    ip_Region: '',
    ip_Latitude: '',
    ip_Longitude: '',
    ip_RegionCode: '',
    ip_PostCode: '',
    ip_InternetServiceProvider: '',
    ip_Continent: '',
    ip_ContinentCode: '',
    ip_TimeZone: '',
    ip_UTC_time_offset: '',
    ip_CountyCode: '',
    birthday: '',
    birthday_day: '',
    birthday_month: '',
    birthday_year: '',

  );



  Future<void> refreshUser() async {
    HackerrankUser user = await _authMethods.getUserDetails();
    _user = user;
    notifyListeners();
  }
}
