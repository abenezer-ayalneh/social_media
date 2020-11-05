const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore.document("/followers/{userId}/peopleFollowingMe/{followerId}").onCreate(
    async (snapshot, context) => {
        console.log("FollowerCreated",snapshot.data());
        const userId = context.params.userId;
        const followerId = context.params.followerId;

        const followedUserPostRef = admin.firestore().collection("users").doc(userId).collection("userPost");
        const timelinePostRef = adimin.firestore().collection("timeline").doc(followerId).collection("timelinePost");

        const querySnapshot = await followedUserPostRef.get();

        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data;
                timelinePostRef.doc(postId).set(postData);
            }

        });
    }
);