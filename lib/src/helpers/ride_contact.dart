import 'package:flutter/material.dart';
import '../models/ride.dart';

abstract class RideContact {

  void onOnline();
  void onOffline();
  void onFailed(BuildContext context, String message);
  void onActiveRideFound(BuildContext context, List<Ride> rides);
  void onConnectFail(BuildContext context, String message);
}