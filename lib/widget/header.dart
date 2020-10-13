import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle: false, String titleText, bool applyDefaultBackButton = false, IconButton prefix, List<Widget> action}) {
  return AppBar(
    leading: prefix,
    
    automaticallyImplyLeading: applyDefaultBackButton,
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
    actions: action,
  );
}
