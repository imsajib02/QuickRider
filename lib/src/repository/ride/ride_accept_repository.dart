import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../helpers/my_ride_contact.dart';
import '../../../generated/l10n.dart';
import '../../models/cancel_notofier.dart';
import '../../helpers/helper.dart';

import '../../models/ride.dart';
import '../../helpers/ride_accept_contact.dart';
import '../settings_repository.dart';

import 'package:http/http.dart' as http;

import '../user_repository.dart';

ValueNotifier<Ride> rideNotifier = ValueNotifier(Ride(id: "", status: ""));

class RideAcceptRepository {

  RideAcceptContact contact;
  MyRideContact myRideContact;
  OverlayEntry loader;

  RideAcceptRepository({this.contact, this.myRideContact});


  Future<void> acceptRide(BuildContext context, Ride ride) async {

    if(currentUser.value != null && currentUser.value.image.url != null && currentUser.value.image.url.isNotEmpty) {

      loader = Helper.overlayLoader(context);

      final String url = '${GlobalConfiguration().getString('api_base_url')}accept-ride';

      final client = new http.Client();

      Map<String, dynamic> body = {
        'api_token': currentUser.value.apiToken,
        'id': ride.id
      };

      Overlay.of(context).insert(loader);

      client.post(

        Uri.encodeFull(url),
        body: json.encode(body),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},

      ).then((response) async {

        print(response.body);

        var jsonData = json.decode(response.body);

        if(response.statusCode == 200 || response.statusCode == 201) {

          if(jsonData['status']) {

            contact.removeRide();
            contact.onRideAccepted(Ride.fromJson(jsonData));
          }
          else {

            if(jsonData['message'] == "You can not accept!") {

              contact.rideOnGoing(context);
            }
            else if(jsonData['message'] == "Rider Already Accepted!") {

              contact.onRideAcceptDenied(context, S.of(context).ride_taken);
            }
            else if(jsonData['message'] == "Client has canceled this request!") {

              contact.onRideAcceptDenied(context, S.of(context).ride_request_canceled);
            }
            else {

              contact.onFailed(context, S.of(context).failed_to_accept_ride);
            }
          }
        }
        else {

          contact.onFailed(context, S.of(context).failed_to_accept_ride);
        }

      }).timeout(Duration(seconds: 5), onTimeout: () {

        client.close();
        contact.onFailed(context, S.of(context).connection_time_out);

      }).whenComplete(() {

        loader.remove();
      });
    }
    else {

      contact.onFailed(context, S.of(context).set_profile_image);
    }
  }


  Future<void> startRide(BuildContext context, Ride ride, Position position) async {

    loader = Helper.overlayLoader(context);

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-info-update';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
      'id': ride.id,
      'ride_status': '4',
      'pickup_point': position.latitude.toString() + "," + position.longitude.toString(),
    };

    Overlay.of(context).insert(loader);

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) async {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          contact.onRideStarted(Ride.fromJson(jsonData));
        }
        else {

          if(jsonData['message'] == "Ride already started!!") {

            contact.onFailed(context, S.of(context).ride_already_started);
          }
          else {

            contact.onFailed(context, S.of(context).failed_to_start_the_ride);
          }
        }
      }
      else {

        contact.onFailed(context, S.of(context).failed_to_start_the_ride);
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();
      contact.onFailed(context, S.of(context).connection_time_out);

    }).whenComplete(() {

      loader.remove();
    });
  }


  Future<void> updateRideInfo(BuildContext context, Ride ride, {List<LatLng> paths}) async {

    loader = Helper.overlayLoader(context);

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-info-update';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
    };

    body.addAll(ride.toJson());

    if(ride.pickupPoint != null) {

      body['pickup_point'] =  ride.pickupPoint.latitude.toString() + "," + ride.pickupPoint.longitude.toString();
    }

    if(ride.dropOffPoint != null) {

      body['dropoff_point'] =  ride.dropOffPoint.latitude.toString() + "," + ride.dropOffPoint.longitude.toString();
    }

    Overlay.of(context).insert(loader);

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          if(contact != null) {

            contact.onRideCancelled(context, Ride.fromJson(jsonData), paths: paths);
          }
          else if(myRideContact != null) {

            myRideContact.onReviewSuccess(context, Ride.fromJson(jsonData));
          }
        }
        else {

          if(contact != null) {

            contact.onFailed(context, S.of(context).failed_to_cancel_ride);
          }
          else if(myRideContact != null) {

            myRideContact.onReviewFailed(context);
          }
        }
      }
      else {

        if(contact != null) {

          contact.onFailed(context, S.of(context).failed_to_cancel_ride);
        }
        else if(myRideContact != null) {

          myRideContact.onReviewFailed(context);
        }
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();

      if(contact != null) {

        contact.onFailed(context, S.of(context).connection_time_out);
      }
      else if(myRideContact != null) {

        myRideContact.onFailed(context, S.of(context).connection_time_out);
      }

    }).whenComplete(() {

      loader.remove();
    });
  }


  Future<void> finishRide(BuildContext context, Ride ride, double distance, double fare, double adminCommission, List<LatLng> paths) async {

    loader = Helper.overlayLoader(context);

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-info-update';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
      'id': ride.id,
      'ride_status': '3',
      'distance': distance.toStringAsFixed(2),
      'dropoff_point': ride.dropOffPoint.latitude.toString() + "," + ride.dropOffPoint.longitude.toString(),
      'ride_fee': fare.ceil().toString(),
      'admin_com_fee': adminCommission.toStringAsFixed(3)
    };

    Overlay.of(context).insert(loader);

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) async {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          contact.onRideComplete(Ride.fromJson(jsonData), paths);
        }
        else {

          contact.onFailed(context, S.of(context).failed_to_finish_ride);
        }
      }
      else {

        contact.onFailed(context, S.of(context).failed_to_finish_ride);
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();
      contact.onFailed(context, S.of(context).connection_time_out);

    }).whenComplete(() {

      loader.remove();
    });
  }


  Future<void> getRideHistory(BuildContext context) async {

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-check?api_token=${currentUser.value.apiToken}&status=2';

    final client = new http.Client();

    client.get(

      Uri.encodeFull(url),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          myRideContact.showMyRides(Rides.fromJson(jsonData).rides);
        }
        else {

          myRideContact.onFailed(context, S.of(context).failed_to_get_ride_history);
        }
      }
      else {

        myRideContact.onFailed(context, S.of(context).failed_to_get_ride_history);
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();
      myRideContact.onFailed(context, S.of(context).connection_time_out);

    }).catchError((error) {

      myRideContact.onFailed(context, S.of(context).failed_to_get_ride_history);
    });
  }
}