import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safewalk/auth/login_page.dart';

import 'widgets/status_card.dart';
import 'widgets/sos_button.dart';
import 'widgets/quick_actions.dart';
import 'package:safewalk/core/services/trip_service.dart' as trip;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userName = "";
  bool isLoading = true;

  bool isTripActive = false;
  String? activeTripId;

  Position? currentPosition;
  StreamSubscription<Position>? positionStream;

  GoogleMapController? mapController;
  final Set<Marker> markers = {};

  bool cameraMovedOnce = false;
  DateTime? _lastUiUpdate;

  StreamSubscription<DocumentSnapshot>? _userListener; // ✅ NEW

  @override
  void initState() {
    super.initState();
    fetchUserName();
    _listenToUserName(); // ✅ NEW
  }

  @override
  void dispose() {
    positionStream?.cancel();
    mapController?.dispose();
    _userListener?.cancel(); // ✅ NEW
    super.dispose();
  }

  /// ORIGINAL METHOD (UNCHANGED)
  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      userName = doc.exists ? (doc.data()?['name'] ?? "") : "";
      isLoading = false;
    });
  }

  /// 🔥 NEW: REAL-TIME USER NAME LISTENER
  void _listenToUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userListener = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final newName = data['name'] ?? "";

      if (mounted && newName != userName) {
        setState(() {
          userName = newName;
        });
      }
    });
  }

  // =====================
  // START TRIP
  // =====================
  Future<void> startTrip() async {
    await positionStream?.cancel();
    positionStream = null;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _snack("Turn on location services");
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _snack("Location permission required");
      return;
    }

    final startPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final tripId = await trip.TripService.startTrip(
      lat: startPosition.latitude,
      lng: startPosition.longitude,
    );

    setState(() {
      activeTripId = tripId;
      isTripActive = true;
      cameraMovedOnce = false;
      _lastUiUpdate = null;
    });

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((position) {
      final now = DateTime.now();
      if (_lastUiUpdate != null &&
          now.difference(_lastUiUpdate!).inMilliseconds < 900) {
        return;
      }
      _lastUiUpdate = now;

      currentPosition = position;
      final latLng = LatLng(position.latitude, position.longitude);

      markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId("user"),
            position: latLng,
          ),
        );

      if (!cameraMovedOnce && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
        cameraMovedOnce = true;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  // =====================
  // STOP TRIP
  // =====================
  Future<void> stopTrip() async {
    await positionStream?.cancel();
    positionStream = null;

    if (activeTripId != null && currentPosition != null) {
      await trip.TripService.endTrip(
        tripId: activeTripId!,
        lat: currentPosition!.latitude,
        lng: currentPosition!.longitude,
      );
    }

    setState(() {
      isTripActive = false;
      activeTripId = null;
      currentPosition = null;
      markers.clear();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SafeWalk"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await stopTrip();
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isTripActive)
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(23.8103, 90.4125),
                            zoom: 14,
                          ),
                          myLocationEnabled: true,
                          markers: markers,
                          onMapCreated: (controller) {
                            mapController = controller;
                          },
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentPosition == null
                                  ? "Starting live location tracking..."
                                  : "Live location tracking active",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $userName",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          user?.email ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        StatusCard(
                          isTripActive: isTripActive,
                          position: currentPosition,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed:
                                isTripActive ? stopTrip : startTrip,
                            icon: Icon(
                              isTripActive
                                  ? Icons.stop_circle
                                  : Icons.location_on,
                              color: Colors.white,
                            ),
                            label: Text(
                              isTripActive
                                  ? "Stop Trip"
                                  : "Start Trip",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isTripActive
                                  ? Colors.red.shade600
                                  : Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (isTripActive) const SOSButton(),

                        const SizedBox(height: 30),

                        const QuickActions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
