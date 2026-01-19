import 'package:flutter/material.dart';
import 'package:safewalk/contacts/trusted_contacts_page.dart';
import 'package:safewalk/dashboard/settings_page.dart';
import 'package:safewalk/dashboard/trip_history_page.dart';
import 'package:safewalk/dashboard/community_alert_page.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _ActionTile(
          icon: Icons.group,
          title: "Trusted Contacts",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TrustedContactsPage(),
              ),
            );
          },
        ),
        _ActionTile(
          icon: Icons.history,
          title: "Trip History",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TripHistoryPage(),
              ),
            );
          },
        ),
        _ActionTile(
          icon: Icons.campaign,
          title: "Community Alert",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityAlertPage(),
              ),
            );
          },
        ),
        _ActionTile(
          icon: Icons.settings,
          title: "Settings",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
