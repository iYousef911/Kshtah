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