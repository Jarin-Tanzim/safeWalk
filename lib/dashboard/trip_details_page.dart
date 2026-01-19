import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripDetailsPage extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TripDetailsPage({
    super.key,
    required this.tripData,
  });

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _setupMarkers() {
    final startLat = widget.tripData['startLat'];
    final startLng = widget.tripData['startLng'];
    final endLat = widget.tripData['endLat'];
    final endLng = widget.tripData['endLng'];

    if (startLat != null && startLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(startLat, startLng),
          infoWindow: const InfoWindow(title: 'Trip Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (endLat != null && endLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(endLat, endLng),
          infoWindow: const InfoWindow(title: 'Trip End'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    final latitudes = _markers.map((m) => m.position.latitude).toList();
    final longitudes = _markers.map((m) => m.position.longitude).toList();

    final southWest = LatLng(
      latitudes.reduce((a, b) => a < b ? a : b),
      longitudes.reduce((a, b) => a < b ? a : b),
    );

    final northEast = LatLng(
      latitudes.reduce((a, b) => a > b ? a : b),
      longitudes.reduce((a, b) => a > b ? a : b),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: southWest,
          northeast: northEast,
        ),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startLat = widget.tripData['startLat'];
    final startLng = widget.tripData['startLng'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: startLat == null || startLng == null
          ? const Center(
              child: Text('Location data unavailable'),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(startLat, startLng),
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMapToMarkers();
              },
            ),
    );
  }
}
