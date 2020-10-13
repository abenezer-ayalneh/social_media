import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/widget/header.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  PickedFile file;
  bool isUploading = false;

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        children: [
          SvgPicture.asset('assets/images/upload.svg'),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              color: Colors.deepOrange,
              child: Text(
                'Upload Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                ),
              ),
              onPressed: () => selectImage(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Create Post'),
          children: [
            SimpleDialogOption(
              child: Text('Camera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('From Gallery'),
              onPressed: handleGalleryPhoto,
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    ImagePicker imagePicker = ImagePicker();
    file = await imagePicker.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      file = this.file;
    });
  }

  handleGalleryPhoto() async {
    Navigator.pop(context);
    ImagePicker imagePicker = ImagePicker();
    file = await imagePicker.getImage(
      source: ImageSource.gallery,
    );
    setState(() {
      file = this.file;
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: header(context,
          isAppTitle: false,
          titleText: "Upload",
          prefix: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: clearImage,
          ),
          action: [
            FlatButton(
              child: Text(
                'Post',
                style: TextStyle(
                  color: Colors.white,
                  // fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              onPressed: ()=>postMethod(),
            ),
          ]),
      body: ListView(
        children: [
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        fit: BoxFit.cover, image: FileImage(File(file.path))),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 25.0,
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Write a caption...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange[300],
              size: 25.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: () => print("get user's location"),
              icon: Icon(Icons.my_location_sharp,color: Colors.white,),
              label: Text(
                "Use current location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: Colors.lightBlue,
            ),
          ),
        ],
      ),
    );
  }

  postMethod() {
    
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
