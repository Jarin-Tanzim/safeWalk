import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:safewalk/auth/login_page.dart';
import 'package:safewalk/contacts/trusted_contacts_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          return ListView(
            children: [
              // ======================
              // Account Section
              // ======================
              const ListTile(
                title: Text(
                  "Account",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              /// 🔹 EDITABLE NAME
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Name"),
                subtitle: Text(data?['name'] ?? ""),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final controller = TextEditingController(
                    text: data?['name'] ?? "",
                  );

                  final newName = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Edit Name"),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: "Your name",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                controller.text.trim(),
                              );
                            },
                            child: const Text("Save"),
                          ),
                        ],
                      );
                    },
                  );

                  if (newName != null && newName.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': newName});

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Name updated successfully"),
                        ),
                      );
                    }
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: Text(user.email ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.security),
                title: const Text("Role"),
                subtitle: Text(data?['role'] ?? "primary"),
              ),

              const Divider(),

              // ======================
              // Trusted Contacts
              // ======================
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text("Trusted Contacts"),
                subtitle:
                    const Text("Manage guardians and emergency contacts"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrustedContactsPage(),
                    ),
                  );
                },
              ),

              const Divider(),

              // ======================
              // App Info
              // ======================
              const ListTile(
                title: Text(
                  "About",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text("SafeWalk"),
                subtitle:
                    Text("Personal safety and emergency alert application"),
              ),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text("Version"),
                subtitle: Text("1.0.0"),
              ),

              const Divider(),

              // ======================
              // Logout
              // ======================
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                    (_) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
