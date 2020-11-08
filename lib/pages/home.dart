import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_media/pages/activity_feed.dart';
import 'package:social_media/pages/create_account.dart';
import 'package:social_media/pages/profile.dart';
import 'package:social_media/pages/search.dart';
import 'package:social_media/pages/timeline.dart';
import 'package:social_media/pages/upload.dart';
import 'package:social_media/models/user.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final userRef = FirebaseFirestore.instance.collection('users');
final postRef = FirebaseFirestore.instance.collection('users');
final commentRef = FirebaseFirestore.instance.collection('comments');
final feedRef = FirebaseFirestore.instance.collection('feed');
final followerRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _unAuthScaffoldKey = GlobalKey<ScaffoldState>();
  final _mainScaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    tryToSignIn();
    //TODO correct the double signing at a time in here!
  }

  Future<bool> checkConnectivity() async {
    bool result = await DataConnectionChecker().hasConnection;
    if (result == true) {
      print('Working Connection Available!');
    } else {
      print('No internet :( Reason:${DataConnectionChecker().lastTryResults}');
    }
    return result;
  }

  showCustomErrorSnackBar(String text, Color color) {
    SnackBar snackBar = SnackBar(
      content: Text(
        text,
        style: TextStyle(fontSize: 17, fontFamily: 'Maiandra'),
      ),
      backgroundColor: color,
      duration: Duration(milliseconds: 1500),
    );
    _unAuthScaffoldKey.currentState.showSnackBar(snackBar);
  }

  tryToSignIn() {
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignInAccount(account);
    }, onError: (err) {
      print('Error Signing In: $err');
    });

    googleSignIn
        .signInSilently(suppressErrors: false)
        .then((account) => handleSignInAccount(account))
        .catchError((err) {
      print('Error signing silently: $err');
    });
  }

  handleSignInAccount(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getIosPermission();
    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token");
      userRef.doc(user.id).update({
        "androidNotificationToken": token,
      });
    });

    _firebaseMessaging.configure(
        //While the user isn't using the app
        // onLaunch:
        //While the app is on the background
        // onResume:
        //Triggered while the user is actively using the app
        onMessage: (Map<String, dynamic> message) async {
      print('Message: $message');
      final recipientId = message['data']['recipient'];
      final body = message['notification']['body'];

      if (recipientId == user.id) {
        print('Notification shown!');
        SnackBar snackBar = SnackBar(
          content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ),
        );
        _mainScaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
  }

  getIosPermission() {
    _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(alert: true, badge: true, sound: true),
    );
    _firebaseMessaging.onIosSettingsRegistered.listen((event) {
      print("Settings Registered: $event");
    });
  }

  createUserInFirestore() async {
    final user = googleSignIn.currentUser;
    DocumentSnapshot documentSnapshot = await userRef.doc(user.id).get();

    if (!documentSnapshot.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      userRef.doc(user.id).set({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "displayName": user.displayName,
        "email": user.email,
        "bio": "",
        "timestamp": timestamp,
      });
      documentSnapshot = await userRef.doc(user.id).get();
    }
    currentUser = User.fromDocument(documentSnapshot);
    print(currentUser);
    print(currentUser.username + " Just logged in!");
  }

  signIn() async {
    bool isConnected = await checkConnectivity();
    if (!isConnected) {
      showCustomErrorSnackBar("No connection was detected!", Colors.red);
    } else {
      googleSignIn.signIn();
    }
  }

  signOut() {
    googleSignIn.signOut();
    print("user logged out successfully");
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        curve: Curves.bounceInOut, duration: Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Widget buildAuthScreen() {
    return Scaffold(
      key: _mainScaffoldKey,
      body: PageView(
        children: [
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 36.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
        key: _unAuthScaffoldKey,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).accentColor,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'SocialMediaApp',
                style: TextStyle(
                    fontFamily: 'Signatra', fontSize: 90, color: Colors.white),
              ),
              GestureDetector(
                onTap: signIn,
                child: Container(
                  width: 260.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image:
                          AssetImage('assets/images/google_signin_button.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              RaisedButton(
                onPressed: signOut,
                child: Text("Logout"),
              )
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: isAuth ? buildAuthScreen() : buildUnAuthScreen());
  }
}
