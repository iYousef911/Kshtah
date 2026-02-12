const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

// 1. Secure Wallet Top-Up
// Ensure you run: firebase functions:config:set moyasar.secret_key="YOUR_LIVE_KEY"
const MOYASAR_SECRET_KEY = functions.config().moyasar.secret_key;

// 1. Secure Wallet Top-Up
exports.topUpWallet = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required.");
  }

  const uid = context.auth.uid;
  const paymentId = data.paymentId;
  const amount = data.amount;

  if (!paymentId || !amount) {
    throw new functions.https.HttpsError("invalid-argument", "Missing details.");
  }

  try {
    // Verify with Moyasar
    const verification = await axios.get(
      `https://api.moyasar.com/v1/payments/${paymentId}`,
      { auth: { username: MOYASAR_SECRET_KEY, password: "" } }
    );

    const paymentData = verification.data;

    if (paymentData.status !== "paid") {
      throw new functions.https.HttpsError("aborted", "Payment not paid.");
    }

    const paidAmount = paymentData.amount / 100.0; // Convert Hallalas to SAR

    // Allow small float difference
    if (Math.abs(paidAmount - amount) > 0.1) {
      throw new functions.https.HttpsError("fraud", "Amount mismatch.");
    }

    // Atomic Transaction to Update Balance
    await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(uid);
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) { throw new functions.https.HttpsError("not-found", "User not found."); }

      const currentBalance = userDoc.data().balance || 0.0;
      const newBalance = currentBalance + paidAmount;

      transaction.update(userRef, { balance: newBalance });

      const transactionRef = db.collection("analytics").doc("revenue").collection("transactions").doc();
      transaction.set(transactionRef, {
        userId: uid,
        type: "deposit",
        amount: paidAmount,
        paymentId: paymentId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        source: "apple_pay"
      });
    });

    return { success: true, newBalance: amount };

  } catch (error) {
    console.error("Payment Verification Failed:", error);
    throw new functions.https.HttpsError("internal", "Verification failed.");
  }
});

// 2. Auto-Create Profile
exports.createUserProfile = functions.auth.user().onCreate((user) => {
  return db.collection("users").doc(user.uid).set({
    name: "مشترك كشتات",
    phoneNumber: user.phoneNumber || "",
    balance: 0.0,
    joinDate: admin.firestore.FieldValue.serverTimestamp(),
    favoriteSpotIds: [],
    favoriteGearIds: []
  });
});

// 3. Send Reply Notification
exports.sendReplyNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Auth required.");
  }

  const recipientUserId = data.recipientUserId;
  const senderName = data.senderName;
  const messageText = data.messageText;
  const roomName = data.roomName || "دردشة مجموعة";

  if (!recipientUserId || !senderName || !messageText) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
  }

  try {
    // Get recipient's FCM token
    const userDoc = await db.collection("users").doc(recipientUserId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Recipient user not found.");
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token found for user ${recipientUserId}`);
      return { success: false, reason: "no_token" };
    }

    // Prepare notification payload
    const message = {
      token: fcmToken,
      notification: {
        title: `رد من ${senderName}`,
        body: messageText.length > 100 ? messageText.substring(0, 100) + "..." : messageText,
      },
      data: {
        type: "reply",
        senderName: senderName,
        messageText: messageText,
        roomName: roomName,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            alert: {
              title: `رد من ${senderName}`,
              body: messageText.length > 100 ? messageText.substring(0, 100) + "..." : messageText,
            },
          },
        },
      },
    };

    // Send notification using Firebase Admin SDK
    const response = await admin.messaging().send(message);
    console.log("Successfully sent reply notification:", response);

    return { success: true, messageId: response };

  } catch (error) {
    console.error("Error sending reply notification:", error);
    throw new functions.https.HttpsError("internal", "Failed to send notification.");
  }
});