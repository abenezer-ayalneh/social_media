import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/pages/edit_profile.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/post.dart';
import 'package:social_media/widget/post_tile.dart';
import 'package:social_media/widget/progress.dart';
import 'package:social_media/pages/home.dart';

enum PostOrientation { grid, list, none }

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String currentUserId = currentUser.id;
  String bio = "";
  String displayName = "";
  bool isLoading = false;
  List<Post> posts = [];
  int postsCount = 0;
  PostOrientation postOrientation = PostOrientation.grid;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .doc(widget.profileId)
        .collection('userPost')
        .orderBy('timeStamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postsCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  editProfile() async {
    final List<String> returnData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(currentUserId: currentUserId),
      ),
    );
    setState(() {
      displayName = returnData[1];
      bio = returnData[0];
    });
  }

  Container buildButon({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          width: 250.0,
          height: 30.0,
        ),
        onPressed: function,
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButon(text: "Edit Profile", function: editProfile);
    }
  }

  Column buildCountColumn(String lable, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            lable,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15.0,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress(context);
        }
        User user = User.fromDocument(snapshot.data);
        displayName = user.displayName;
        bio = user.bio;
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            buildCountColumn("Posts", postsCount),
                            buildCountColumn("Followers", 0),
                            buildCountColumn("Following", 0),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  "@${user.username}",
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Container noPostContainer() {
    return Container(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/no_content.svg',
            height: 300,
          ),
          Text(
            "No Posts Yet!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              fontSize: 60.0,
            ),
          )
        ],
      ),
    );
  }

  Widget buildProfilePosts() {
    if (postOrientation == PostOrientation.grid && posts.isNotEmpty) {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(
          GridTile(
            child: PostTile(post),
          ),
        );
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == PostOrientation.list && posts.isNotEmpty) {
      return Column(
        children: posts,
      );
    } else {
      return noPostContainer();
    }
  }

  setPostOrientation(PostOrientation orientation) {
    setState(() {
      postOrientation = orientation;
    });
  }

  buildTogglePostOrientation() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.grid_on),
            onPressed: () => setPostOrientation(PostOrientation.grid),
            color: postOrientation == PostOrientation.grid
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => setPostOrientation(PostOrientation.list),
            color: postOrientation == PostOrientation.list
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Profile'),
      body: ListView(children: [
        buildProfileHeader(),
        Divider(
          height: 0.0,
          color: Colors.black45,
        ),
        buildTogglePostOrientation(),
        Divider(
          height: 0.0,
          color: Colors.black45,
        ),
        buildProfilePosts(),
      ]),
    );
  }
}
