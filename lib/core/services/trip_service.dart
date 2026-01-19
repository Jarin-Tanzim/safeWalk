import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Start a new trip and return the trip document ID
  static Future<String?> startTrip({
    required double lat,
    required double lng,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docRef = await _firestore.collection('trips').add({
      'userId': user.uid,
      'startTime': FieldValue.serverTimestamp(),
      'startLat': lat,
      'startLng': lng,
      'status': 'active',
    });

    return docRef.id;
  }

  /// End an existing trip
  static Future<void> endTrip({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('trips').doc(tripId).update({
      'endTime': FieldValue.serverTimestamp(),
      'endLat': lat,
      'endLng': lng,
      'status': 'completed',
    });
  }

  /// Stream trip history for the current user
  static Stream<QuerySnapshot<Map<String, dynamic>>> tripHistoryStream(
  String userId,
) {
  return _firestore
      .collection('trips')
      .where('userId', isEqualTo: userId)
      .orderBy('startTime', descending: true)
      .snapshots();
}

}
