import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoder/geocoder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/pages/home.dart';
import 'package:social_media/widget/header.dart';
import 'package:social_media/widget/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as Im;

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

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
    file = await ImagePicker.pickImage(
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
    file = await ImagePicker.pickImage(
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
              disabledColor: Colors.grey,
              child: Text(
                'Post',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
              onPressed: isUploading ? null : () => postMethod(),
            ),
          ]),
      body: ListView(
        children: [
          isUploading ? linearProgress(context) : Text(""),
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
                controller: captionController,
                textCapitalization: TextCapitalization.sentences,
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
                controller: locationController,
                textCapitalization: TextCapitalization.words,
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
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location_sharp,
                color: Colors.white,
              ),
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

  getUserLocation() async{
    Position position = await GeolocatorPlatform.instance.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final addresses= await Geocoder.local.findAddressesFromCoordinates(Coordinates(position.latitude, position.longitude));
    Address address = addresses[0];
    String formattedAddress = "${address.locality}, ${address.countryName}";
    locationController.text = formattedAddress;
    //TODO Permission handling required!
  }

  compressImage() async {
    final imageBytes = await file.readAsBytes();
    final toBeDecodedImage = imageBytes.toList();
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(toBeDecodedImage);
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(
        Im.encodeJpg(imageFile, quality: 70),
      );
    setState(() {
      file = compressedImageFile;
    });
  }

  postMethod() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirebase(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );

    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  createPostInFirebase({String mediaUrl, String location, String description}) {
    postRef.doc(widget.currentUser.id).collection('userPost').doc(postId).set({
      'postId': postId,
      'userId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'description': description,
      'location': location,
      'timeStamp': timestamp,
      'likes': {}
    });
  }

  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  clearImage() {
    setState(() {
      file = null;
    });
    //TODO Make this work with the back button too and display an "are you sure?" popup before clearing!
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
