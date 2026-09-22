const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {getFirestore} = require("firebase-admin/firestore");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

// Use the exact database "algohary" for triggers and DB queries
const db = getFirestore("algohary");

exports.onMessageSent = onDocumentCreated({
  document: "conversations/{conversationId}/messages/{messageId}",
  database: "algohary",
}, async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const message = snapshot.data();
  const senderId = message.senderId;
  const conversationId = event.params.conversationId;

  // Optimize: Avoid querying conversations and sender documents!
  // The client app should send 'recipientId', 'senderName',
  // and 'senderAvatar' directly in the message document.
  const recipientId = message.recipientId;
  if (!recipientId) return;

  try {
    // 1. Fetch ONLY the recipient details to get the FCM token
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    if (!recipientDoc.exists) return;

    const recipientData = recipientDoc.data();
    const fcmToken = recipientData.fcm_token;
    // Default fallback values if not sent by client
    const senderName = message.senderName || "User";
    const senderAvatar = message.senderAvatar || null;

    // Snippet for notification
    let snippet = message.content || "Sent a media file";
    if (snippet.length > 50) snippet = snippet.substring(0, 50) + "...";

    // 2. Create In-App Notification Document (1 Write)
    const notificationRef = db
        .collection("users")
        .doc(recipientId)
        .collection("notifications")
        .doc();

    await notificationRef.set({
      id: notificationRef.id,
      title: `${senderName} sent you a message`,
      body: snippet,
      type: "CHAT_MESSAGE",
      referenceId: conversationId,
      senderId: senderId,
      senderAvatar: senderAvatar,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Send Push Notification if FCM token exists
    if (fcmToken) {
      const payload = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: snippet,
        },
        data: {
          type: "chat_message",
          conversationId: conversationId,
        },
        android: {
          priority: "high",
          notification: {
            sound: "notification",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "notification.mp3",
            },
          },
        },
      };

      await admin.messaging().send(payload);
    }
  } catch (error) {
    console.error("Error processing onMessageSent:", error);
  }
});
