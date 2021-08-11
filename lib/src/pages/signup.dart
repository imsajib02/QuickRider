import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import '../helpers/Constants.dart';
import '../models/rider_type.dart';

import '../../generated/l10n.dart';
import '../controllers/user_controller.dart';
import '../elements/BlockButtonWidget.dart';
import '../helpers/app_config.dart' as config;
import '../repository/settings_repository.dart';

class SignUpWidget extends StatefulWidget {
  @override
  _SignUpWidgetState createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends StateMVC<SignUpWidget> {

  UserController _con;

  _SignUpWidgetState() : super(UserController()) {
    _con = controller;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: _con.scaffoldKey,
        resizeToAvoidBottomPadding: false,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[

            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.only(left: 25, top: 20),
                alignment: Alignment.centerLeft,
                color: Theme.of(context).accentColor,
                child: Text(
                  S.of(context).lets_start_with_register,
                  style: Theme.of(context).textTheme.headline2.merge(TextStyle(color: Theme.of(context).primaryColor)),
                ),
              ),
            ),

            Expanded(
              flex: 10,
              child: ScrollConfiguration(
                behavior: new ScrollBehavior()..buildViewportChrome(context, null, AxisDirection.down),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 40, horizontal: 27),
                    width: config.App(context).appWidth(88),
                    child: Form(
                      key: _con.loginFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          TextFormField(
                            keyboardType: TextInputType.text,
                            onChanged: (input) => _con.user.name = input,
                            //validator: (input) => input.length < 3 ? S.of(context).should_be_more_than_3_letters : null,
                            decoration: InputDecoration(
                              labelText: S.of(context).full_name,
                              labelStyle: TextStyle(color: Theme.of(context).accentColor),
                              contentPadding: EdgeInsets.all(12),
                              hintText: S.of(context).john_doe,
                              hintStyle: TextStyle(color: Theme.of(context).focusColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).accentColor),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.5))),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                            ),
                          ),
                          SizedBox(height: 30),
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            onChanged: (input) => _con.user.email = input,
                            //validator: (input) => input.length < 11 ? S.of(context).not_a_valid_phone : null,
                            decoration: InputDecoration(
                              labelText: S.of(context).phone,
                              labelStyle: TextStyle(color: Theme.of(context).accentColor),
                              contentPadding: EdgeInsets.all(12),
                              hintText: '01XXXXXXXXX',
                              hintStyle: TextStyle(color: Theme.of(context).focusColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.contact_phone, color: Theme.of(context).accentColor),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.5))),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                            ),
                          ),
                          SizedBox(height: 30),
                          TextFormField(
                            obscureText: _con.hidePassword,
                            onChanged: (input) => _con.user.password = input,
                            //validator: (input) => input.length < 6 ? S.of(context).should_be_more_than_6_letters : null,
                            decoration: InputDecoration(
                              labelText: S.of(context).password,
                              labelStyle: TextStyle(color: Theme.of(context).accentColor),
                              contentPadding: EdgeInsets.all(12),
                              hintText: '••••••••••••',
                              hintStyle: TextStyle(color: Theme.of(context).focusColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).accentColor),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _con.hidePassword = !_con.hidePassword;
                                  });
                                },
                                color: Theme.of(context).focusColor,
                                icon: Icon(_con.hidePassword ? Icons.visibility : Icons.visibility_off),
                              ),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.5))),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                            ),
                          ),
                          SizedBox(height: 30),
                          DropdownButtonFormField(
                            hint: Text(S.of(context).select_ride_type_hint + " ---", style: Theme.of(context).textTheme.subtitle2,),
                            value: _con.user.riderType,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.5))),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).focusColor.withOpacity(0.2))),
                            ),
                            //validator: (value) => value == null ? "Select rider type" : null,
                            items: setting.value.riderTypes.map((RiderType type) {

                              return DropdownMenuItem(child: Text(type.name, style: Theme.of(context).textTheme.subtitle2), value: type);
                            }).toList(),
                            onChanged: (value) {

                              setState(() {
                                _con.user.riderType = value;
                              });
                            },
                          ),
                          Visibility(
                            visible: _con.user.riderType != null && _con.user.riderType.isNidRequired,
                            child: Column(
                              children: <Widget>[

                                SizedBox(height: 30),
                                IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Padding(
                                        padding: EdgeInsets.only(left: 5.0),
                                        child: Text(S.of(context).nid_front_img, style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.blue),),
                                      ),

                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _pickImage(Constants.NID_FRONT);
                                        },
                                        child: Container(
                                          width: 100,
                                          height: 40,
                                          decoration: _con.user.NIDFront == null ? BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1)
                                          ) : BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1),
                                              image: DecorationImage(image: FileImage(_con.user.NIDFront), fit: BoxFit.fill)
                                          ),
                                          child: Icon(Icons.photo, color: _con.user.NIDFront == null ? Colors.blue : Colors.transparent,),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 30),
                                IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Padding(
                                        padding: EdgeInsets.only(left: 5.0),
                                        child: Text(S.of(context).nid_back_img, style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.blue),),
                                      ),

                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _pickImage(Constants.NID_BACK);
                                        },
                                        child: Container(
                                          width: 100,
                                          height: 40,
                                          decoration: _con.user.NIDBack == null ? BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1)
                                          ) : BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1),
                                              image: DecorationImage(image: FileImage(_con.user.NIDBack), fit: BoxFit.fill)
                                          ),
                                          child: Icon(Icons.photo, color: _con.user.NIDBack == null ? Colors.blue : Colors.transparent,),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: _con.user.riderType != null && _con.user.riderType.isLicenseRequired,
                            child: Column(
                              children: <Widget>[

                                SizedBox(height: 30),
                                IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Padding(
                                        padding: EdgeInsets.only(left: 5.0),
                                        child: Text(S.of(context).license_front_img, style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.blue),),
                                      ),

                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _pickImage(Constants.LICENSE_FRONT);
                                        },
                                        child: Container(
                                          width: 100,
                                          height: 40,
                                          decoration: _con.user.licenseFront == null ? BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1)
                                          ) : BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1),
                                              image: DecorationImage(image: FileImage(_con.user.licenseFront), fit: BoxFit.fill)
                                          ),
                                          child: Icon(Icons.photo, color: _con.user.licenseFront == null ? Colors.blue : Colors.transparent,),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 30),
                                IntrinsicHeight(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Padding(
                                        padding: EdgeInsets.only(left: 5.0),
                                        child: Text(S.of(context).license_back_img, style: Theme.of(context).textTheme.subtitle2.copyWith(color: Colors.blue),),
                                      ),

                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          _pickImage(Constants.LICENSE_BACK);
                                        },
                                        child: Container(
                                          width: 100,
                                          height: 40,
                                          decoration: _con.user.licenseBack == null ? BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1)
                                          ) : BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              border: Border.all(color: Colors.black26, width: 1),
                                              image: DecorationImage(image: FileImage(_con.user.licenseBack), fit: BoxFit.fill)
                                          ),
                                          child: Icon(Icons.photo, color: _con.user.licenseBack == null ? Colors.blue : Colors.transparent,),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                          BlockButtonWidget(
                            text: Text(
                              S.of(context).register,
                              style: TextStyle(color: Theme.of(context).primaryColor),
                            ),
                            color: Theme.of(context).accentColor,
                            onPressed: () {
                              _con.validate();
                            },
                          ),
                          SizedBox(height: 20),
                          FlatButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/Login');
                            },
                            textColor: Theme.of(context).hintColor,
                            child: Text(S.of(context).i_have_account_back_to_login),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(int FileId) async {

    try {

      var pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
      File file = await _compressFile(File(pickedFile.path));

      setState(() {

        switch(FileId) {

          case Constants.NID_FRONT:
            _con.user.NIDFront = file;
            break;

          case Constants.NID_BACK:
            _con.user.NIDBack = file;
            break;

          case Constants.LICENSE_FRONT:
            _con.user.licenseFront = file;
            break;

          case Constants.LICENSE_BACK:
            _con.user.licenseBack = file;
            break;
        }
      });

    } catch(error) {

      print(error);
    }
  }

  Future<File> _compressFile(File file) async {

    final filePath = file.absolute.path;

    final lastIndex = filePath.lastIndexOf(new RegExp(r'.jp'));
    final splitted = filePath.substring(0, (lastIndex));
    final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, outPath,
      quality: 70,
    );

    return result;
  }
}
