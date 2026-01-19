import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class CommunityAlertService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a community alert with approximate location
  static Future<void> sendCommunityAlert({
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Position? position;

    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      // Location optional per SRS (approximate allowed)
      position = null;
    }

    await _firestore.collection('community_alerts').add({
      'userId': user.uid, // stored but not displayed (anonymous)
      'message': message,
      'lat': position?.latitude,
      'lng': position?.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream recent community alerts
  static Stream<QuerySnapshot<Map<String, dynamic>>> alertsStream() {
    return _firestore
        .collection('community_alerts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
}
