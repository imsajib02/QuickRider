import 'package:flutter/material.dart';

import '../helpers/custom_trace.dart';
import 'rider_type.dart';

class Setting {
  String appName = '';
  double defaultTax;
  String defaultCurrency;
  String distanceUnit;
  bool currencyRight = false;
  int currencyDecimalDigits = 2;
  bool payPalEnabled = true;
  bool stripeEnabled = true;
  bool razorPayEnabled = true;
  String mainColor;
  String mainDarkColor;
  String secondColor;
  String secondDarkColor;
  String accentColor;
  String accentDarkColor;
  String scaffoldDarkColor;
  String scaffoldColor;
  String googleMapsKey;
  List<RiderType> riderTypes;
  ValueNotifier<Locale> mobileLanguage = new ValueNotifier(Locale('en', ''));
  String appVersion;
  bool enableVersion = true;

  ValueNotifier<Brightness> brightness = new ValueNotifier(Brightness.light);

  Setting();

  Setting.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      appName = jsonMap['app_name'] == null ? "Delivery Boy" : jsonMap['app_name'];
      mainColor = jsonMap['main_color'] ?? '';
      mainDarkColor = jsonMap['main_dark_color'] ?? '';
      secondColor = jsonMap['second_color'] ?? '';
      secondDarkColor = jsonMap['second_dark_color'] ?? '';
      accentColor = jsonMap['accent_color'] ?? '';
      accentDarkColor = jsonMap['accent_dark_color'] ?? '';
      scaffoldDarkColor = jsonMap['scaffold_dark_color'] ?? '';
      scaffoldColor = jsonMap['scaffold_color'] ?? '';
      googleMapsKey = jsonMap['google_maps_key'] ?? "AIzaSyC6BrV9rm8RCQ_3qMn36s8xBbbHnnCQsJM";
      mobileLanguage.value = Locale(jsonMap['mobile_language'] ?? "en", '');
      appVersion = jsonMap['app_version'] ?? '';
      distanceUnit = jsonMap['distance_unit'] ?? 'km';
      enableVersion = jsonMap['enable_version'] == null || jsonMap['enable_version'] == '0' ? false : true;
      defaultTax = jsonMap['default_tax'] == null ? 0.0 : double.tryParse(jsonMap['default_tax']);
      defaultCurrency = jsonMap['default_currency'] == null ? '' : jsonMap['default_currency'];
      currencyDecimalDigits = jsonMap['default_currency_decimal_digits'] == null ? 2 : int.tryParse(jsonMap['default_currency_decimal_digits']);
      currencyRight = jsonMap['currency_right'] == null || jsonMap['currency_right'] == '0' ? false : true;
      payPalEnabled = jsonMap['enable_paypal'] == null || jsonMap['enable_paypal'] == '0' ? false : true;
      stripeEnabled = jsonMap['enable_stripe'] == null || jsonMap['enable_stripe'] == '0' ? false : true;
      razorPayEnabled = jsonMap['enable_razorpay'] == null || jsonMap['enable_razorpay'] == '0' ? false : true;
      razorPayEnabled = jsonMap['enable_razorpay'] == null || jsonMap['enable_razorpay'] == '0' ? false : true;

      riderTypes = List();

      if(jsonMap['riderTypes'] != null) {
        jsonMap['riderTypes'].forEach((type) {

          if(type['is_active'] == "1") {

            riderTypes.add(RiderType.fromJSON(type));
          }
        });
      }
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["app_name"] = appName;
    map["default_tax"] = defaultTax;
    map["default_currency"] = defaultCurrency;
    map["default_currency_decimal_digits"] = currencyDecimalDigits;
    map["currency_right"] = currencyRight;
    map["enable_paypal"] = payPalEnabled;
    map["enable_stripe"] = stripeEnabled;
    map["enable_razorpay"] = razorPayEnabled;
    map["mobile_language"] = mobileLanguage.value.languageCode;
    return map;
  }
}
