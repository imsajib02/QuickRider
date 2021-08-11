import 'package:flutter/material.dart';

import 'src/controllers/settings_controller.dart';
import 'src/models/otp_verify.dart';
import 'src/models/ride.dart';
import 'src/models/route_argument.dart';
import 'src/pages/forget_password.dart';
import 'src/pages/help.dart';
import 'src/pages/languages.dart';
import 'src/pages/login.dart';
import 'src/pages/mobile_verification.dart';
import 'src/pages/mobile_verification_2.dart';
import 'src/pages/notifications.dart';
import 'src/pages/order.dart';
import 'src/pages/pages.dart';
import 'src/pages/phone_change.dart';
import 'src/pages/ride/my_rides.dart';
import 'src/pages/ride/ride_accept.dart';
import 'src/pages/ride/ride_details.dart';
import 'src/pages/settings.dart';
import 'src/pages/signup.dart';
import 'src/pages/signup_notify.dart';
import 'src/pages/splash_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;
    switch (settings.name) {
      case '/Splash':
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case '/SignUp':
        return MaterialPageRoute(builder: (_) => SignUpWidget());
      case '/SignUpNotify':
        return MaterialPageRoute(builder: (_) => SignUpNotify());
      case '/MobileVerification':
        return MaterialPageRoute(builder: (_) => MobileVerification());
      case '/MobileVerification2':
        return MaterialPageRoute(builder: (_) => MobileVerification2(args as OtpVerify));
      case '/Login':
        return MaterialPageRoute(builder: (_) => LoginWidget());
      case '/ForgetPassword':
        return MaterialPageRoute(builder: (_) => ForgetPasswordWidget());
      case '/Pages':
        return MaterialPageRoute(builder: (_) => PagesTestWidget(currentTab: args));
      case '/OrderDetails':
        return MaterialPageRoute(builder: (_) => OrderWidget(routeArgument: args as RouteArgument));
      case '/Notifications':
        return MaterialPageRoute(builder: (_) => NotificationsWidget());
      case '/Languages':
        return MaterialPageRoute(builder: (_) => LanguagesWidget());
      case '/Help':
        return MaterialPageRoute(builder: (_) => HelpWidget());
      case '/Settings':
        return MaterialPageRoute(builder: (_) => SettingsWidget());
      case '/ChangePhone':
        return MaterialPageRoute(builder: (_) => PhoneNumberChange(con: args as SettingsController));
      case '/RideAccept':
        return MaterialPageRoute(builder: (_) => RideAccept(args as Ride));
      case '/MyRides':
        return MaterialPageRoute(builder: (_) => MyRides());
      case '/RideDetails':
        return MaterialPageRoute(builder: (_) => RideDetails(args as Ride));
      default:
        // If there is no such named route in the switch statement, e.g. /third
        return MaterialPageRoute(builder: (_) => Scaffold(body: SizedBox(height: 0)));
    }
  }
}