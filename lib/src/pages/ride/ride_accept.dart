import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:screen/screen.dart';
import '../../helpers/dbhelper.dart';
import '../../controllers/ride/ride_accept_controller.dart';
import '../../repository/user_repository.dart';
import '../../helpers/Constants.dart';
import '../../repository/ride/ride_accept_repository.dart';
import '../../../generated/l10n.dart';
import '../../helpers/ride_accept_contact.dart';
import '../../models/ride.dart';
import '../../repository/ride/ride_repository.dart';

import 'dart:ui' as ui;

class RideAccept extends StatefulWidget {

  final Ride _ride;

  RideAccept(this._ride);

  @override
  _RideAcceptState createState() => _RideAcceptState();
}

class _RideAcceptState extends State<RideAccept> with TickerProviderStateMixin implements RideAcceptContact {

  GoogleMapController _controller;

  LocationOptions locationOptions;
  StreamSubscription<Position> positionStream;

  CameraPosition _initialPosition = CameraPosition(
    bearing: 0.0,
    tilt: 0.0,
    target: LatLng(23.759398, 90.378904),
    zoom: 6.5,
  );

  RideAcceptController _acceptController;
  RideAcceptRepository _acceptRepo;
  RideAcceptContact _contact;

  Set<Marker> _markers = Set();
  Set<Polyline> _polyLines = Set();

  double _distance = 0.0;
  double _fare = 0.0;
  double _adminCommission = 0.0;

  String _time = "";
  String _appBarTitle = "";

  Ride _acceptedRide;
  DbHelper _dbHelper;


  @override
  void initState() {

    _contact = this;
    _acceptRepo = RideAcceptRepository(contact: _contact);
    _acceptController = RideAcceptController(this, _acceptRepo, _contact);
    _dbHelper = DbHelper();

    locationOptions = LocationOptions(accuracy: LocationAccuracy.best, timeInterval: 2);

    positionStream = Geolocator().getPositionStream(locationOptions).listen((Position position) {

      if(position != null && _acceptedRide != null) {

        if(_acceptedRide.status == Constants.accepted) {

          _showRouteToPickupPoint(position);
        }
        else if(_acceptedRide.status == Constants.started) {

          _dbHelper.storePath(position);
          _showCurrentLocation(position);
        }
      }
    });

    super.initState();
  }


  @override
  void didChangeDependencies() {

    _initBitmapIcons();

    if(_acceptedRide == null) {
      _appBarTitle = S.of(context).new_request;
    }

    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 5,
          title: Text(_appBarTitle,
            style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3)),
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: rideNotifier,
          builder: (BuildContext context, Ride rideNotifier, _) {

            if(rideNotifier != null && _acceptedRide != null && _acceptedRide.id != null && rideNotifier.id == _acceptedRide.id && rideNotifier.status == Constants.canceled &&
                (_acceptedRide.status == Constants.accepted || _acceptedRide.status == Constants.started) && !_acceptController.isFlagged) {

              Screen.keepOn(false);

              _acceptController.isFlagged = true;
              positionStream.cancel();

              try {
                setState(() {
                  _markers.clear();
                  _polyLines.clear();
                });
              }
              catch(e) {
                _markers.clear();
                _polyLines.clear();
              }

              if(_acceptedRide.status == Constants.accepted) {

                _acceptController.pickupController.reverse();
                _acceptController.beforeStartCancelController.forward();
              }
              else if(_acceptedRide.status == Constants.started) {

                _acceptController.startedController.reverse();
                _showRouteTillHere(rideNotifier);
              }
            }

            return Stack(
              children: <Widget>[

                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onTap: (LatLng latLng) {},
                  onLongPress: (LatLng latLng) {},
                  onMapCreated: (GoogleMapController controller) async {

                    _controller = controller;

                    if(_polyLines.length == 0) {

                      if(widget._ride.status == null || widget._ride.status.isEmpty) {

                        List<LatLng> latLngs = await _acceptController.getPolylineList(widget._ride.pickupPoint, widget._ride.dropOffPoint);
                        showRequestedRideRoute(latLngs);
                      }
                      else if(widget._ride.status == Constants.accepted) {

                        if(widget._ride.pickupPoint != null) {

                          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(widget._ride.pickupPoint.latitude, widget._ride.pickupPoint.longitude));
                          widget._ride.pickupAddress = addresses.first.addressLine;
                        }

                        Timer.periodic(Duration(milliseconds: 1200), (timer) {

                          if(_acceptController.isInitialized) {

                            timer.cancel();
                            onRideAccepted(widget._ride);
                          }
                        });
                      }
                      else if(widget._ride.status == Constants.started) {

                        Timer.periodic(Duration(milliseconds: 1200), (timer) {

                          if(_acceptController.isInitialized) {

                            timer.cancel();

                            Screen.keepOn(true);
                            _acceptedRide = widget._ride;
                            onRideStarted(widget._ride);
                          }
                        });
                      }
                    }
                  },
                  onCameraMove: (CameraPosition cameraPosition) {},
                  onCameraIdle: () {},
                  markers: _markers,
                  polylines: _polyLines,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  mapType: MapType.normal,
                  myLocationEnabled: _acceptedRide == null ? true : false,
                  myLocationButtonEnabled: true,
                  trafficEnabled: false,
                ),

                _acceptController.requestDetails(context, _distance, _fare, _time, widget._ride),

                _acceptController.pickupDetails(context, _acceptedRide),

                _acceptController.startedView(context),

                _acceptController.rideCompleted(context, _acceptedRide),

                _acceptController.rideCancelledBeforeStart(context, rideNotifier),

                _acceptController.rideCancelledAfterStart(context, rideNotifier),
              ],
            );
          },
        ),
      )
    );
  }


  @override
  void dispose() {

    positionStream.cancel();

    _acceptController.requestDetailsController.dispose();
    _acceptController.pickupController.dispose();
    _acceptController.startedController.dispose();
    _acceptController.completeController.dispose();
    _acceptController.beforeStartCancelController.dispose();
    _acceptController.afterStartCancelController.dispose();

    super.dispose();
  }


  Future<bool> _onBackPressed() async {

    bool value = true;

    if(_acceptedRide != null && _acceptedRide.status != null && (_acceptedRide.status == Constants.accepted || _acceptedRide.status == Constants.started)) {

      value = false;
    }

    return Future(() => value);
  }


  Future<void> _initBitmapIcons() async {

    _acceptController.pickUpPointBitmap = await _getBytesFromAsset('assets/img/blue_pin.png', 150, 150);
    _acceptController.destinationPointBitmap = await _getBytesFromAsset('assets/img/orange_pin.png', 150, 150);
    _acceptController.movingBitmap = await _getBytesFromAsset('assets/img/moving_marker_2.png', 90, 90);

    _acceptController.isInitialized = true;
  }


  Future<Uint8List> _getBytesFromAsset(String path, int width, int height) async {

    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: height, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }


  Future<void> _getDistance(List<LatLng> latLngs) async {

    double distance = 0.0;
    var p = 0.017453292519943295;
    var c = cos;

    for(int i=0; i<latLngs.length - 1; i++) {

      var a = 0.5 - c((latLngs[i+1].latitude - latLngs[i].latitude) * p) / 2 + c(latLngs[i].latitude * p) * c(latLngs[i+1].latitude * p) * (1 - c((latLngs[i+1].longitude - latLngs[i].longitude) * p)) / 2;
      distance += 12742 * asin(sqrt(a));
    }

    _calculateTime(distance);

    setState(() {
      _distance = distance;
      _fare = distance * double.parse(currentUser.value.riderType.fee);
      _adminCommission = (double.parse(currentUser.value.riderType.adminCommission) * _fare) / 100;
    });
  }


  Future<void> _calculateTime(double distance) async {

    double time = distance / double.parse(currentUser.value.riderType.speed);

    if(time > 1.0) {

      setState(() {
        _time = time.floor().toString() + " " + S.of(context).hour + " " + ((time - time.floorToDouble()) * 60.0).ceil().toString();
      });
    }
    else if(time == 1.0) {

      setState(() {
        _time = "1 " + S.of(context).hour;
      });
    }
    else {

      setState(() {
        _time = (time * 60.0).ceil().toString() + " " + S.of(context).minute;
      });
    }
  }


  Future<void> _createPickUpMarker(LatLng latLng) async {

    Marker pickupMarker = Marker(
      markerId: Constants.PICK_UP_POINT_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: S.of(context).pick_up_point),
      icon: BitmapDescriptor.fromBytes(_acceptController.pickUpPointBitmap),
    );

    _placeMarkerOnMap(pickupMarker, true);
  }


  Future<void> _createDropOffMarker(LatLng latLng) async {

    print("yessssssssssssssssssssssssssssssssssssssssssssssss");

    Marker dropOffMarker = Marker(
      markerId: Constants.DROP_OFF_POINT_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: S.of(context).drop_off_point),
      icon: BitmapDescriptor.fromBytes(_acceptController.destinationPointBitmap),
    );

    _placeMarkerOnMap(dropOffMarker, true);
  }


  Future<void> _createRiderLocationMarker(Position position) async {

    Marker userLocation = Marker(
      markerId: Constants.USER_LOCATION_MARKER,
      position: LatLng(position.latitude, position.longitude),
      rotation: position.heading,
      draggable: false,
      flat: true,
      zIndex: 2,
      anchor: Offset(0.5, 0.5),
      icon: BitmapDescriptor.fromBytes(_acceptController.riderBitmap),
    );

    _placeMarkerOnMap(userLocation, false);
  }


  Future<void> _placeMarkerOnMap(Marker marker, bool showInfo) async {

    try {
      setState(() {
        _markers.add(marker);
      });
    }
    catch(e) {
      _markers.add(marker);
    }

    if(showInfo) {
      _showMarkerInfo(marker.markerId);
    }
  }


  Future<void> _createPolyline(List<LatLng> latLngs) async {

    Polyline polyline = Polyline(
      polylineId: PolylineId(""),
      color: Colors.blue,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
      width: 7,
      visible: true,
      points: latLngs,
      patterns: <PatternItem>[],
    );

    _placePolylineOnMap(polyline);
  }


  Future<void> _placePolylineOnMap(Polyline polyline) async {

    try {
      setState(() {
        _polyLines.add(polyline);
      });
    }
    catch(e) {
      _polyLines.add(polyline);
    }
  }


  Future<void> _zoomBetweenTwoPoints(LatLng firstPoint, LatLng secondPoint) async {

    LatLngBounds bounds;

    if(firstPoint.latitude > secondPoint.latitude && firstPoint.longitude > secondPoint.longitude) {

      bounds = LatLngBounds(southwest: secondPoint, northeast: firstPoint);
    }
    else if(firstPoint.longitude > secondPoint.longitude) {

      bounds = LatLngBounds(southwest: LatLng(firstPoint.latitude, secondPoint.longitude),
          northeast: LatLng(secondPoint.latitude, firstPoint.longitude));
    }
    else if(firstPoint.latitude > secondPoint.latitude) {

      bounds = LatLngBounds(southwest: LatLng(secondPoint.latitude, firstPoint.longitude),
          northeast: LatLng(firstPoint.latitude, secondPoint.longitude));
    }
    else {

      bounds = LatLngBounds(southwest: firstPoint, northeast: secondPoint);
    }

    _controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }


  @override
  Future<void> showRequestedRideRoute(List<LatLng> latLngs) async {

    _getDistance(latLngs);

    setState(() {
      _markers.clear();
      _polyLines.clear();
    });

    _createPickUpMarker(widget._ride.pickupPoint);
    _createDropOffMarker(widget._ride.dropOffPoint);
    _createPolyline(latLngs);

    _zoomBetweenTwoPoints(widget._ride.pickupPoint, widget._ride.dropOffPoint);

    _acceptController.requestDetailsController.forward();
  }


  @override
  void onFailed(BuildContext context, String message) {

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Future<void> removeRide() async {

    for(int i=0; i<rideRequests.value.length; i++) {

      if(rideRequests.value[i].id == widget._ride.id) {

        rideRequests.value.removeAt(i);
        rideRequests.notifyListeners();
        break;
      }
    }
  }


  @override
  Future<void> onRideAccepted(Ride ride) async {

    Screen.keepOn(true);

    _dbHelper.clearRoutePath();

    if(_acceptController.requestDetailsController.isCompleted) {

      _acceptController.requestDetailsController.reverse();
    }

    setState(() {
      _acceptedRide = ride;
      _acceptedRide.pickupAddress = widget._ride.pickupAddress;
      _acceptedRide.dropOffAddress = widget._ride.dropOffAddress;

      _markers.clear();
      _polyLines.clear();
      _appBarTitle = S.of(context).pick_up;
    });

    await _createPickUpMarker(widget._ride.pickupPoint);

    _acceptController.pickupController.forward();
  }


  Future<void> _showRouteToPickupPoint(Position position) async {

    try {

      List<LatLng> latLngs = await _acceptController.getPolylineList(LatLng(position.latitude, position.longitude), widget._ride.pickupPoint);

      _createPolyline(latLngs);
      _createRiderLocationMarker(position);

      if(!_acceptController.isShown) {

        _acceptController.isShown = true;
        _zoomBetweenTwoPoints(LatLng(position.latitude, position.longitude), widget._ride.pickupPoint);
      }
      else {

        _controller.moveCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
      }
    }
    catch (e) {
      print(e);
    }
  }


  Future<void> _showMarkerInfo(MarkerId markerID) async {

    await Future.delayed(Duration(milliseconds: 1500));

    try {
      _controller.showMarkerInfoWindow(markerID);
    }
    catch (e) {
      print(e);
    }
  }


  @override
  void onRideAcceptDenied(BuildContext context, String message) {

    removeRide();

    setState(() {
      widget._ride.isTaken = true;
    });

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  void rideOnGoing(BuildContext context) {

    setState(() {
      _acceptController.isAllowed = false;
    });

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).not_allowed_to_accept_another_ride)));
  }


  @override
  Future<void> onRideStarted(Ride ride) async {

    if(_acceptController.pickupController.isCompleted) {

      _acceptController.pickupController.reverse();
    }

    setState(() {

      _acceptedRide.pickupPoint = ride.pickupPoint;
      _acceptedRide.status = Constants.started;

      _markers.clear();
      _polyLines.clear();
      _appBarTitle = S.of(context).ride_started;
    });

    _acceptController.isShown = false;

    await _createDropOffMarker(widget._ride.dropOffPoint);

    _acceptController.startedController.forward();
  }


  Future<void> _showCurrentLocation(Position position) async {

    try {

      List<LatLng> latLngs = await _acceptController.getPolylineList(LatLng(position.latitude, position.longitude), _acceptedRide.dropOffPoint);

      _createPolyline(latLngs);
      _createRiderLocationMarker(position);

      if(!_acceptController.isShown) {

        _acceptController.isShown = true;
        _zoomBetweenTwoPoints(LatLng(position.latitude, position.longitude), _acceptedRide.dropOffPoint);
      }
      else {

        _controller.moveCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
      }
    }
    catch (e) {
      print(e);
    }
  }

  
  Future<void> _liveMovementTest() async {

    try {

      Screen.keepOn(true);

      setState(() {
        _markers.clear();
        _polyLines.clear();
      });

      List<LatLng> latLngs = await _acceptController.getPolylineList(LatLng(23.751309, 90.378099), LatLng(23.807451, 90.355858));

      for(int i=1; i<latLngs.length; i++) {

        List<LatLng> latLngsdfgfg = await _acceptController.getPolylineList(latLngs[i], LatLng(23.807451, 90.355858));

        Timer(Duration(seconds: 10), () async {

          Polyline polyline = Polyline(
            polylineId: PolylineId(""),
            color: Colors.blue,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
            width: 8,
            visible: true,
            points: latLngsdfgfg,
            patterns: <PatternItem>[],
          );

          Marker riderMarker = Marker(
            markerId: Constants.USER_LOCATION_MARKER,
            position: latLngs[i],
            draggable: false,
            flat: true,
            zIndex: 2,
            anchor: Offset(0.5, 0.5),
            icon: BitmapDescriptor.fromBytes(_acceptController.riderBitmap),
          );

          setState(() {
            _markers.add(riderMarker);
            _polyLines.add(polyline);
          });

          //old latlng, new latlng
          double bearing = await Geolocator().bearingBetween(latLngs[i-1].latitude, latLngs[i-1].longitude, latLngs[i].latitude, latLngs[i].longitude);

          //final GoogleMapController controller = await _controller.future;
          //controller.moveCamera(CameraUpdate.newLatLng(latLngs[i]));
          _controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLngs[i], zoom: 16.5, bearing: bearing)));
        });
      }

      Screen.keepOn(false);
    }
    catch (e) {
      print(e);
    }
  }


  @override
  Future<void> finishRide(BuildContext context) async {

    setState(() {
      _acceptedRide.status = Constants.completed;
    });

    Position position = await Geolocator().getCurrentPosition();

    setState(() {
      _acceptedRide.dropOffPoint = LatLng(position.latitude, position.longitude);
    });

    List<LatLng> paths  = await _dbHelper.getTotalRoutePath();

    paths.insert(0, _acceptedRide.pickupPoint);
    paths.add(_acceptedRide.dropOffPoint);

    await _getDistance(paths);

    _acceptRepo.finishRide(context, _acceptedRide, _distance, _fare, _adminCommission, paths);
  }


  @override
  Future<void> onRideComplete(Ride ride, List<LatLng> paths) async {

    Screen.keepOn(false);

    _acceptController.startedController.reverse();

    var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.pickupPoint.latitude, ride.pickupPoint.longitude));
    ride.pickupAddress = addresses.first.addressLine;

    addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.dropOffPoint.latitude, ride.dropOffPoint.longitude));
    ride.dropOffAddress = addresses.first.addressLine;

    setState(() {
      _appBarTitle = S.of(context).ride_complete;
      _acceptedRide = ride;
      _markers.clear();
      _polyLines.clear();
    });

    _createPickUpMarker(ride.pickupPoint);
    _createDropOffMarker(ride.dropOffPoint);
    _createPolyline(paths);

    _zoomBetweenTwoPoints(ride.pickupPoint, ride.dropOffPoint);

    _acceptController.completeController.forward();
  }


  @override
  Future<void> onRideCancelled(BuildContext context, Ride ride, {List<LatLng> paths}) async {

    Screen.keepOn(false);

    if(_acceptedRide.status == Constants.accepted) {

      rideNotifier.value = ride;
      rideNotifier.notifyListeners();
    }
    else if(_acceptedRide.status == Constants.started) {

      _acceptController.startedController.reverse();

      try {

        if(ride.pickupPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.pickupPoint.latitude, ride.pickupPoint.longitude));
          ride.pickupAddress = addresses.first.addressLine;
        }

        if(ride.dropOffPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.dropOffPoint.latitude, ride.dropOffPoint.longitude));
          ride.dropOffAddress = addresses.first.addressLine;
        }

        rideNotifier.value = ride;
        rideNotifier.notifyListeners();
      }
      catch (e) {}
    }
  }


  @override
  Future<void> onCancelConfirmed(BuildContext context, String message) async {

    Position position = await Geolocator().getCurrentPosition();

    setState(() {
      _acceptedRide.dropOffPoint = LatLng(position.latitude, position.longitude);
    });

    List<LatLng> paths  = await _dbHelper.getTotalRoutePath();

    paths.insert(0, _acceptedRide.pickupPoint);
    paths.add(_acceptedRide.dropOffPoint);

    await _getDistance(paths);
    String cancelFee = currentUser.value.riderType.cancelFee;

    Ride ride = Ride(id: _acceptedRide.id, status: Constants.canceled, dropOffPoint: LatLng(position.latitude, position.longitude), cancellationFee: cancelFee,
        distance: _distance.toStringAsFixed(2), cancellationMessage: message);
    _acceptRepo.updateRideInfo(context, ride, paths: paths);
  }


  Future<void> _showRouteTillHere(Ride ride) async {

    List<LatLng> paths  = await _dbHelper.getTotalRoutePath();

    paths.insert(0, ride.pickupPoint);
    paths.add(ride.dropOffPoint);

    _createPickUpMarker(ride.pickupPoint);
    _createPolyline(paths);

    _zoomBetweenTwoPoints(ride.pickupPoint, ride.dropOffPoint);

    _acceptController.afterStartCancelController.forward();

    setState(() {
      _acceptedRide.status == Constants.canceled;
    });
  }
}