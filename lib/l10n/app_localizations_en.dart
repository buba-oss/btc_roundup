// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BTC Round-Up';

  @override
  String get totalSaved => 'Total Saved';

  @override
  String get roundUpEnabled => 'Round-Up Enabled';

  @override
  String get autoSaveSpareChange => 'Automatically save spare change';

  @override
  String get enterAmount => 'Enter amount (€)';

  @override
  String get roundUpSave => 'Round Up & Save';

  @override
  String get sendBitcoin => 'Send Bitcoin';

  @override
  String get copyAddress => 'Copy Address';

  @override
  String get copied => 'Address copied';

  @override
  String get cancel => 'Cancel';

  @override
  String get iveSent => 'I\'ve Sent';

  @override
  String get transactionCompleted => 'Transaction completed!';

  @override
  String get monthlySavings => 'Monthly Savings';

  @override
  String get history => 'History';

  @override
  String get tapToExpand => 'Tap to expand';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get failedToSave => 'Failed to save. Please try again.';

  @override
  String get collapseAll => 'Collapse All';

  @override
  String get expandAll => 'Expand All';

  @override
  String get last6Months => 'Last 6 months';

  @override
  String get needMoreData => 'Need more data';

  @override
  String get yourBtcAddress => 'Your BTC Address';

  @override
  String get generating => 'Generating...';

  @override
  String get processing => 'Processing...';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get settingsLegal => 'Legal';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsPrivacySubtitle => 'How we handle your data';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Permanently remove your account and app data';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountWarning =>
      'Your account and all associated app data will be permanently deleted.\n\nThis action cannot be undone.';

  @override
  String get deleteAccountCancel => 'Cancel';

  @override
  String get deleteAccountConfirm => 'Delete';

  @override
  String get privacyPolicyOpen => 'Open privacy policy';

  @override
  String get privacyPolicyNote =>
      'The full privacy policy opens in your browser.';
}
