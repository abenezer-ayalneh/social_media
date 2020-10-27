import 'package:flutter/material.dart';
import 'package:social_media/widget/custom_image.dart';
import 'package:social_media/widget/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>print('showing post'),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
