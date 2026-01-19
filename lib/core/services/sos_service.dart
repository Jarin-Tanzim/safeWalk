import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

class SOSService {
  /// OPTION 1: CREATE SOS EVENT (WITH LOCATION)
  static Future<void> sendSOSNotification(BuildContext context) async {
    // 1️⃣ Try to get location (best effort)
    Position? position;
    try {
      position = await _getCurrentLocation();
    } catch (_) {
      position = null;
    }

    final double? lat = position?.latitude;
    final double? lng = position?.longitude;

    final String? mapLink =
        (lat != null && lng != null)
            ? 'https://www.google.com/maps?q=$lat,$lng'
            : null;

    // 2️⃣ Create SOS event (push notifications still handled here)
    final String sosEventId =
        await NotificationService.createSOSEvent();

    // 3️⃣ Attach location to SAME sos_event
    await FirebaseFirestore.instance
        .collection('sos_events')
        .doc(sosEventId)
        .set(
      {
        'lat': lat,
        'lng': lng,
        'mapLink': mapLink,
      },
      SetOptions(merge: true),
    );

    // 4️⃣ UI feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS alert triggered for guardians'),
        ),
      );
    }
  }

  /// OPTION 2: SHARE LOCATION LINK (UNCHANGED)
  static Future<void> shareLocationLink() async {
    final position = await _getCurrentLocation();

    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    await Share.share(
      '🚨 Emergency! Here is my live location:\n$googleMapsUrl',
    );
  }

  /// LOCATION HELPER (UNCHANGED)
  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
