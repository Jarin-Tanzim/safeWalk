import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  /// Initialize notifications and save FCM token to Firestore
  static Future<void> initAndSaveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// 🚨 CREATE SOS EVENT
  /// ✅ RETURNS sosEventId (IMPORTANT)
  static Future<String> createSOSEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await FirebaseFirestore.instance
        .collection('sos_events')
        .add({
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    return docRef.id;
  }
}
