import 'package:google_maps_flutter/google_maps_flutter.dart';

class Constants {

  static const int NID_FRONT = 86868;
  static const int NID_BACK = 94772;
  static const int LICENSE_FRONT = 37659;
  static const int LICENSE_BACK = 45364;

  static final MarkerId USER_LOCATION_MARKER = MarkerId("bryhuh");
  static final MarkerId PICK_UP_POINT_MARKER = MarkerId("neiyiuh");
  static final MarkerId DROP_OFF_POINT_MARKER = MarkerId("onyfigu");
  static final MarkerId SEARCHED_ADDRESS_MARKER = MarkerId("nffgubdv");

  static final String online = "1";
  static final String offline = "2";

  static final String requested = "0";
  static final String accepted = "1";
  static final String canceled = "2";
  static final String completed = "3";
  static final String started = "4";
}