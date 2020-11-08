const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
  .document("/followers/{userId}/peopleFollowingMe/{followerId}")
  .onCreate(async (snapshot, context) => {
    console.log("Follower Created", snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    // 1) Create followed users posts ref
    const followedUserPostsRef = admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("userPost");

    // 2) Create following user's timeline ref
    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePost");

    // 3) Get followed users posts
    const querySnapshot = await followedUserPostsRef.get();

    // 4) Add each user post to following user's timeline
    querySnapshot.forEach(doc => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();
        timelinePostsRef.doc(postId).set(postData);
      }
    });
  });

exports.onUnfollow = functions.firestore
  .document("/followers/{userId}/peopleFollowingMe/{followerId}")
  .onDelete(async (snapshot, context) => {
    console.log("Successfully unfollowed the user.");
    const followerId = context.params.followerId;
    const userId = context.params.userId;

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePost")
      .where("userId", "==", userId);

    const querySnapshot = await timelinePostsRef.get();

    querySnapshot.forEach(doc => {
      if (doc.exists) {
        doc.ref.delete();
      }
    });
  });

exports.onPostCreated = functions.firestore
  .document("/users/{userId}/userPost/{postId}")
  .onCreate(async (snapshot, context) => {
    const postCreted = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //getting all the followers of the user who made the post
    const userFollowersRef = admin.firestore
      .collection("followers")
      .doc(userId)
      .collection("peopleFollowingMe");

    const querySnapshot = await userFollowersRef.get();

    //adding the post to all the follower's timeline
    querySnapshot.forEach(doc => {
      const follwerId = doc.id;

      admin.firestore
        .collection('timeline')
        .doc(follwerId)
        .collection('timelinePost')
        .doc(postId)
        .set(postCreted);
    });
  });

exports.onUpdatePost = functions.firestore
  .document("/users/{userId}/userPost/{postId}")
  .onUpdate(async (change, context) => {
    const updatedPost = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //getting all the followers of the user who made the post
    const userFollowersRef = admin.firestore
      .collection("followers")
      .doc(userId)
      .collection("peopleFollowingMe");

    const querySnapshot = await userFollowersRef.get();

    //updating the post in all of the follower's timeline
    querySnapshot.forEach(doc => {
      const follwerId = doc.id;

      admin.firestore
        .collection('timeline')
        .doc(follwerId)
        .collection('timelinePost')
        .doc(postId)
        .get().then(doc => {
          if (doc.exists) {
            doc.ref.update(updatedPost);
          }
        });
    });
  });

exports.onDeletePost = functions.firestore
  .document("/users/{userId}/userPost/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    //getting all the followers of the user who made the post
    const userFollowersRef = admin.firestore
      .collection("followers")
      .doc(userId)
      .collection("peopleFollowingMe");

    const querySnapshot = await userFollowersRef.get();

    //updating the post in all of the follower's timeline
    querySnapshot.forEach(doc => {
      const follwerId = doc.id;

      admin.firestore
        .collection('timeline')
        .doc(follwerId)
        .collection('timelinePost')
        .doc(postId)
        .get().then(doc => {
          if (doc.exists) {
            doc.ref.delete();
          }
        });
    });
  });

exports.onActivityFeedItemCreated = functions.firestore
  .document('/feed/{userId}/feedItems/{feedItem}')
  .onCreate(async(snapshot,context)=>{
    console.log('Feed Item created',snapshot.id);
    const userId = context.params.userId;

    const userRef = admin.firestore().doc(`user/${userId}`);
    const doc = userRef.get();

    const androidNotificationToken = doc.data().androidNotificationToken;
    if(androidNotificationToken){
      sendNotification(androidNotificationToken,snapshot.data())
    }else{
      console.log("no token for user, can't send notification!");
    }
    function sendNotification(androidNotificationToken,feedItem){
      let body;

      switch(feedItem.type){
        case "comment":
          body = `${feedItem.username} replied: ${feedItem.commentData}`;
          break;
        case "like":
          body = `${feedItem.username} liked your post`;
          break;
        case "follow":
          body = `${feedItem.username} started following your`;
          break;
        default:
          break;
      }

      const message = {
        notification: {body},
        token: androidNotificationToken,
        data: {recipient: userId}
      };

      admin
        .messaging()
        .send(message)
        .then(response =>{
          console.log("Successfully sent notification: ",response);
        }).catch(errorMsg=>{
          console.log('Error sending message: ',errorMsg);
        });
    }
  });