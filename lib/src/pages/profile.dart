import 'package:cached_network_image/cached_network_image.dart';
import '../elements/profile_imgae_pick.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../controllers/profile_controller.dart';
import '../elements/CircularLoadingWidget.dart';
import '../elements/OrderItemWidget.dart';
import '../elements/ProfileAvatarWidget.dart';
import '../elements/ShoppingCartButtonWidget.dart';
import '../repository/user_repository.dart';

class ProfileWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  ProfileWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends StateMVC<ProfileWidget> {
  ProfileController _con;

  _ProfileWidgetState() : super(ProfileController()) {
    _con = controller;
  }

  @override
  void initState() {
    _con.listenForRecentOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: new IconButton(
          icon: new Icon(Icons.menu, color: Theme.of(context).primaryColor),
          onPressed: () => widget.parentScaffoldKey?.currentState?.openDrawer(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).accentColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          S.of(context).profile,
          style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3, color: Theme.of(context).primaryColor)),
        ),
      ),
      key: _con.scaffoldKey,
      body: _con.user.apiToken == null
          ? CircularLoadingWidget(height: 500)
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: Theme.of(context).accentColor,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[

                              CircleAvatar(
                                radius: 65,
                                backgroundImage: CachedNetworkImageProvider(currentUser.value.image?.url),
                              ),

                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {
                                    _selectImage(context);
                                  },
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 15,
                                      child: Icon(Icons.camera_alt, size: 17.0, color: Color(0xFF404040),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(currentUser.value.name, textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline5.merge(TextStyle(color: Theme.of(context).primaryColor)),
                        ),
                      ],
                    ),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Icon(
                      Icons.person,
                      color: Theme.of(context).hintColor,
                    ),
                    title: Text(
                      S.of(context).about,
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _con.user.bio,
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _selectImage(BuildContext context) {

    showDialog(
        context: context,
        builder: (BuildContext context) {

          return ProfileImagePickerWidget(con: _con,);
        }
    );
  }
}
