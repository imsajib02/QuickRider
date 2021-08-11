import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../helpers/Constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../repository/user_repository.dart';
import '../../helpers/ride_accept_contact.dart';
import '../../models/ride.dart';
import '../../repository/ride/ride_accept_repository.dart';
import '../../repository/settings_repository.dart';
import '../../../generated/l10n.dart';

import 'dart:ui' as ui;

class RideAcceptController {

  RideAcceptRepository _acceptRepo;
  RideAcceptContact _contact;

  AnimationController requestDetailsController;
  AnimationController pickupController;
  AnimationController startedController;
  AnimationController completeController;
  AnimationController beforeStartCancelController;
  AnimationController afterStartCancelController;

  Animation<Offset> _requestDetailsOffset;
  Animation<Offset> _pickupOffset;
  Animation<Offset> _startedOffset;
  Animation<Offset> _completeOffset;
  Animation<Offset> _beforeStartCancelOffset;
  Animation<Offset> _afterStartCancelOffset;

  bool isAllowed = true;
  bool isShown = false;
  bool isFlagged = false;
  bool isInitialized = false;

  TextEditingController _controller = TextEditingController();

  Uint8List pickUpPointBitmap;
  Uint8List destinationPointBitmap;
  Uint8List riderBitmap;
  Uint8List movingBitmap;

  RideAcceptController(TickerProvider tickerProvider, RideAcceptRepository acceptRepo, RideAcceptContact contact) {

    _setMarkerIcon();

    this._acceptRepo = acceptRepo;
    this._contact = contact;

    requestDetailsController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
    _requestDetailsOffset = Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(requestDetailsController);

    pickupController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
    _pickupOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(pickupController);

    startedController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
    _startedOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(startedController);

    completeController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
    _completeOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(completeController);

    beforeStartCancelController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
    _beforeStartCancelOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(beforeStartCancelController);

    afterStartCancelController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
    _afterStartCancelOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(afterStartCancelController);
  }


  SlideTransition requestDetails(BuildContext context, double distance, double fare, String time, Ride ride) {

    return SlideTransition(
      position: _requestDetailsOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: .5,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).estimated_distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(distance.toStringAsFixed(2) + " " + S.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).estimated_time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(time,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).estimated_fare,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(setting.value.defaultCurrency + " " + fare.ceil().toString(),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.dropOffAddress == null ? "" : ride.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Visibility(
                              visible: (ride == null || ride.isTaken == null || !ride.isTaken) || isAllowed,
                              child: Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[

                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () async {

                                          await _contact.removeRide();
                                          Navigator.pop(context);
                                        },
                                        child: Material(
                                          elevation: 10,
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(22),
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                            child: Text(S.of(context).decline.toUpperCase(),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 10,),

                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _acceptRepo.acceptRide(context, ride);
                                        },
                                        child: Material(
                                          elevation: 10,
                                          color: Theme.of(context).accentColor,
                                          borderRadius: BorderRadius.circular(22),
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                            child: Text(S.of(context).accept.toUpperCase(),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 10,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition pickupDetails(BuildContext context, Ride ride) {

    return SlideTransition(
      position: _pickupOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.635,
          minChildSize: 0.22,
          maxChildSize: 0.635,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(S.of(context).pick_up_the_customer,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(S.of(context).pick_up_the_customer_msg,
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 20,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 20,),

                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black54),
                                    ),
                                  ),

                                  SizedBox(width: 10,),

                                  Flexible(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: EdgeInsets.all(12),
                                      margin: EdgeInsets.only(left: 5, right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                      ),
                                      child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 20,),

                            Text(S.of(context).client_details,
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                            ),

                            SizedBox(height: 30,),

                            ride != null && ride.clientAvatar != null ? Padding(
                              padding: EdgeInsets.only(left: 80, right: 80),
                              child: Container(
                                width: 150,
                                height: 170,
                                decoration: BoxDecoration(
                                  image: DecorationImage(image: NetworkImage(ride.clientAvatar), fit: BoxFit.fill),
                                ),
                              ),
                            ) : Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                image: DecorationImage(image: AssetImage("assets/img/test_account.png"), fit: BoxFit.contain),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(ride == null || ride.clientName == null ? "" : ride.clientName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline5,
                              ),
                            ),

                            SizedBox(height: 40,),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  ride == null || ride.clientPhone == null ? null : launch("tel:" + ride.clientPhone);
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.blue[300],
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(S.of(context).call.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 25,),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {

                                        Ride mRide = Ride(id: ride.id, status: Constants.canceled);
                                        _acceptRepo.updateRideInfo(context, mRide);
                                      },
                                      child: Material(
                                        elevation: 10,
                                        color: Colors.red[400],
                                        borderRadius: BorderRadius.circular(22),
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                          child: Text(S.of(context).cancel.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 10,),

                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {

                                        Position position = await Geolocator().getCurrentPosition();
                                        _acceptRepo.startRide(context, ride, position);
                                      },
                                      child: Material(
                                        elevation: 10,
                                        color: Theme.of(context).accentColor,
                                        borderRadius: BorderRadius.circular(22),
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                          child: Text(S.of(context).start.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition startedView(BuildContext context) {

    return SlideTransition(
      position: _startedOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          color: Colors.white,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 30),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[

                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {

                      _confirmRideCancellation(context);
                    },
                    child: Material(
                      elevation: 10,
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                        child: Text(S.of(context).cancel.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 10,),

                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {

                      _contact.finishRide(context);
                    },
                    child: Material(
                      elevation: 10,
                      color: Theme.of(context).accentColor,
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                        child: Text(S.of(context).finish.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  SlideTransition rideCompleted(BuildContext context, Ride ride) {

    return SlideTransition(
      position: _completeOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: .5,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(S.of(context).ride_complete,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.distance == null ? "" : ride.distance + " " + S.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.duration == null ? "" : ride.duration.split(":")[0] + S.of(context).hour + " " +
                                    ride.duration.split(":")[1] + S.of(context).minute,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).fare,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(setting.value.defaultCurrency + " " + (ride == null || ride.rideFee == null ? "" : ride.rideFee),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).admin_commission,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(setting.value.defaultCurrency + " " + (ride == null || ride.adminCommission == null ? "" : ride.adminCommission),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.dropOffAddress == null ? "" : ride.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {

                                  Navigator.pop(context);
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(S.of(context).go_back.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCancelledBeforeStart(BuildContext context, Ride cancelledRide) {

    return SlideTransition(
      position: _beforeStartCancelOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.34,
          minChildSize: 0.34,
          maxChildSize: 0.34,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(S.of(context).ride_cancelled,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled ?
                            (cancelledRide.cancelledBy == currentUser.value.id ? S.of(context).ride_cancelled_by_you : S.of(context).ride_cancelled_by_client_before_pickup) : "",
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 30),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {

                                  Navigator.pop(context);
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(S.of(context).go_back.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCancelledAfterStart(BuildContext context, Ride cancelledRide) {

    return SlideTransition(
      position: _afterStartCancelOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: .5,
          minChildSize: .45,
          maxChildSize: .5,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(S.of(context).ride_cancelled,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled ? (cancelledRide.cancelledBy == currentUser.value.id ?
                            S.of(context).ride_cancelled_by_you : S.of(context).ride_cancelled_by_client_after_started) : "",
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 20,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(cancelledRide == null || cancelledRide.distance == null ? "" : cancelledRide.distance + " " + S.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(cancelledRide == null || cancelledRide.duration == null ? "" : cancelledRide.duration.split(":")[0] + S.of(context).hour + " " +
                                    cancelledRide.duration.split(":")[1] + S.of(context).minute,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            Visibility(
                              visible: cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled && cancelledRide.cancelledBy != currentUser.value.id,
                              child: SizedBox(height: 10,),
                            ),

                            Visibility(
                              visible: cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled && cancelledRide.cancelledBy != currentUser.value.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Text(S.of(context).fare,
                                    style: Theme.of(context).textTheme.subtitle1,
                                  ),

                                  Text(setting.value.defaultCurrency + " " + (cancelledRide == null || cancelledRide.rideFee == null ? "" : cancelledRide.rideFee),
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(S.of(context).cancel_fee,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(setting.value.defaultCurrency + " " + (cancelledRide == null || cancelledRide.cancellationFee == null ? "" : cancelledRide.cancellationFee),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            Visibility(
                              visible: cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled && cancelledRide.cancelledBy != currentUser.value.id,
                              child: SizedBox(height: 10,),
                            ),

                            Visibility(
                              visible: cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled && cancelledRide.cancelledBy != currentUser.value.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Text(S.of(context).admin_commission,
                                    style: Theme.of(context).textTheme.subtitle1,
                                  ),

                                  Text(setting.value.defaultCurrency + " " + (cancelledRide == null || cancelledRide.adminCommission == null ? "" : cancelledRide.adminCommission),
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(cancelledRide == null || cancelledRide.pickupAddress == null ? "" : cancelledRide.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(cancelledRide == null || cancelledRide.dropOffAddress == null ? "" : cancelledRide.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 40,),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {

                                  Navigator.pop(context);
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(S.of(context).go_back.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  Future<List<LatLng>> getPolylineList(LatLng from, LatLng to) async {

    List<LatLng> list = [];

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(setting.value.googleMapsKey, PointLatLng(from.latitude, from.longitude),
        PointLatLng(to.latitude, to.longitude));

    if(result.status == 'OK') {

      list.add(from);

      result.points.forEach((point) {

        list.add(LatLng(point.latitude, point.longitude));
      });

      list.add(to);
    }

    return list;
  }


  Future<void> _setMarkerIcon() async {

    Uint8List bytes = (await NetworkAssetBundle(Uri.parse(currentUser.value.riderType.markerIcon)).load(currentUser.value.riderType.markerIcon)).buffer.asUint8List();
    riderBitmap = await getBytesFromAsset(bytes, 110, 110);
  }


  Future<Uint8List> getBytesFromAsset(Uint8List uint8list, int width, int height) async {

    ui.Codec codec = await ui.instantiateImageCodec(uint8list, targetHeight: height, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }


  void _confirmRideCancellation(BuildContext scaffoldContext) {

    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => false);
          },
          child: AlertDialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Row(
                children: <Widget>[

                  Icon(Icons.error, color: Colors.red, size: 30,),

                  SizedBox(width: 15,),

                  Text(S.of(context).cancel_ride,
                    style: Theme.of(context).textTheme.headline4.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
            content: Text(S.of(context).cancel_ride_confirmation_content, textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.black, fontWeight: FontWeight.normal),
            ),
            contentPadding: EdgeInsets.only(left: 30, top: 20, bottom: 20, right: 30),
            actionsPadding: EdgeInsets.only(right: 20, bottom: 10, top: 5),
            actions: <Widget> [

              FlatButton(
                color: Theme.of(context).accentColor,
                textColor: Colors.white,
                child: Text(S.of(context).yes),
                onPressed: () {

                  Navigator.of(context).pop();
                  _cancellationReason(scaffoldContext);
                },
              ),

              SizedBox(width: 10,),

              FlatButton(
                color: Colors.lightBlueAccent,
                textColor: Colors.white,
                child: Text(S.of(context).no),
                onPressed: () {

                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _cancellationReason(BuildContext scaffoldContext) {

    _controller.text = "";
    bool valid = true;

    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => false);
          },
          child: Dialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {

                return Container(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      Flexible(
                        child: TextField(
                          controller: _controller,
                          enabled: true,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 2,
                          maxLength: 250,
                          style: Theme.of(context).textTheme.bodyText2.copyWith(letterSpacing: .1, wordSpacing: .2, height: 1.3),
                          decoration: InputDecoration(
                            hintText: S.of(context).cancellation_hint,
                            hintStyle: Theme.of(context).textTheme.caption,
                            errorText: !valid ? S.of(context).cancellation_msg_error : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0, style: BorderStyle.none,),
                            ),
                            filled: true,
                            contentPadding: EdgeInsets.all(10),
                            fillColor: Colors.black12.withOpacity(.035),
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),
                      
                      FlatButton(
                        color: Theme.of(context).accentColor,
                        textColor: Colors.white,
                        child: Text(S.of(context).cancel_ride),
                        onPressed: () {

                          if(_controller.text == null || _controller.text.isEmpty) {

                            setState(() {
                              valid = false;
                            });
                          }
                          else {

                            setState(() {
                              valid = true;
                            });

                            Navigator.of(context).pop();
                            _contact.onCancelConfirmed(scaffoldContext, _controller.text);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}