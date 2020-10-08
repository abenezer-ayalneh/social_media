import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/widget/header.dart';

final userRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  void setState(fn) {
    // TODO: implement setState
    super.setState(fn);
    getUsers();
  }

  getUsers() {
    userRef.get().then((snapShot) => snapShot.docs.forEach((element) {
          print(element.data);
        }));
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
    );
  }
}
