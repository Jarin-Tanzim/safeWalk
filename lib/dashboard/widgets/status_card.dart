import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class StatusCard extends StatelessWidget {
  final bool isTripActive;
  final Position? position;

  const StatusCard({
    super.key,
    required this.isTripActive,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Status",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusItem(
                  icon: Icons.gps_fixed,
                  label: "GPS",
                  value: position != null ? "Locked" : "Searching",
                  color: position != null
                      ? Colors.green
                      : Colors.orange,
                ),
                _StatusItem(
                  icon: Icons.timer,
                  label: "Trip",
                  value: isTripActive ? "Active" : "Idle",
                  color: isTripActive
                      ? Colors.green
                      : Colors.grey,
                ),
              ],
            ),

            if (position != null) ...[
              const SizedBox(height: 12),
              Text(
                "Lat: ${position!.latitude.toStringAsFixed(5)}",
              ),
              Text(
                "Lng: ${position!.longitude.toStringAsFixed(5)}",
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
