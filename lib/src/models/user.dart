import 'dart:io';

import '../models/media.dart';
import 'rider_type.dart';

class User {
  String id;
  String name;
  String email;
  String password;
  String apiToken;
  String deviceToken;
  String phone;
  int roleID;
  String address;
  String bio;
  Media image;
  bool isActive;
  File NIDFront;
  File NIDBack;
  File licenseFront;
  File licenseBack;
  RiderType riderType;

  // used for indicate if client logged in or not
  bool auth;

//  String role;

  User();

  User.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      id = jsonMap['id'].toString();
      name = jsonMap['name'] != null ? jsonMap['name'] : '';
      email = jsonMap['email'] != null ? jsonMap['email'] : '';
      apiToken = jsonMap['api_token'] ?? '';
      deviceToken = jsonMap['device_token'] ?? '';
      roleID = jsonMap['role_id'] ?? 0;
      isActive = jsonMap['is_active'] != null && jsonMap['is_active'] == "1" ? true : false;
      try {
        phone = jsonMap['custom_fields']['phone']['view'];
      } catch (e) {
        phone = "";
      }
      try {
        address = jsonMap['custom_fields']['address']['view'];
      } catch (e) {
        address = "";
      }
      try {
        bio = jsonMap['custom_fields']['bio']['view'];
      } catch (e) {
        bio = "";
      }
      image = jsonMap['media'] != null && (jsonMap['media'] as List).length > 0 ? Media.fromJSON(jsonMap['media'][0]) : new Media();
      image.url = jsonMap['avatar'] == null ? image.url : jsonMap['avatar'];

      riderType = RiderType.fromJSON(jsonMap['rider_types']);
    } catch (e) {
      print(e);
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["email"] = email;
    map["name"] = name;
    map["password"] = password;
    map["api_token"] = apiToken;
    if (deviceToken != null) {
      map["device_token"] = deviceToken;
    }
    map["role_id"] = 6;
    map["phone"] = phone;
    map["address"] = address;
    map["bio"] = bio;
    map["media"] = image?.toMap();
    return map;
  }

  Map toUpdate() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["email"] = email;
    map["name"] = name;
    map["role_id"] = 6;
    map["password"] = password;
    map["api_token"] = apiToken;
    map["phone"] = phone;
    map["address"] = address;
    map["bio"] = bio;
    map["media"] = image?.toMap();
    return map;
  }

  toJsonFormat() {

    List<Media> mediaList = List();
    mediaList.add(image);

    return {
      "id" : id,
      "email" : email,
      "name" : name,
      "role_id" : 6,
      "password" : password,
      "api_token" : apiToken,
      "deviceToken" : deviceToken == null ? "" : deviceToken,
      "phone" : phone,
      "address" : address,
      "bio" : bio,
      "media" : mediaList.map((media) => media.toJsonFormat()).toList(),
      "rider_types" : riderType.toMap(),
    };
  }

  @override
  String toString() {
    var map = this.toMap();
    map["auth"] = this.auth;
    return map.toString();
  }
}
