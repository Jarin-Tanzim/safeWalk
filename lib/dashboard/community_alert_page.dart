import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safewalk/core/services/community_alert_service.dart';

class CommunityAlertPage extends StatefulWidget {
  const CommunityAlertPage({super.key});

  @override
  State<CommunityAlertPage> createState() => _CommunityAlertPageState();
}

class _CommunityAlertPageState extends State<CommunityAlertPage> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  Future<void> _sendAlert() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    await CommunityAlertService.sendCommunityAlert(message: text);

    _controller.clear();
    setState(() => _sending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community alert sent')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Alerts'),
      ),
      body: Column(
        children: [
          // 🔔 ALERT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: CommunityAlertService.alertsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No community alerts yet'),
                  );
                }

                final alerts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final data = alerts[index].data();
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                        title: Text(data['message'] ?? ''),
                        subtitle: createdAt != null
                            ? Text(
                                'Reported: ${createdAt.toLocal()}',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ✍️ SEND ALERT BOX
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Report a suspicious activity or danger...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _sendAlert,
                    icon: const Icon(Icons.campaign),
                    label: Text(
                      _sending ? 'Sending...' : 'Send Alert',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
