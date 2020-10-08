import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_media/pages/activity_feed.dart';
import 'package:social_media/pages/profile.dart';
import 'package:social_media/pages/search.dart';
import 'package:social_media/pages/timeline.dart';
import 'package:social_media/pages/upload.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
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

  handleSignInAccount(GoogleSignInAccount account) {
    if (account != null) {
      print('The user $account just signed in!');
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  signIn() {
    googleSignIn.signIn();
  }

  signOut() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,curve: Curves.bounceInOut, duration: Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Widget buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Timeline(),
          ActivityFeed(),
          Upload(),
          Search(),
          Profile(),
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
          BottomNavigationBarItem(
               icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(
               icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
              
              icon: Icon(
                Icons.photo_camera,
                size: 36.0,
              )),
          BottomNavigationBarItem( icon: Icon(Icons.search)),
          BottomNavigationBarItem(
               icon: Icon(Icons.account_circle)),
        ],
      ),
      
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
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
            onTap: () {
              signIn();
            },
            child: Container(
              width: 260.0,
              height: 60.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/google_signin_button.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
