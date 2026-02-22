import 'dart:async';
import 'dart:ui';
import 'package:btc_roundup/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/monthly_summary.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/btc_price_service.dart';
import '../utils/formatters.dart';
import '../widgets/montly_bar_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required User user,});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  final TextEditingController _amountController = TextEditingController();
  int totalSavedSats = 0;
  bool loading = false;
  bool roundUpEnabled = true;
  String? btcReceivingAddress;
  List<MonthlySummary> monthlySummaries = [];
  bool _monthlyDataLoaded = false;

  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreTransactions = true;
  bool _isLoadingMore = false;
  final List<QueryDocumentSnapshot> _allTransactions = [];

  final Map<DateTime, _DayExpansionState> _dayExpansionStates = {};
  bool _prefsLoaded = false;
  StreamSubscription? _transactionSubscription;

  User? get user => FirebaseAuth.instance.currentUser;
  static const String _expandedDaysKey = 'expanded_days_state';

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
    _loadUserData();
    _loadMonthlyData();
    _subscribeToTransactions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionSubscription?.cancel();
    for (final state in _dayExpansionStates.values) {
      state.controller.dispose();
    }
    super.dispose();
  }

  void _subscribeToTransactions() {
    _transactionSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .listen((snapshot) {
          if (mounted) setState(() {});
        });
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getString(_expandedDaysKey);

    if (savedState != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedState);
        setState(() {
          for (final entry in decoded.entries) {
            final day = DateTime.parse(entry.key);
            final isExpanded = entry.value as bool;
            _getOrCreateExpansionState(day).isExpanded = isExpanded;
          }
        });
      } catch (e) {
        debugPrint('Error loading persisted state: $e');
      }
    }
    setState(() => _prefsLoaded = true);
  }

  Future<void> _persistState() async {
    if (!_prefsLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final Map<String, bool> stateToSave = {};

    for (final entry in _dayExpansionStates.entries) {
      stateToSave[entry.key.toIso8601String()] = entry.value.isExpanded;
    }

    await prefs.setString(_expandedDaysKey, jsonEncode(stateToSave));
  }

  String _truncateAddress(
    String address, {
    int startChars = 8,
    int endChars = 6,
  }) {
    if (address.length <= startChars + endChars + 3) return address;
    return '${address.substring(0, startChars)}...${address.substring(address.length - endChars)}';
  }

  _DayExpansionState _getOrCreateExpansionState(DateTime day) {
    return _dayExpansionStates.putIfAbsent(day, () {
      return _DayExpansionState(
        controller: AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        ),
        isExpanded: true, // Default to expanded
      );
    });
  }

  void _cleanupOldExpansionStates(List<DateTime> visibleDays) {
    final visibleSet = visibleDays.toSet();
    final keysToRemove = _dayExpansionStates.keys
        .where((day) => !visibleSet.contains(day))
        .toList();

    for (final key in keysToRemove) {
      final state = _dayExpansionStates.remove(key);
      state?.controller.dispose();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          totalSavedSats = (doc['totalSavedSats'] as num?)?.toInt() ?? 0;
          roundUpEnabled = doc['roundUpEnabled'] as bool? ?? true;
          btcReceivingAddress = doc['btcAddress'] as String?;
        });

        if (btcReceivingAddress == null || btcReceivingAddress!.isEmpty) {
          await _generateNewAddress();
        }
      } else {
        await _generateNewAddress();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _generateNewAddress() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userHash = user!.uid.substring(0, 8);
    final address = 'bc1q$userHash${timestamp.toString().substring(0, 6)}';

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'btcAddress': address,
      'totalSavedSats': 0,
      'roundUpEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => btcReceivingAddress = address);
  }
  void _showSettingsDialog(BuildContext context) {
    // Get settings from the provider at the top level
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Settings'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Use Biometric Lock'),
                    subtitle: const Text('Require fingerprint/face to open app'),
                    value: settings.biometricEnabled,
                    onChanged: (value) {
                      settings.setBiometricEnabled(value);
                      setState(() {

                      }); // Rebuild dialog
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Language'),
                    trailing: Text(Localizations.localeOf(context).languageCode.toUpperCase()),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.copied)));
    }
  }

  Future<void> _loadMonthlyData() async {
    await fetchMonthTotalsFromFirestore();
    setState(() => _monthlyDataLoaded = true);
  }

  Future<void> fetchMonthTotalsFromFirestore() async {
    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('transactions')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo),
          )
          .orderBy('createdAt', descending: true)
          .get();

      Map<int, Map<int, int>> yearMonthTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final year = createdAt.year;
        final month = createdAt.month;
        final sats = (data['sats'] as num?)?.toInt() ?? 0;

        yearMonthTotals[year] ??= {};
        yearMonthTotals[year]![month] =
            (yearMonthTotals[year]![month] ?? 0) + sats;
      }

      monthlySummaries =
          yearMonthTotals.entries.expand((yearEntry) {
            return yearEntry.value.entries.map(
              (monthEntry) => MonthlySummary(
                year: yearEntry.key,
                month: monthEntry.key,
                totalSats: monthEntry.value,
                totalRoundUp: null,
                transactionCount: null,
              ),
            );
          }).toList()..sort((a, b) {
            final yearCompare = b.year.compareTo(a.year);
            return yearCompare != 0 ? yearCompare : b.month.compareTo(a.month);
          });

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching month totals: $e');
    }
  }

  double _roundUp(double amount) {
    final roundedUp = (amount / 10).ceil() * 10;
    final spareChange = roundedUp - amount;
    return spareChange < 0.01 ? 10.0 : spareChange;
  }

  String? _validateAmount(String value) {
    if (value.isEmpty) return null;
    final amount = double.tryParse(value);
    if (amount == null) return 'Please enter a valid number';
    if (amount <= 0) return 'Amount must be greater than 0';
    if (amount > 10000) return 'Maximum amount is €10,000';
    return null;
  }

  Future<void> _handleRoundUp() async {
    if (!roundUpEnabled) return;

    final input = _amountController.text.trim();
    if (input.isEmpty) return;

    final amount = double.tryParse(input);
    if (amount == null || amount <= 0) return;

    final roundUpEuro = _roundUp(amount);

    setState(() => loading = true);

    try {
      // Generate address only if it doesn't exist
      if (btcReceivingAddress == null || btcReceivingAddress!.isEmpty) {
        await _generateNewAddress();
      }

      final sats = await BtcPriceService.euroToSats(roundUpEuro);
      final newTotal = totalSavedSats + sats;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);

      // Create transaction document reference to get the ID
      final transactionRef = userRef.collection('transactions').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentTotal =
            (userDoc.data()?['totalSavedSats'] as num?)?.toInt() ?? 0;

        transaction.update(userRef, {
          'totalSavedSats': currentTotal + sats,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Use the pre-created document reference
        transaction.set(transactionRef, {
          'spendAmount': amount,
          'roundUpEuro': roundUpEuro,
          'sats': sats,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': user!.uid,
          'btcAddress': btcReceivingAddress,
          'status': 'pending',
        });
      });

      // Get the transaction ID after successful commit
      final String transactionId = transactionRef.id;

      setState(() {
        totalSavedSats = newTotal;
        loading = false;
        _amountController.clear();
      });

      await _loadMonthlyData();

      if (mounted) {
        _showPaymentDialog(sats, roundUpEuro, transactionId);
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Error in round up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  void _showPaymentDialog(int sats, double euroAmount, String transactionId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.send, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('Send Bitcoin'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send $sats sats',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '(€${euroAmount.toStringAsFixed(2)})',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // QR Code
                  if (btcReceivingAddress != null)
                    Center(
                      child: SizedBox(
                        // Add fixed size wrapper
                        width: 200,
                        height: 200,
                        child: QrImageView(
                          data:
                              'bitcoin:${btcReceivingAddress!}?amount=${sats.toString()}',
                          version: QrVersions.auto,
                          size: 180, // Keep this smaller than container
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Address
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            btcReceivingAddress != null
                                ? _truncateAddress(btcReceivingAddress!)
                                : 'Generating...',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: btcReceivingAddress != null
                              ? () => _copyToClipboard(btcReceivingAddress!)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(

                  onPressed: () async {
                    final navigator = Navigator.of(
                      context,
                    ); // Capture BEFORE await

                    await _markTransactionCompleted(transactionId);
                    if (!mounted) return;
                    // Show checkmark animation overlay
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => CheckmarkAnimation(
                        onComplete: () {
                          Navigator.of(context).pop(); // Close animation dialog
                          navigator
                              .pop(); // Close payment dialog (use captured navigator)
                          _showSuccessSnackBar();
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('I\'ve Sent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _markTransactionCompleted(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('transactions')
          .doc(transactionId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error marking transaction completed: $e');
    }
  }

  void _showSuccessSnackBar() {
    if (!mounted) return; // Add this check
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Transaction marked as completed!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleRoundUp(bool value) async {
    setState(() => roundUpEnabled = value);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'roundUpEnabled': value,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      setState(() => roundUpEnabled = !value);
      debugPrint('Error updating roundUp setting: $e');
    }
  }

  void _toggleDayExpansion(DateTime day) {
    final state = _getOrCreateExpansionState(day);

    setState(() {
      state.isExpanded = !state.isExpanded;
      if (state.isExpanded) {
        state.controller.forward();
      } else {
        state.controller.reverse();
      }
    });

    _persistState();
  }

  void _collapseAll() {
    setState(() {
      for (final state in _dayExpansionStates.values) {
        state.isExpanded = false;
        state.controller.reverse();
      }
    });
    _persistState();
  }

  void _expandAll() {
    setState(() {
      for (final state in _dayExpansionStates.values) {
        state.isExpanded = true;
        state.controller.forward();
      }
    });
    _persistState();
  }


  Future<void> _loadMoreTransactions() async {
    if (!_hasMoreTransactions || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize)
        .get();

    if (snapshot.docs.isEmpty) {
      _hasMoreTransactions = false;
    } else {
      _lastDocument = snapshot.docs.last;
      _allTransactions.addAll(snapshot.docs);
    }

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final _ = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light gray background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(
          l10n.appTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // ADD THIS SETTINGS BUTTON
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Settings',
            onPressed: () => _showSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less, color: Colors.grey),
            tooltip: l10n.collapseAll,
            onPressed: _collapseAll,
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more, color: Colors.grey),
            tooltip: l10n.expandAll,
            onPressed: _expandAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await AuthService().logout();
              // No navigation needed - AuthWrapper handles it
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _lastDocument = null;
          _hasMoreTransactions = true;
          _allTransactions.clear();
          await _loadUserData();
          await _loadMonthlyData();
        },
        child: CustomScrollView(
          slivers: [
            // Premium Total Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white.withValues(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.totalSaved,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Formatters.formatSats(totalSavedSats),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<double>(
                            future: BtcPriceService.getBtcEurPrice(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              final euroValue =
                                  (totalSavedSats / 100000000) * snapshot.data!;
                              return Text(
                                '≈ €${euroValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withValues(),
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Modern Input Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle with modern styling
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: roundUpEnabled
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          l10n.roundUpEnabled,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: roundUpEnabled
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                        subtitle: Text(
                          l10n.autoSaveSpareChange,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        value: roundUpEnabled,
                        activeThumbColor: Colors.green,
                        onChanged: _toggleRoundUp,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Modern input field
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.enterAmount,
                        labelStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.euro,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        errorText: _validateAmount(_amountController.text),
                        helperText: roundUpEnabled
                            ? 'We\'ll round up to the nearest €10'
                            : l10n.autoSaveSpareChange,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Premium action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (!roundUpEnabled || loading)
                            ? null
                            : _handleRoundUp,
                        icon: loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.savings, size: 24),
                        label: loading
                            ? const Text('Processing...')
                            : Text(
                                l10n.roundUpSave,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Monthly Chart Section
            if (_monthlyDataLoaded && monthlySummaries.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.monthlySavings,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.last6Months,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: monthlySummaries.length >= 2
                            ? MonthlyBarChart(
                                summaries: monthlySummaries,
                                onMonthSelected: (monthDate) {
                                  debugPrint('Tapped month: $monthDate');
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.needMoreData,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            // Transaction History Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.history,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.tapToExpand,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // Transaction List
            StreamBuilder<QuerySnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('transactions')
                  .orderBy('createdAt', descending: true)
                  .limit(_pageSize)
                  .snapshots()
                  : const Stream.empty(),  // Empty stream when logged out
              builder: (context, snapshot) {
                // Handle logged out state
                if (user == null) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    _allTransactions.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // ... rest of your builder code

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                final List<QueryDocumentSnapshot> displayDocs = snapshot.hasData
                    ? snapshot.data!.docs
                    : [];

                if (snapshot.hasData &&
                    _allTransactions.isEmpty &&
                    snapshot.data!.docs.isNotEmpty) {
                  _allTransactions.addAll(snapshot.data!.docs);
                  _lastDocument = snapshot.data!.docs.last;
                }

                if (displayDocs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTransactions,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final Map<DateTime, List<QueryDocumentSnapshot>> groupedByDay =
                    {};
                for (final doc in displayDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['createdAt'] as Timestamp).toDate();
                  final dayKey = DateTime(date.year, date.month, date.day);
                  groupedByDay.putIfAbsent(dayKey, () => []).add(doc);
                }

                final sortedDays = groupedByDay.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                _cleanupOldExpansionStates(sortedDays);

                for (final day in sortedDays) {
                  _getOrCreateExpansionState(day);
                }

                final double lifetimeEuroTotal = displayDocs.fold(0.0, (
                  acc,
                  doc,
                ) {
                  final data = doc.data() as Map<String, dynamic>;
                  return acc + ((data['roundUpEuro'] as num?) ?? 0).toDouble();
                });

                final int lifetimeSatsTotal = displayDocs.fold(
                  0,
                  (acc, doc) => acc + ((doc['sats'] as num?)?.toInt() ?? 0),
                );

                // Replace the LifetimeTotalCard with this premium version:
                final List<Widget> listItems = [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lifetime Total',
                              style: TextStyle(
                                color: Colors.white.withValues(),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatSats(lifetimeSatsTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${lifetimeEuroTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'saved',
                              style: TextStyle(
                                color: Colors.white.withValues(),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ];

                for (final day in sortedDays) {
                  final dayDocs = groupedByDay[day]!;
                  final expansionState = _getOrCreateExpansionState(day);
                  final isExpanded = expansionState.isExpanded;

                  final int dayTotalSats = dayDocs.fold<int>(
                    0,
                    (acc, doc) => acc + ((doc['sats'] as num?)?.toInt() ?? 0),
                  );

                  final double dayTotalEuro = dayDocs.fold<double>(
                    0.0,
                    (acc, doc) =>
                        acc + ((doc['roundUpEuro'] as num?) ?? 0).toDouble(),
                  );

                  final int transactionCount = dayDocs.length;

                  listItems.add(
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleDayExpansion(day),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedBuilder(
                          animation: expansionState.controller,
                          builder: (context, child) {
                            final progress = expansionState.controller.value;
                            final backgroundColor = Color.lerp(
                              Colors.grey.shade100,
                              Colors.orange.shade50,
                              progress,
                            )!;
                            final borderColor = Color.lerp(
                              Colors.grey.shade300,
                              Colors.orange.shade200,
                              progress,
                            )!;
                            final textColor = Color.lerp(
                              Colors.black87,
                              Colors.orange.shade800,
                              progress,
                            )!;
                            final borderWidth = 1.0 + (progress * 1.0);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: borderWidth,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(),
                                    blurRadius: 8 * progress,
                                    offset: Offset(0, 4 * progress),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      AnimatedBuilder(
                                        animation: expansionState.controller,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle:
                                                expansionState
                                                    .controller
                                                    .value *
                                                (3.14159 / 2),
                                            child: Icon(
                                              Icons.chevron_right,
                                              color: isExpanded
                                                  ? Colors.orange
                                                  : Colors.grey,
                                              size: 24,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat.yMMMMd().format(day),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.bolt,
                                            size: 16,
                                            color: Colors.orange.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+${Formatters.formatSats(dayTotalSats)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '€${dayTotalEuro.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );

                  listItems.add(
                    AnimatedBuilder(
                      animation: expansionState.controller,
                      builder: (context, child) {
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: expansionState.controller.value,
                            child: Opacity(
                              opacity: expansionState.controller.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: dayDocs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doc = entry.value;
                          final data = doc.data() as Map<String, dynamic>;
                          final date = (data['createdAt'] as Timestamp)
                              .toDate();

                          return AnimatedBuilder(
                            animation: expansionState.controller,
                            builder: (context, child) {
                              final delay = index * 0.1;
                              final itemProgress =
                                  ((expansionState.controller.value - delay) /
                                          (1 - delay))
                                      .clamp(0.0, 1.0);

                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - itemProgress)),
                                child: Opacity(
                                  opacity: itemProgress,
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.savings,
                                    color: Colors.orange.shade700,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  '+${Formatters.formatSats((data['sats'] as num?)?.toInt() ?? 0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Spent: €${((data['spendAmount'] as num?) ?? 0).toStringAsFixed(2)} '
                                    '→ Saved: €${((data['roundUpEuro'] as num?) ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                // In your dayDocs list builder, update the trailing widget:
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat.Hm().format(date),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Show checkmark for completed, pending icon otherwise
                                    data['status'] == 'completed'
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 12,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Done',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.green.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.pending,
                                                  size: 12,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Pending',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.orange.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                }

                if (_hasMoreTransactions) {
                  listItems.add(
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _isLoadingMore
                            ? null
                            : _loadMoreTransactions,
                        child: _isLoadingMore
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Load More'),
                      ),
                    ),
                  );
                }

                listItems.add(const SizedBox(height: 32));

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => listItems[index],
                    childCount: listItems.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to manage expansion state with animation controller
class _DayExpansionState {
  final AnimationController controller;
  bool isExpanded;

  _DayExpansionState({required this.controller, this.isExpanded = true});
}

class CheckmarkAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const CheckmarkAnimation({super.key, required this.onComplete});

  @override
  State<CheckmarkAnimation> createState() => _CheckmarkAnimationState();
}

class _CheckmarkAnimationState extends State<CheckmarkAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Add this widget for pending status
class PendingPulse extends StatefulWidget {
  final Widget child;
  const PendingPulse({super.key, required this.child});

  @override
  State<PendingPulse> createState() => _PendingPulseState();
}

class _PendingPulseState extends State<PendingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: widget.child,
        );
      },
    );
  }
}
