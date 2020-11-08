import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/pages/activity_feed.dart';
import 'package:social_media/pages/comments.dart';
import 'package:social_media/pages/home.dart';
import 'package:social_media/widget/custom_image.dart';
import 'package:social_media/widget/progress.dart';
import 'package:animator/animator.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot snapshot) {
    return Post(
      postId: snapshot['postId'],
      ownerId: snapshot['userId'],
      username: snapshot['username'],
      location: snapshot['location'],
      description: snapshot['description'],
      mediaUrl: snapshot['mediaUrl'],
      likes: snapshot['likes'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) return 0;
    int counter = 0;
    likes.values.forEach((value) {
      if (value == true) {
        counter += 1;
      }
    });
    return counter;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likeCount: getLikeCount(this.likes),
        likes: this.likes,
      );
}

class _PostState extends State<Post> {
  final currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: userRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
          ),
          title: GestureDetector(
            child: Text(
              user.displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              ),
            ),
            onTap: () => showProfile(context, profileId: ownerId),
          ),
          subtitle: Text(
            location,
            style: TextStyle(color: Colors.grey),
          ),
          trailing: isPostOwner
              ? IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => handleDeletePost(context),
                )
              : Text(""),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: ((context) {
        return SimpleDialog(
          title: Text("Are you sure?"),
          children: [
            SimpleDialogOption(
              child: Text(
                "Yes",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                deletePost(parentContext);
              },
            ),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      }),
    );
  }

  deletePost(BuildContext parentContext) async {
    //deleting the post from the userPost collection
    postRef
        .doc(currentUser.id)
        .collection('userPost')
        .doc(postId)
        .get()
        .then((post) => {
              if (post.exists) {post.reference.delete()}
            });

    //deleting the post from the firestore
    storageRef.child("post_$postId.jpg").delete();

    //deleting all activity feeds related to that post
    feedRef
        .doc(currentUserId)
        .collection("feedItems")
        .where("postId", isEqualTo: postId)
        .get()
        .then((snapshot) => {
              snapshot.docs.forEach((doc) {
                if (doc.exists) {
                  doc.reference.delete();
                }
              })
            });
    
    //deleting all the comments related to the post
    commentRef.doc(postId).get().then((value) => {
      if(value.exists){
        value.reference.delete()
      }
    });
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
            ),
            GestureDetector(
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
              onTap: handleLikePost,
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0),
            ),
            GestureDetector(
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
              onTap: () => showComments(context,
                  postId: postId, ownerId: ownerId, mediaUrl: mediaUrl),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount Likes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  handleLikePost() {
    bool _hasLikedBefore = likes[currentUserId] == true;

    if (_hasLikedBefore) {
      postRef
          .doc(ownerId)
          .collection("userPost")
          .doc(postId)
          .update({"likes.$currentUserId": false});
      removeLikeFromActivityFeed();
      setState(() {
        isLiked = false;
        likeCount -= 1;
        likes[currentUserId] = false;
      });
    } else if (!_hasLikedBefore) {
      postRef
          .doc(ownerId)
          .collection("userPost")
          .doc(postId)
          .update({"likes.$currentUserId": true});
      addLikeToActicityFeed();
      setState(() {
        isLiked = true;
        likeCount += 1;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActicityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      feedRef.doc(ownerId).collection("feedItems").doc(postId).set({
        "username": currentUser.username,
        "type": "like",
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timeStamp": timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      feedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((value) {
        if (value.exists) {
          value.reference.delete();
        } else {
          print("The document you were trying to delete doesn't exist!");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    isLiked = likes[currentUserId] == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(context, {postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
        postId: postId, postOwnerId: ownerId, postMediaUrl: mediaUrl);
  }));
}
