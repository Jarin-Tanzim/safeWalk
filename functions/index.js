const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendSosPush = functions
  .region("asia-south1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { sosId, contactUids, mapLink } = data;

    if (!Array.isArray(contactUids) || contactUids.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "contactUids is required"
      );
    }

    // Get sender info
    const senderUid = context.auth.uid;
    const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
    const senderName = senderDoc.exists ? (senderDoc.data().name || "SafeWalk User") : "SafeWalk User";

    // Fetch FCM tokens for contacts
    const tokens = [];
    const tokenUsers = [];

    for (const uid of contactUids) {
      const doc = await admin.firestore().collection("users").doc(uid).get();
      if (doc.exists) {
        const t = doc.data().fcmToken;
        if (t) {
          tokens.push(t);
          tokenUsers.push(uid);
        }
      }
    }

    if (tokens.length === 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No FCM tokens found for trusted contacts"
      );
    }

    // Send push notification
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "🚨 SOS Alert",
        body: `${senderName} needs help. Tap to view location.`,
      },
      data: {
        type: "SOS",
        sosId: sosId ? String(sosId) : "",
        mapLink: mapLink ? String(mapLink) : "",
        senderUid: String(senderUid),
      },
      android: {
        priority: "high",
      },
    });

    // Log result
    await admin.firestore().collection("sos_push_logs").add({
      sosId: sosId || null,
      senderUid,
      contactUids: contactUids,
      tokenUsers,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses.map((r, i) => ({
        tokenUser: tokenUsers[i] || null,
        success: r.success,
        error: r.error ? r.error.message : null,
      })),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  });
