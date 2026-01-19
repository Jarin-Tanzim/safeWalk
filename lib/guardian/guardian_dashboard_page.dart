import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safewalk/auth/login_page.dart';

class GuardianDashboardPage extends StatelessWidget {
  const GuardianDashboardPage({Key? key}) : super(key: key);

  Future<void> _openMap(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_events')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No SOS alerts yet'),
            );
          }

          final sosEvents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sosEvents.length,
            itemBuilder: (context, index) {
              final data =
                  sosEvents[index].data() as Map<String, dynamic>;

              final DateTime? time =
                  (data['timestamp'] as Timestamp?)?.toDate();

              final double? lat =
                  data['lat'] is num ? data['lat'].toDouble() : null;
              final double? lng =
                  data['lng'] is num ? data['lng'].toDouble() : null;

              final String? mapLink = data['mapLink'];
              final String? fallbackLink =
                  (lat != null && lng != null)
                      ? 'https://www.google.com/maps?q=$lat,$lng'
                      : null;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'SOS Alert',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        time != null
                            ? 'Time: $time'
                            : 'Time unavailable',
                      ),
                      const SizedBox(height: 8),
                      if (mapLink != null || fallbackLink != null)
                        InkWell(
                          onTap: () {
                            _openMap(
                              mapLink ?? fallbackLink!,
                            );
                          },
                          child: const Text(
                            '📍 View location on Google Maps',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration:
                                  TextDecoration.underline,
                            ),
                          ),
                        )
                      else
                        const Text(
                          '📍 Location unavailable',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
