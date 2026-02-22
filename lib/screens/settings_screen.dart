import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Biometric lock'),
            value: settings.biometricEnabled,
            onChanged: settings.setBiometricEnabled,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete account'),
            subtitle: const Text('Permanently remove your account and data'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete account'),
                  content: const Text(
                    'This will permanently delete your account and all app data.\n\n'
                        'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .delete();

                await user.delete(); // deletes Firebase Auth account
              }
            },
          ),
        ],
      ),
    );
  }
}
