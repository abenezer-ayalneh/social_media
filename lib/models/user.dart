import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;

  User(
      {this.id,
      this.username,
      this.email,
      this.photoUrl,
      this.displayName,
      this.bio});
//TODO Learn about the factory data type!
  factory User.fromDocument(DocumentSnapshot documentSnapshot) {
    return User(
      id: documentSnapshot["id"],
      username: documentSnapshot['username'],
      email: documentSnapshot["email"],
      photoUrl: documentSnapshot["photoUrl"],
      displayName: documentSnapshot["displayName"],
      bio: documentSnapshot["bio"]
    );
  }
}
