import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:quickrider/generated/l10n.dart';
import '../../repository/ride/ride_accept_repository.dart';
import '../../repository/user_repository.dart';
import '../../helpers/constants.dart';
import '../../helpers/my_ride_contact.dart';
import '../../models/ride.dart';
import '../../repository/ride/ride_repository.dart';

class MyRides extends StatefulWidget {

  final GlobalKey<ScaffoldState> parentScaffoldKey;

  MyRides({Key key, this.parentScaffoldKey}) : super(key: key);

  @override
  _MyRidesState createState() => _MyRidesState();
}

class _MyRidesState extends State<MyRides> implements MyRideContact {

  RideAcceptRepository _acceptRepo;
  MyRideContact _contact;

  List<Ride> _myRides = [];
  bool _isCallMade = false;
  int _currentIndex = 0;

  TextEditingController _reviewController = TextEditingController();


  @override
  void initState() {

    _contact = this;
    _acceptRepo = RideAcceptRepository(myRideContact: _contact);

    super.initState();
  }


  @override
  Widget build(BuildContext context) {

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
        title: Text(S.of(context).my_rides,
          style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3)),
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {

            if(!_isCallMade) {

               _isCallMade = true;
              _acceptRepo.getRideHistory(context);
            }

            return IndexedStack(
              index: _currentIndex,
              children: <Widget>[

                Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).accentColor),
                  )
                ),

                Container(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {

                        setState(() {
                          _currentIndex = 0;
                        });

                        _acceptRepo.getRideHistory(context);
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
                  ),
                ),

                RefreshIndicator(
                  onRefresh: () async {

                    setState(() {
                      _currentIndex = 0;
                    });

                    _acceptRepo.getRideHistory(context);
                    return;
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 10),
                    child: ListView.separated(
                      itemCount: _myRides.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(height: 2);
                      },
                      itemBuilder: (BuildContext context, int index) {

                        return Padding(
                          padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(5),
                            child: Padding(
                              padding: EdgeInsets.only(left: 10, right: 15, top: 20, bottom: 15),
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[

                                    Padding(
                                      padding: EdgeInsets.only(left: 10, right: 10),
                                      child: Text(_myRides[index].startTime == null ? (_myRides[index].createdAt == null ? "" :
                                      S.of(context).date + ": " + _myRides[index].createdAt) :
                                      S.of(context).start_time + ": " + _myRides[index].startTime,
                                        style: Theme.of(context).textTheme.caption.copyWith(fontSize: 15),
                                      ),
                                    ),

                                    Visibility(
                                      visible: _myRides[index].startTime != null || _myRides[index].endTime != null,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                                        child: Text(_myRides[index].endTime == null ? "" : S.of(context).end_time + ": " + _myRides[index].endTime,
                                          style: Theme.of(context).textTheme.caption.copyWith(fontSize: 15),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 20,),

                                    Padding(
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
                                                  child: Text(_myRides[index].pickupAddress == null ? "" : _myRides[index].pickupAddress,
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
                                                  child: Text(_myRides[index].dropOffAddress == null ? "" : _myRides[index].dropOffAddress,
                                                    style: Theme.of(context).textTheme.subtitle2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 20,),

                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[

                                        Visibility(
                                          visible: _myRides[index].status == Constants.canceled &&
                                              _myRides[index].cancellationFee.isNotEmpty && _myRides[index].cancelledBy != currentUser.value.id && _myRides[index].review.isEmpty,
                                          child: Expanded(
                                            flex: 1,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {

                                                _getReview(context, _myRides[index]);
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                height: 35,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(2),
                                                    border: Border.all(width: 1, color: Colors.black26)
                                                ),
                                                child: Text(S.of(context).review,
                                                  style: Theme.of(context).textTheme.subtitle2.copyWith(color: Theme.of(context).accentColor),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        Visibility(
                                          visible: _myRides[index].status == Constants.canceled &&
                                              _myRides[index].cancellationFee.isNotEmpty && _myRides[index].cancelledBy != currentUser.value.id && _myRides[index].review.isEmpty,
                                          child: SizedBox(
                                            width: 15,
                                          ),
                                        ),

                                        Expanded(
                                          flex: 1,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {

                                              Navigator.of(context).pushNamed('/RideDetails', arguments: _myRides[index]);
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              height: 35,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(2),
                                                  border: Border.all(width: 1, color: Colors.black26)
                                              ),
                                              child: Text(S.of(context).viewDetails,
                                                style: Theme.of(context).textTheme.subtitle2.copyWith(color: Theme.of(context).accentColor),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 30, right: 30),
                    child: Text(S.of(context).no_ride_history,
                      style: Theme.of(context).textTheme.caption.copyWith(fontSize: 22),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  @override
  void onFailed(BuildContext context, String message) {

    setState(() {
      _currentIndex = 1;
    });

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Future<void> showMyRides(List<Ride> rides) async {

    rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if(rides.length > 0) {

      for(int i=0; i<rides.length; i++) {

        if(rides[i].pickupPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(rides[i].pickupPoint.latitude, rides[i].pickupPoint.longitude));
          rides[i].pickupAddress = addresses.first.addressLine;
        }

        if(rides[i].dropOffPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(rides[i].dropOffPoint.latitude, rides[i].dropOffPoint.longitude));
          rides[i].dropOffAddress = addresses.first.addressLine;
        }

        if(i == rides.length - 1) {

          setState(() {
            _myRides = rides;
            _currentIndex = 2;
          });
        }
      }
    }
    else {

      setState(() {
        _currentIndex = 3;
      });
    }
  }


  void _getReview(BuildContext scaffoldContext, Ride ride) {

    _reviewController.text = "";
    bool reviewed = true;

    showDialog(
      context: scaffoldContext,
      barrierDismissible: true,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => true);
          },
          child: Dialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {

                return Container(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      Flexible(
                        child: TextField(
                          controller: _reviewController,
                          enabled: true,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 2,
                          maxLength: 250,
                          style: Theme.of(context).textTheme.bodyText2.copyWith(letterSpacing: .1, wordSpacing: .2, height: 1.3),
                          decoration: InputDecoration(
                            hintText: S.of(context).your_review_here,
                            hintStyle: Theme.of(context).textTheme.caption,
                            errorText: !reviewed ? S.of(context).review_error_msg : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0, style: BorderStyle.none,),
                            ),
                            filled: true,
                            contentPadding: EdgeInsets.all(10),
                            fillColor: Colors.black12.withOpacity(.035),
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      FlatButton(
                        color: Theme.of(context).accentColor,
                        textColor: Colors.white,
                        child: Text(S.of(context).submit),
                        onPressed: () {

                          if(_reviewController.text == null || _reviewController.text.isEmpty) {

                            setState(() {
                              reviewed = false;
                            });
                          }
                          else {

                            setState(() {
                              reviewed = true;
                            });

                            Navigator.of(context).pop();

                            Ride mRide = Ride(id: ride.id, review: _reviewController.text);
                            _acceptRepo.updateRideInfo(scaffoldContext, mRide);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }


  @override
  void onReviewFailed(BuildContext context) {

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).review_failed)));
  }


  @override
  void onReviewSuccess(BuildContext context, Ride ride) {

    for(int i=0; i<_myRides.length; i++) {

      if(_myRides[i].id == ride.id) {

        setState(() {
          _myRides[i].review = ride.review;
        });

        break;
      }
    }

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(S.of(context).review_success)));
  }
}
