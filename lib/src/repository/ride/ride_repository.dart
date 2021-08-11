import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_configuration/global_configuration.dart';
import '../../models/ride.dart';
import '../../helpers/Constants.dart';
import '../../../generated/l10n.dart';
import '../../helpers/ride_contact.dart';
import '../../helpers/helper.dart';

import 'package:http/http.dart' as http;
import '../user_repository.dart';

ValueNotifier<List<Ride>> rideRequests = ValueNotifier(List());
ValueNotifier<bool> online = ValueNotifier(false);

class RideRepository {

  RideContact _contact;
  OverlayEntry loader;

  //bool isOnline = false;

  RideRepository(RideContact contact) {

    this._contact = contact;

//    if(!isOnline) {
//      _makeRiderOffline();
//    }
  }


  void updateRiderStatus(BuildContext context) {

    loader = Helper.overlayLoader(context);

    final String url = '${GlobalConfiguration().getString('api_base_url')}update-rider-info';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
      'user_id': currentUser.value.id,
      'is_online': !online.value ? Constants.online : Constants.offline
    };

    Overlay.of(context).insert(loader);

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          if(!online.value) {

            _contact.onOnline();
          }
          else {

            _contact.onOffline();
          }
        }
        else {

          _onStatusUpdateFailed(context);
        }
      }
      else {

        _onStatusUpdateFailed(context);
      }

    }).timeout(Duration(seconds: 8), onTimeout: () {

      client.close();
      _contact.onFailed(context, S.of(context).connection_time_out);

    }).whenComplete(() {

      loader.remove();
    });
  }


  void _onStatusUpdateFailed(BuildContext context) {

    if(!online.value) {

      _contact.onFailed(context, S.of(context).failed_to_go_online);
    }
    else {

      _contact.onFailed(context, S.of(context).failed_to_go_offline);
    }
  }


  void _makeRiderOffline() {

    final String url = '${GlobalConfiguration().getString('api_base_url')}update-rider-info';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
      'user_id': currentUser.value.id,
      'is_online': Constants.offline
    };

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

    }).timeout(Duration(seconds: 8), onTimeout: () {

      client.close();
    });
  }


  Future<void> updateRiderLocation(Position position) async {

    final String url = '${GlobalConfiguration().getString('api_base_url')}update-rider-info';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
      'user_id': currentUser.value.id,
      'lat_input': position.latitude.toString(),
      'lng_input': position.longitude.toString(),
      'rotation': position.heading.toString()
    };

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

    }).timeout(Duration(seconds: 8), onTimeout: () {

      client.close();

    });
  }


  Future<void> getActiveRide(BuildContext context) async {

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-check?api_token=${currentUser.value.apiToken}&status=1';

    final client = new http.Client();

    client.get(

      Uri.encodeFull(url),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          _contact.onActiveRideFound(context, Rides.fromJson(jsonData).rides);
        }
        else {

          _contact.onConnectFail(context, S.of(context).could_not_connect);
        }
      }
      else {

        _contact.onConnectFail(context, S.of(context).could_not_connect);
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();
      _contact.onConnectFail(context, S.of(context).could_not_connect);

    }).catchError((error) {

      _contact.onConnectFail(context, S.of(context).could_not_connect);
    });
  }
}