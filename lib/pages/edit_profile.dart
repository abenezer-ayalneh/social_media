import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import "package:flutter/material.dart";
import 'package:social_media/models/user.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/progress.dart';
import 'home.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  bool isDisplayNameValid = true;
  User user;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool _bioValidator = true;
  bool _displayNameValidator = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    final doc = await userRef.doc(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  updateProfile() async {
    setState(() {
      displayNameController.text.trim().length < 3
          ? _displayNameValidator = false
          : _displayNameValidator = true;
      bioController.text.trim().length > 50
          ? _bioValidator = false
          : _bioValidator = true;
    });
    if (_displayNameValidator && _bioValidator) {
      await userRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text
      });
      SnackBar snackBar = SnackBar(
        content: Text('Profile Updated'),
        backgroundColor: Colors.green,
      );
      Timer(Duration(seconds: 1), () {
        Navigator.pop(context, <String>[user.bio, user.displayName]);
      });
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  signOut() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(
        context,
        titleText: 'Edit Profile',
        applyDefaultBackButton: true,
        action: [
          IconButton(
            icon: Icon(
              Icons.done,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: updateProfile,
          )
        ],
      ),
      body: isLoading
          ? circularProgress(context)
          : ListView(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(
                    top: 5.0,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            CachedNetworkImageProvider(user.photoUrl),
                        radius: 60.0,
                      )
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.only(top: 5.0, left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(top: 15.0),
                        child: Text(
                          "Display Name",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(5.0),
                        child: TextFormField(
                          autofocus: true,
                          onEditingComplete:
                              displayNameController.text.isNotEmpty
                                  ? () => {
                                        setState(() {
                                          isDisplayNameValid = true;
                                        })
                                      }
                                  : () => {
                                        setState(() {
                                          isDisplayNameValid = false;
                                        })
                                      },
                          autovalidateMode: AutovalidateMode.always,
                          controller: displayNameController,
                          decoration: InputDecoration(
                              hintText: "Display Name goes here..."),
                          validator: (text) {
                            if (text.trim().length < 1) {
                              return "Display name can't be empty!";
                            } else {
                              return null;
                            }
                          },
                        ),
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(top: 15.0),
                        child: Text(
                          "Bio",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(5.0),
                        child: TextFormField(
                          autovalidateMode: AutovalidateMode.always,
                          validator: (text) {
                            if (text.length > 50) {
                              return "Bio can't be greater than 50 charachters!";
                            } else {
                              return null;
                            }
                          },
                          controller: bioController,
                          decoration:
                              InputDecoration(hintText: "Bio goes here..."),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0),
                        alignment: Alignment.center,
                        child: RaisedButton(
                          onPressed: updateProfile,
                          child: Text(
                            "Update Profile",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0),
                        alignment: Alignment.center,
                        child: FlatButton.icon(
                            onPressed: signOut,
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            label: Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
