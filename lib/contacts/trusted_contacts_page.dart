import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContactsPage extends StatefulWidget {
  const TrustedContactsPage({super.key});

  @override
  State<TrustedContactsPage> createState() => _TrustedContactsPageState();
}

class _TrustedContactsPageState extends State<TrustedContactsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  CollectionReference get _contactsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('trusted_contacts');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _addContact() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (name.isEmpty || email.isEmpty) {
      _snack("Please enter name and email");
      return;
    }

    // 🔍 Find SafeWalk user by email
    final q = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      _snack("No SafeWalk user found with that email");
      return;
    }

    final contactUid = q.docs.first.id;

    if (contactUid == user!.uid) {
      _snack("You cannot add yourself");
      return;
    }

    // ❌ Prevent duplicates
    final existing = await _contactsRef
        .where('contactUid', isEqualTo: contactUid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      _snack("This contact is already added");
      return;
    }

    // ✅ Add to trusted_contacts subcollection
    await _contactsRef.add({
      'name': name,
      'email': email,
      'contactUid': contactUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ IMPORTANT: Add guardian UID to parent user document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'trustedContacts': FieldValue.arrayUnion([contactUid]),
    });

    _nameController.clear();
    _emailController.clear();
    Navigator.pop(context);
    _snack("Trusted contact added");
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Trusted Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Contact Email (SafeWalk account)",
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _addContact,
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(String id, String contactUid) async {
    // Remove from subcollection
    await _contactsRef.doc(id).delete();

    // Remove from parent array
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({
      'trustedContacts': FieldValue.arrayRemove([contactUid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trusted Contacts")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _contactsRef
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No trusted contacts added yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(data['name'] ?? ""),
                  subtitle: Text(data['email'] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _deleteContact(doc.id, data['contactUid']),
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
