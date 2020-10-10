import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/progress.dart';

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final CollectionReference userRef =
      FirebaseFirestore.instance.collection('users');
  // List<dynamic> userList = [];

  @override
  void initState() {
    // getUsers();
    super.initState();
  }

  // getUsers() async {
  //   // userRef.get().then((value) => value.docs.forEach((element) {print(element.data());}));
  //   final querySnapshot = await userRef.get();
  //   setState(() {
  //     userList = querySnapshot.docs;
  //   });
  // }

  getUserById() async {
    final String id = '0dxxvCx6lBsEoKKslVXM';
    // userRef.doc(id).get().then((value) => print(value["username"]));
    final documentSnapshot = await userRef.doc(id).get();
    if (documentSnapshot.exists) {
      print(documentSnapshot["username"]);
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: StreamBuilder<QuerySnapshot>(
          stream: userRef.snapshots(),
          builder: (context, querySnapshot) {
            if (!querySnapshot.hasData) return circularProgress(context);
            return Container(
              alignment: Alignment.center,
              child: Center(
                child: ListView(
                  children:
                      querySnapshot.data.docs.map((user) => Text(user["username"])).toList(),
                ),
              ),
            );
          }),
    );
  }
}
