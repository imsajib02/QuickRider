import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'ride/ride_accept_controller.dart';
import '../helpers/Constants.dart';
import '../repository/ride/ride_accept_repository.dart';
import '../models/ride.dart';

import '../../generated/l10n.dart';
import '../helpers/custom_trace.dart';
import '../repository/settings_repository.dart' as settingRepo;
import '../repository/user_repository.dart' as userRepo;
import '../repository/ride/ride_repository.dart';

class SplashScreenController extends ControllerMVC with ChangeNotifier {
  ValueNotifier<Map<String, double>> progress = new ValueNotifier(new Map());
  GlobalKey<ScaffoldState> scaffoldKey;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();

  SplashScreenController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    // Should define these variables before the app loaded
    progress.value = {"Setting": 0, "User": 0};
  }

  @override
  void initState() {
    super.initState();
    firebaseMessaging.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
    configureFirebase(firebaseMessaging);
    settingRepo.setting.addListener(() {
      if (settingRepo.setting.value.appName != null && settingRepo.setting.value.appName != '' && settingRepo.setting.value.mainColor != null) {
        progress.value["Setting"] = 41;
        progress?.notifyListeners();
      }
    });
    userRepo.currentUser.addListener(() {
      if (userRepo.currentUser.value.auth != null) {
        progress.value["User"] = 59;
        progress?.notifyListeners();
      }
    });
    Timer(Duration(seconds: 20), () {
      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).verify_your_internet_connection),
      ));
    });
  }

  void configureFirebase(FirebaseMessaging _firebaseMessaging) {
    try {
      _firebaseMessaging.configure(
        onMessage: notificationOnMessage,
        onLaunch: notificationOnLaunch,
        onResume: notificationOnResume,
      );
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
      print(CustomTrace(StackTrace.current, message: 'Error Config Firebase'));
    }
  }

  Future notificationOnResume(Map<String, dynamic> message) async {

    if(message['data']['id'] == "ride_request") {

      _showRideRequest(message, false);
    }
    else if(message['data']['id'] == "ride_canceled") {

      _onRideCancelled(message, false);
    }
  }

  Future notificationOnLaunch(Map<String, dynamic> message) async {

    if(message['data']['id'] == "ride_request") {

      _showRideRequest(message, false);
    }
    else if(message['data']['id'] == "ride_canceled") {

      _onRideCancelled(message, false);
    }
  }

  Future notificationOnMessage(Map<String, dynamic> message) async {

    print(message);

    if(message['data']['id'] == "ride_request") {

      _showRideRequest(message, true);
    }
    else if(message['data']['id'] == "ride_canceled") {

      _onRideCancelled(message, true);
    }
  }

  Future<void> _showRideRequest(Map<String, dynamic> message, bool isForeground) async {

    try {

      Ride ride = Ride.fromJson(message);
      ride.id = message['data']['ride_id'] as String;

      var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.pickupPoint.latitude, ride.pickupPoint.longitude));
      ride.pickupAddress = addresses.first.addressLine;

      addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.dropOffPoint.latitude, ride.dropOffPoint.longitude));
      ride.dropOffAddress = addresses.first.addressLine;

      if(ride != null && ride.clientID != null) {

        rideRequests.value.add(ride);
        rideRequests.notifyListeners();

        if(!isForeground) {
          Navigator.of(context).pushNamed('/Pages', arguments: 1);
        }
      }
    }
    catch (e) {
      print(e);
    }
  }

  Future<void> _onRideCancelled(Map<String, dynamic> message, bool isForeground) async {

    try {

      Ride ride = Ride.fromJson(message);
      ride.id = message['data']['ride_id'] as String;
      ride.status = Constants.canceled;

      try {

        if(ride.pickupPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.pickupPoint.latitude, ride.pickupPoint.longitude));
          ride.pickupAddress = addresses.first.addressLine;
        }

        if(ride.dropOffPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.dropOffPoint.latitude, ride.dropOffPoint.longitude));
          ride.dropOffAddress = addresses.first.addressLine;
        }
      }
      catch (e) {}

      if(ride != null) {

        if(!isForeground) {
          Navigator.of(context).pushNamed('/Pages', arguments: 1);
        }
        else {

          rideNotifier.value = ride;
          rideNotifier.notifyListeners();
        }
      }
    }
    catch (e) {
      print(e);
    }
  }
}
