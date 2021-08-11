import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride.dart';

abstract class RideAcceptContact {

  void showRequestedRideRoute(List<LatLng> latLngs);
  void onFailed(BuildContext context, String message);
  void onRideAcceptDenied(BuildContext context, String message);
  void rideOnGoing(BuildContext context);
  void removeRide();
  void onRideAccepted(Ride ride);
  void onRideStarted(Ride ride);
  void finishRide(BuildContext context);
  void onRideComplete(Ride ride, List<LatLng> paths);
  void onRideCancelled(BuildContext context, Ride ride, {List<LatLng> paths});
  void onCancelConfirmed(BuildContext context, String message);
}