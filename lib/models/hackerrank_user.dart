import 'package:cloud_firestore/cloud_firestore.dart';

class HackerrankUser {
  late String image;
  late String about;
  late String name;
  late String createdAt;
  late bool isOnline;
  late String id;
  late String lastActive;
  late String email;
  late String pushToken;
  late String number;
  late String relationship;
  late String country;
  late String gender;
  late String language;
  late String password;
  late String deviceModel;
  late String deviceVersion;
  late String deviceLocation;
  late String ipAddress;
  late String currentDateTime;
  late String ip_Country ;
  late String ip_City;
  late String ip_Region;
  late String ip_Latitude;
  late String ip_Longitude;
  late String ip_RegionCode;
  late String ip_PostCode;
  late String ip_InternetServiceProvider;
  late String ip_Continent;
  late String ip_UTC_time_offset;
  late String ip_CountyCode;
  late String ip_ContinentCode;
  late String ip_TimeZone;
  late String birthday;
  late String birthday_day;
  late String birthday_month;
  late String birthday_year;



  HackerrankUser({
    required this.image,
    required this.about,
    required this.name,
    required this.createdAt,
    required this.isOnline,
    required this.id,
    required this.lastActive,
    required this.email,
    required this.pushToken,
    required this.number,
    required this.relationship,
    required this.country,
    required this.gender,
    required this.language,
    required this.password,
    required this.deviceModel,
    required this.deviceVersion,
    required this.deviceLocation,
    required this.ipAddress,
    required this.currentDateTime,

    required this.ip_Country  ,
  required this.ip_City  ,
  required this.ip_Region  ,
  required this.ip_Latitude  ,
  required this.ip_Longitude  ,
  required this.ip_RegionCode  ,
  required this.ip_PostCode  ,
  required this.ip_InternetServiceProvider  ,
  required this.ip_Continent  ,
  required this.ip_ContinentCode  ,
  required this.ip_TimeZone  ,
  required this.ip_UTC_time_offset  ,
  required this.ip_CountyCode  ,
    required this.birthday,
    required this.birthday_day,
    required this.birthday_month,
    required this.birthday_year,
  });

  HackerrankUser.fromJson(Map<String, dynamic> json) {
    image = json['image'] ?? '';
    about = json['about'] ?? '';
    name = json['name'] ?? '';
    createdAt = json['created_at'] ?? '';
    isOnline = json['is_online'] ?? false;
    id = json['id'] ?? '';
    lastActive = json['last_active'] ?? '';
    email = json['email'] ?? '';
    pushToken = json['push_token'] ?? '';
    number = json['number'] ?? '';
    relationship = json['relationship'] ?? '';
    country = json['country'] ?? '';
    gender = json['gender'] ?? '';
    language = json['language'] ?? '';
    password = json['password'] ?? '';
    deviceModel = json['deviceModel'] ?? '';
    deviceVersion = json['deviceVersion'] ?? '';
    deviceLocation = json['deviceLocation'] ?? '';
    ipAddress = json['ipAddress'] ?? '';
    currentDateTime = json['dateAndTime'] ?? '';

    ip_Country = json['ip_Country'] ?? '';
    ip_City = json['ip_City'] ?? '';
    ip_Region = json['ip_Region'] ?? '';
    ip_Latitude = json['ip_Latitude'] ?? '';
    ip_Longitude = json['ip_Longitude'] ?? '';
    ip_RegionCode = json['ip_RegionCode'] ?? '';
    ip_PostCode = json['ip_PostCode'] ?? '';
    ip_InternetServiceProvider = json['ip_InternetServiceProvider'] ?? '';
    ip_Continent = json['ip_Continent'] ?? '';
    ip_ContinentCode = json['ip_ContinentCode'] ?? '';
    ip_TimeZone = json['ip_TimeZone'] ?? '';
    ip_UTC_time_offset = json['ip_UTC_time_offset'] ?? '';
    ip_CountyCode = json['ip_CountyCode'] ?? '';
    birthday = json['birthday'] ?? '';
    birthday_day = json['birthday_day'] ?? '';
    birthday_month = json['birthday_month'] ?? '';
    birthday_year = json['birthday_year'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['image'] = image;
    data['about'] = about;
    data['name'] = name;
    data['created_at'] = createdAt;
    data['is_online'] = isOnline;
    data['id'] = id;
    data['last_active'] = lastActive;
    data['email'] = email;
    data['push_token'] = pushToken;
    data['number'] = number;
    data['relationship'] = relationship;
    data['country'] = country;
    data['gender'] = gender;
    data['language'] = language;
    data['deviceModel'] = deviceModel;
    data['deviceVersion'] = deviceVersion;
    data['deviceLocation'] = deviceLocation;
    data['ipAddress'] = ipAddress;
    data['dateAndTime'] = currentDateTime;
    data['ip_Country'] = ip_Country ;
    data['ip_City'] = ip_City;
    data['ip_Region'] = ip_Region;
    data['ip_Latitude'] =ip_Latitude  ;
    data['ip_Longitude'] = ip_Longitude ;
    data['ip_RegionCode'] = ip_RegionCode ;
    data['ip_PostCode'] = ip_PostCode ;
    data['ip_InternetServiceProvider'] = ip_InternetServiceProvider ;
    data['ip_Continent'] = ip_Continent ;
    data['ip_ContinentCode'] = ip_ContinentCode ;
    data['ip_TimeZone'] = ip_TimeZone ;
    data['ip_UTC_time_offset'] = ip_UTC_time_offset ;
    data['ip_CountyCode'] = ip_CountyCode ;
    data['birthday'] = birthday;
    data['birthday_day'] = birthday_day;
    data['birthday_month'] = birthday_month;
    data['birthday_year'] = birthday_year;

    return data;
  }
}
