import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle: false, String titleText, bool removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton,
    title: Text(
      isAppTitle ? 'Social Media App' : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? 'Signatra' : 'Maiandra',
        fontSize: isAppTitle ? 45.0 : 20.0,
      ),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
