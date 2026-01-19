import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentOrLastKnown() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw "Location services are OFF";
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw "Location permission denied";
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) throw "Could not get location";
      return last;
    }
  }
}
