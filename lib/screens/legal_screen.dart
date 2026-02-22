import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const _privacyPolicyUrl =
      'https://buba-oss.github.io/btc_roundup/privacy.html';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLegal)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacy),
            subtitle: Text(l10n.settingsPrivacySubtitle),
            onTap: () async {
              final uri = Uri.parse(_privacyPolicyUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(l10n.settingsDeleteAccount),
            subtitle: Text(l10n.settingsDeleteAccountSubtitle),
            onTap: user == null
                ? null
                : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l10n.deleteAccountTitle),
                  content: Text(l10n.deleteAccountWarning),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: Text(l10n.deleteAccountCancel),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: Text(
                        l10n.deleteAccountConfirm,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .delete();

                await user.delete();

                if (context.mounted) {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}