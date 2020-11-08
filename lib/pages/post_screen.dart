import 'package:flutter/material.dart';
import 'package:social_media/pages/home.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/post.dart';
import 'package:social_media/widget/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postRef
          .doc(userId)
          .collection("userPost")
          .doc(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Scaffold(
              appBar: header(context,
                  applyDefaultBackButton: true, titleText: "Fetching data..."),
              body: ListView(
                children: [circularProgress(context)],
              ),
            ),
          );
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context,
                titleText: post.description, applyDefaultBackButton: true),
            body: ListView(
              children: [
                Container(
                  child: post,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
