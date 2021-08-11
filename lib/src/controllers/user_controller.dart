import 'dart:async';
import 'dart:convert';

import '../repository/ride/ride_repository.dart';

import '../models/otp_verify.dart';
import '../models/password.dart';
import '../pages/password_reset_otp_verify.dart';
import '../pages/reset_password.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../helpers/helper.dart';
import '../models/user.dart';
import '../repository/user_repository.dart' as repository;

class UserController extends ControllerMVC with ChangeNotifier {
  User user = new User();
  bool hidePassword = true;
  bool loading = false;
  GlobalKey<FormState> loginFormKey;
  GlobalKey<ScaffoldState> scaffoldKey;
  FirebaseMessaging _firebaseMessaging;
  FirebaseAuth _firebaseAuth;
  bool passwordResetSuccess = false;
  AuthCredential _authCredential;
  OverlayEntry loader;
  int resendingToken;
  String verificationID;
  Timer _timer;
  int timeOut;

  UserController() {
    passwordResetSuccess = false;
    loader = Helper.overlayLoader(context);
    loginFormKey = new GlobalKey<FormState>();
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    _firebaseMessaging = FirebaseMessaging();
    _firebaseAuth = FirebaseAuth.instance;
    _firebaseMessaging.getToken().then((String _deviceToken) {
      print("Firebase Device Token: " + _deviceToken);
      user.deviceToken = _deviceToken;
    }).catchError((e) {
      print('Notification not configured');
    });
  }

  void login() async {
    FocusScope.of(context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);
      repository.login(user).then((response) {

        if(json.decode(response.body)['success']) {

          User user = User.fromJSON(json.decode(response.body)['data']);

          if(user.roleID == 6 && user.isActive) {

            repository.setCurrentUser(response.body);
            repository.currentUser.value = user;

            rideRequests.value = List();
            rideRequests.notifyListeners();

            Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Pages', arguments: 1);
          }
          else if(user.roleID == 6 && !user.isActive) {

            Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/SignUpNotify');
          }
          else {

            scaffoldKey?.currentState?.showSnackBar(SnackBar(
              content: Text(S.of(context).not_rider_Account),
            ));
          }
        }
        else {

          if(json.decode(response.body)['message'] == "Invalid email or password") {

            scaffoldKey?.currentState?.showSnackBar(SnackBar(
              content: Text(S.of(context).wrong_email_or_password),
            ));
          }
          else {

            scaffoldKey?.currentState?.showSnackBar(SnackBar(
              content: Text(S.of(context).failed_to_login),
            ));
          }
        }
      }).catchError((e) {
        loader.remove();
        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).failed_to_login),
        ));
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }

  void validate() {

    if(user.name == null || user.name.isEmpty) {

      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(S.of(context).enter_full_name), duration: Duration(seconds: 2),
      ));
    }
    else {

      if(user.name.length < 3) {

        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(S.of(context).should_be_more_than_3_letters), duration: Duration(seconds: 2),
        ));
      }
      else {

        if(user.email == null || user.email.isEmpty) {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).enter_phone), duration: Duration(seconds: 2),
          ));
        }
        else {

          if(user.email.length < 11) {

            scaffoldKey?.currentState?.showSnackBar(SnackBar(
              content: Text(S.of(context).not_a_valid_phone), duration: Duration(seconds: 2),
            ));
          }
          else {

            if(user.password == null || user.password.isEmpty) {

              scaffoldKey?.currentState?.showSnackBar(SnackBar(
                content: Text(S.of(context).enter_password), duration: Duration(seconds: 2),
              ));
            }
            else {

              if(user.password.length < 6) {

                scaffoldKey?.currentState?.showSnackBar(SnackBar(
                  content: Text(S.of(context).must_be_6_letters), duration: Duration(seconds: 2),
                ));
              }
              else {

                if(user.riderType == null) {

                  scaffoldKey?.currentState?.showSnackBar(SnackBar(
                    content: Text(S.of(context).select_ride_type_hint), duration: Duration(seconds: 2),
                  ));
                }
                else {

                  if(user.riderType.isNidRequired && user.NIDFront == null) {

                    scaffoldKey?.currentState?.showSnackBar(SnackBar(
                      content: Text(S.of(context).add_nid_front_image), duration: Duration(seconds: 2),
                    ));
                  }
                  else {

                    if(user.riderType.isNidRequired && user.NIDBack == null) {

                      scaffoldKey?.currentState?.showSnackBar(SnackBar(
                        content: Text(S.of(context).add_nid_back_image), duration: Duration(seconds: 2),
                      ));
                    }
                    else {

                      if(user.riderType.isLicenseRequired && user.licenseFront == null) {

                        scaffoldKey?.currentState?.showSnackBar(SnackBar(
                          content: Text(S.of(context).add_license_front_image), duration: Duration(seconds: 2),
                        ));
                      }
                      else {

                        if(user.riderType.isLicenseRequired && user.licenseBack == null) {

                          scaffoldKey?.currentState?.showSnackBar(SnackBar(
                            content: Text(S.of(context).add_license_back_image), duration: Duration(seconds: 2),
                          ));
                        }
                        else {

                          sendOTP();
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  void sendOTP() {

    FocusScope.of(context).unfocus();

    loginFormKey.currentState.save();
    Overlay.of(context).insert(loader);

    String phoneNumber = "+88" + user.email;

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: Duration(seconds: 0),
      verificationCompleted: (authCredential) {},
      verificationFailed: (authException) {
        print(authException.message);
        loader.remove();
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(S.of(context).otpSendingFailed),
        ));
      },
      codeSent: (verificationId, [token]) {
        resendingToken = token;
      },
      codeAutoRetrievalTimeout: (verificationId) {
        loader.remove();
        OtpVerify otpVerify = OtpVerify(verificationID: verificationId, resendingToken: resendingToken, user: user);
        Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/MobileVerification2', arguments: otpVerify);
      },
    );
  }

  void startCountDown() {

    repository.timeOut.value = 60;
    //timeOut = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {

      if(repository.timeOut.value == 0) {

        timer.cancel();
      }
      else if(repository.timeOut.value > 0) {

        repository.timeOut.value = repository.timeOut.value - 1;
      }
    });
  }

  void resendOTP(String phone) {

    FocusScope.of(context).unfocus();

    if(resendingToken != null) {

      Overlay.of(context).insert(loader);

      String phoneNumber = "+88" + phone;

      _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: 0),
        forceResendingToken: resendingToken,
        verificationCompleted: (authCredential) {},
        verificationFailed: (authException) {
          print(authException.message);
          loader.remove();
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).otpSendingFailed),
          ));
        },
        codeSent: (verificationId, [token]) {
          this.resendingToken = token;
        },
        codeAutoRetrievalTimeout: (verificationId) {
          this.verificationID = verificationId;
          loader.remove();
          startCountDown();
        },
      );
    }
  }

  void verifyCode(String code, OtpVerify otpVerify) {

    FocusScope.of(context).unfocus();

    if(loginFormKey.currentState.validate()) {

      loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);

      _authCredential = PhoneAuthProvider.getCredential(verificationId: this.verificationID, smsCode: code);

      _firebaseAuth.signInWithCredential(_authCredential).then((authResult) async {

        if(authResult.user != null) {
          register(otpVerify.user);
        }
        else {

          loader.remove();
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).failedToVerifyOTP),
          ));
        }
      }).catchError((error) async {

        loader.remove();

        if(error.toString().contains("ERROR_INVALID_VERIFICATION_CODE")) {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).invalidOTPCode),
          ));
        }
        else {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).failedToVerifyOTP),
          ));
        }
      });
    }
  }

  void register(User user) async {
    FocusScope.of(context).unfocus();
    if(loginFormKey.currentState.validate()) {
      loginFormKey.currentState.save();
      repository.register(user).then((response) {

        try {
          loader.remove();
        }
        catch(e) {
          print(e);
        }

        print(response.body);

        if(response.statusCode == 200) {
          if(json.decode(response.body)['success']) {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/SignUpNotify');
          }
          else {
            if(json.decode(response.body)['errors']['email'] != null && json.decode(response.body)['errors']['email'].first == "The given data has already been taken. Please try another") {

              scaffoldKey?.currentState?.showSnackBar(SnackBar(
                content: Text(S.of(context).phone_already_used),
              ));
            }
            else {
              scaffoldKey?.currentState?.showSnackBar(SnackBar(
                content: Text(S.of(context).wrong_email_or_password),
              ));
            }
          }
        } else {
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).failed_to_register),
          ));
        }
      }).catchError((e) {
        try {
          loader.remove();
        }
        catch(e) {
          print(e);
        }

        scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(S.of(context).thisAccountNotExist),
        ));
      }).whenComplete(() {
        try {
          loader.remove();
        }
        catch(e) {
          print(e);
        }
        Helper.hideLoader(loader);
      });
    }
  }

  void validateUser(String phone) {
    FocusScope.of(context).unfocus();
    if (loginFormKey.currentState.validate()) {
      //loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);
      repository.validateUser(phone).then((response) {

        try {
          if(json.decode(response)['success']) {

            User user = User.fromJSON(json.decode(response)['data']);
            sendPasswordResetOTP(user);
          }
          else {

            if(json.decode(response)['message'] == "No Data Found") {

              loader.remove();
              scaffoldKey?.currentState?.showSnackBar(SnackBar(
                content: Text(S.of(context).account_not_exist),
              ));
            }
          }
        }
        catch(error) {
          loader.remove();
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).password_reset_failed),
          ));
          print(error);
        }
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }

  void sendPasswordResetOTP(User user) {

    String phoneNumber = "+88" + user.email;

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: Duration(seconds: 0),
      verificationCompleted: (authCredential) {},
      verificationFailed: (authException) {
        loader.remove();
        scaffoldKey?.currentState?.showSnackBar(SnackBar(
          content: Text(S.of(context).otpSendingFailed),
        ));
      },
      codeSent: (verificationId, [token]) {
        loader.remove();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PasswordResetOtpVerify(verificationId, user)));
      },
      codeAutoRetrievalTimeout: (verificationId) {
      },
    );
  }

  void verifyPasswordResetCode(String code, String verificationID, User user) {

    FocusScope.of(context).unfocus();

    if(loginFormKey.currentState.validate()) {

      loginFormKey.currentState.save();
      Overlay.of(context).insert(loader);

      _authCredential = PhoneAuthProvider.getCredential(verificationId: verificationID, smsCode: code);

      _firebaseAuth.signInWithCredential(_authCredential).then((authResult) async {

        loader.remove();

        if(authResult.user != null) {

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResetPassword(user: user)));
        }
        else {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).failedToVerifyOTP),
          ));
        }
      }).catchError((error) async {

        loader.remove();

        if(error.toString().contains("ERROR_INVALID_VERIFICATION_CODE")) {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).invalidOTPCode),
          ));
        }
        else {

          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).failedToVerifyOTP),
          ));
        }
      });
    }
  }

  void resetPassword(Password password) {
    FocusScope.of(context).unfocus();
    if (loginFormKey.currentState.validate()) {
      loginFormKey.currentState.reset();
      Overlay.of(context).insert(loader);
      repository.resetPassword(password).then((value) {

        if (value != null && value == true) {
          passwordResetSuccess = true;
          loginFormKey?.currentState?.reset();
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).password_reset_success),
            action: SnackBarAction(
              label: S.of(context).login,
              onPressed: () {
                Navigator.of(scaffoldKey.currentContext).pushReplacementNamed('/Login');
              },
            ),
            duration: Duration(days: 365),
          ));
        } else {
          loader.remove();
          scaffoldKey?.currentState?.showSnackBar(SnackBar(
            content: Text(S.of(context).password_reset_failed),
          ));
        }
      }).whenComplete(() {
        Helper.hideLoader(loader);
      });
    }
  }
}
