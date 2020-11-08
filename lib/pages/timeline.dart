import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/pages/home.dart';
import 'package:social_media/pages/search.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/post.dart';
import 'package:social_media/widget/progress.dart';

class Timeline extends StatefulWidget {
  final currentUser;

  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];
  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowingList();
  }

  getFollowingList() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser.id)
        .collection("peopleIamFollowing")
        .get();
    snapshot.docs.forEach((doc) {
      followingList.add(doc.id.toString());
    });
  }
  //TODO make the user's own posts to appear in his/her own timeline

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(currentUser.id)
        .collection('timelinePost')
        .orderBy("timeStamp", descending: true)
        .get();

    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress(context);
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    }
    return ListView(
      children: posts,
    );
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          userRef.orderBy("timestamp", descending: true).limit(30).snapshots(),
      builder: ((context, snapshot) {
        if (!snapshot.hasData) return circularProgress(context);
        List<UserResult> userResults = [];
        snapshot.data.docs.forEach((doc) {
          User user = User.fromDocument(doc);
          bool isAuthUser = currentUser.id == user.id;
          bool isFollowing = followingList.contains(user.id);

          if (isAuthUser || isFollowing) {
            return;
          } else{
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
            print("The resulted user: " + user.displayName);
          }
        });
        return Container(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            // child: Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 30.0,
                        ),
                        Text(
                          " Users to Follow",
                          style: TextStyle(fontSize: 30.0),
                        )
                      ],
                    ),
                  ),
                  Column(
                    children: userResults.isEmpty?[Text('No Users Available to follow!')]:userResults,
                  ),
                ],
              ),
            // )
            );
      }),
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true, titleText: "SocialMediaApp"),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
