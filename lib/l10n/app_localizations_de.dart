// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'BTC Round-Up';

  @override
  String get totalSaved => 'Gespart';

  @override
  String get roundUpEnabled => 'Round-Up Aktiviert';

  @override
  String get autoSaveSpareChange => 'Wechselgeld automatisch sparen';

  @override
  String get enterAmount => 'Betrag eingeben (€)';

  @override
  String get roundUpSave => 'Aufrunden & Sparen';

  @override
  String get sendBitcoin => 'Bitcoin Senden';

  @override
  String get copyAddress => 'Adresse Kopieren';

  @override
  String get copied => 'Adresse kopiert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get iveSent => 'Ich Habe Gesendet';

  @override
  String get transactionCompleted => 'Transaktion abgeschlossen!';

  @override
  String get monthlySavings => 'Monatliches Sparen';

  @override
  String get history => 'Verlauf';

  @override
  String get tapToExpand => 'Zum Erweitern Tippen';

  @override
  String get pending => 'Ausstehend';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get noTransactions => 'Noch keine Transaktionen';

  @override
  String get failedToSave =>
      'Speichern fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get collapseAll => 'Alle Einklappen';

  @override
  String get expandAll => 'Alle Ausklappen';

  @override
  String get last6Months => 'Letzte 6 Monate';

  @override
  String get needMoreData => 'Mehr Daten benötigt';

  @override
  String get yourBtcAddress => 'Ihre BTC-Adresse';

  @override
  String get generating => 'Wird generiert...';

  @override
  String get processing => 'Wird verarbeitet...';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get settingsLegal => 'Rechtliches';

  @override
  String get settingsPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsPrivacySubtitle => 'Wie wir Ihre Daten verarbeiten';

  @override
  String get settingsDeleteAccount => 'Konto löschen';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Konto und App-Daten dauerhaft entfernen';

  @override
  String get deleteAccountTitle => 'Konto löschen';

  @override
  String get deleteAccountWarning =>
      'Ihr Konto und alle zugehörigen App-Daten werden dauerhaft gelöscht.\n\nDiese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAccountCancel => 'Abbrechen';

  @override
  String get deleteAccountConfirm => 'Konto löschen';

  @override
  String get privacyPolicyOpen => 'Datenschutzerklärung öffnen';

  @override
  String get privacyPolicyNote =>
      'Die vollständige Datenschutzerklärung wird im Browser geöffnet.';
}
