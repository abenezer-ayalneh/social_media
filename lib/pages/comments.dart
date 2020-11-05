import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/progress.dart';
import 'package:social_media/pages/home.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
      stream: commentRef
          .doc(postId)
          .collection("comments")
          .orderBy("timeStamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        List<Comment> comments = [];
        snapshot.data.docs.forEach((snapshot) {
          comments.add(Comment.fromDocument(snapshot));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComment() async {
    commentRef.doc(postId).collection('comments').add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timeStamp": timestamp,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });
    await addCommentToActivityFeed();
    commentController.clear();
  }

  addCommentToActivityFeed() async {
    bool isNotPostOwner = currentUser.id != postOwnerId;
    if (isNotPostOwner) {
      feedRef.doc(postOwnerId).collection("feedItems").add({
        "type": "comment",
        "commentData": commentController.text,
        "timeStamp": timestamp,
        "postId": postId,
        "userId": currentUser.id,
        "username": currentUser.username,
        "userProfileImg": currentUser.photoUrl,
        "mediaUrl": postMediaUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          header(context, titleText: "Comments", applyDefaultBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(hintText: "Write a comment..."),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              child: Text("Post"),
              borderSide: BorderSide.none,
            ),
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String comment;
  final String avatarUrl;
  final Timestamp timeStamp;

  Comment({
    this.username,
    this.userId,
    this.comment,
    this.avatarUrl,
    this.timeStamp,
  });

  factory Comment.fromDocument(DocumentSnapshot snapshot) {
    return Comment(
      username: snapshot['username'],
      userId: snapshot['userId'],
      comment: snapshot['comment'],
      avatarUrl: snapshot['avatarUrl'],
      timeStamp: snapshot['timeStamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(currentUser.displayName,style: TextStyle(fontSize: 17.0,fontWeight: FontWeight.bold),),
          isThreeLine: true,
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
            backgroundColor: Colors.grey,
          ),
          subtitle: Text(comment + "\n" + timeago.format(timeStamp.toDate()),style: TextStyle(color: Colors.black87)),
        ),
        Divider(),
      ],
    );
  }
}
