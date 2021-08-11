import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import '../../models/ride.dart';
import '../../helpers/ride_contact.dart';
import '../../repository/ride/ride_repository.dart';

import '../../../generated/l10n.dart';
import 'package:intl/intl.dart';

class RidesWidget extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;

  RidesWidget({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _RidesWidgetState createState() => _RidesWidgetState();
}

class _RidesWidgetState extends StateMVC<RidesWidget> implements RideContact {

  RideRepository _rideRepo;
  RideContact _contact;

  LocationOptions locationOptions;
  StreamSubscription<Position> positionStream;

  int _currentIndex = 0;

  bool _isCallMade = false;


  @override
  void initState() {

    _contact = this;
    _rideRepo = RideRepository(_contact);

    locationOptions = LocationOptions(accuracy: LocationAccuracy.best, timeInterval: 2);

    positionStream = Geolocator().getPositionStream(locationOptions).listen((Position position) {

      print(position.toString());

      if(position != null && online.value) {

        _rideRepo.updateRiderLocation(position);
      }
    });

    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder(
      valueListenable: online,
      builder: (BuildContext context, bool isOnline, _) {

        return Scaffold(
          appBar: AppBar(
            leading: new IconButton(
              icon: new Icon(Icons.menu, color: Theme.of(context).hintColor),
              onPressed: () => widget.parentScaffoldKey.currentState.openDrawer(),
            ),
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(isOnline ? S.of(context).online : S.of(context).offline,
              style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3)),
            ),
            actions: <Widget>[

              Switch(
                value: isOnline,
                activeColor: Colors.blue,
                activeTrackColor: Theme.of(context).accentColor,
                inactiveThumbColor: Colors.redAccent,
                inactiveTrackColor: Colors.grey[200],
                onChanged: (value) {
                  _rideRepo.updateRiderStatus(context);
                },
              ),
            ],
          ),
          body: Builder(
            builder: (BuildContext context) {

              if(!_isCallMade) {

                _isCallMade = true;
                _rideRepo.getActiveRide(context);
              }

              return IndexedStack(
                index: _currentIndex,
                children: <Widget>[

                  Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).accentColor),
                      )
                  ),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[

                        Text(S.of(context).could_not_connect,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                        ),

                        SizedBox(height: 30,),

                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {

                            setState(() {
                              _currentIndex = 0;
                            });

                            _rideRepo.getActiveRide(context);
                          },
                          child: Material(
                            elevation: 10,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                              child: Text(S.of(context).try_again.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: rideRequests,
                      builder: (BuildContext context, List<Ride> rides, _) {

                        return rides.length == 0 ? Center(
                          child: Text(S.of(context).no_rides_nearby, style: Theme.of(context).textTheme.caption.copyWith(fontSize: 25),),
                        ) : Stack(
                          children: <Widget>[

                            Container(
                              margin: EdgeInsets.only(top: 70),
                              child: ListView.separated(
                                itemCount: rides.length,
                                separatorBuilder: (BuildContext context, int index) {
                                  return SizedBox(height: 2,);
                                },
                                itemBuilder: (BuildContext context, int index) {

                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      Navigator.of(context).pushNamed('/RideAccept', arguments: rides[index]);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
                                      child: Material(
                                        elevation: 8,
                                        borderRadius: BorderRadius.circular(5),
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 10, right: 15, top: 20, bottom: 20),
                                          child: IntrinsicHeight(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: <Widget>[

                                                Padding(
                                                  padding: EdgeInsets.only(left: 10, right: 10),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.max,
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: <Widget>[

                                                      Text(rides[index].date,
                                                        style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                                      ),

                                                      Text(rides[index].time,
                                                        style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                SizedBox(height: 20,),

                                                Row(
                                                  mainAxisSize: MainAxisSize.max,
                                                  children: <Widget>[

                                                    Expanded(
                                                      flex: 7,
                                                      child: Padding(
                                                        padding: EdgeInsets.only(left: 10, right: 15),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.max,
                                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: <Widget>[

                                                            IntrinsicHeight(
                                                              child: Row(
                                                                children: <Widget>[

                                                                  Container(
                                                                    width: 7,
                                                                    height: 7,
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.white,
                                                                      border: Border.all(color: Colors.black54),
                                                                    ),
                                                                  ),

                                                                  SizedBox(width: 15,),

                                                                  Flexible(
                                                                    child: Text(rides[index].pickupAddress,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      maxLines: 2,
                                                                      style: Theme.of(context).textTheme.subtitle2,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),

                                                            SizedBox(height: 25,),

                                                            IntrinsicHeight(
                                                              child: Row(
                                                                children: <Widget>[

                                                                  Container(
                                                                    width: 7,
                                                                    height: 7,
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.black,
                                                                      border: Border.all(color: Colors.black38),
                                                                    ),
                                                                  ),

                                                                  SizedBox(width: 15,),

                                                                  Flexible(
                                                                    child: Text(rides[index].dropOffAddress,
                                                                      style: Theme.of(context).textTheme.subtitle2,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    Expanded(
                                                      flex: 1,
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: Theme.of(context).accentColor,
                                                        child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20,),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.only(top: 20, left: 30, right: 10, bottom: 20),
                              child: Text(S.of(context).ride_requests,
                                style: Theme.of(context).textTheme.headline4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  @override
  void dispose() {

    positionStream.cancel();
    super.dispose();
  }


  @override
  void onOnline() {

    online.value = true;
    online.notifyListeners();

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).now_online)));
  }


  @override
  void onOffline() {

    online.value = false;
    online.notifyListeners();

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).now_offline)));
  }


  @override
  void onFailed(BuildContext context, String message) {

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  void onActiveRideFound(BuildContext context, List<Ride> rides) {

    if(rides.length > 0) {

      Navigator.of(context).pushNamed('/RideAccept', arguments: rides.first);
    }
    else {

      setState(() {
        _currentIndex = 2;
      });
    }
  }


  @override
  void onConnectFail(BuildContext context, String message) {

    setState(() {
      _currentIndex = 1;
    });
  }
}
