import 'package:flutter/material.dart';
import 'package:safewalk/core/services/sos_service.dart';

class SOSButton extends StatelessWidget {
  const SOSButton({Key? key}) : super(key: key);

  void _showSOSOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Emergency SOS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // OPTION 1: ALERT GUARDIANS
              ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.red),
                title: const Text('Alert Guardians'),
                subtitle: const Text('Send emergency notification to guardians'),
                onTap: () async {
                  Navigator.pop(context);
                  await SOSService.sendSOSNotification(context);
                },
              ),

              // OPTION 2: SHARE MAP LINK
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: const Text('Share Live Location'),
                subtitle: const Text(
                  'Share map link via WhatsApp, Facebook, etc.',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await SOSService.shareLocationLink();
                },
              ),

              // OPTION 3: SMS (COMING SOON)
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.grey),
                title: const Text('Send SMS'),
                subtitle: const Text('Coming soon (requires paid service)'),
                onTap: () {
                  Navigator.pop(context);
                  _showSMSInfo(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSMSInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SMS Feature'),
        content: const Text(
          'SMS sending requires third-party paid services (e.g., Twilio). '
          'To keep this project free and academic, this feature will be implemented later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56), // SAME HEIGHT AS STOP TRIP
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => _showSOSOptions(context),
      child: const Text(
        'SOS',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
