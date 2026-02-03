import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/monthly_summary.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import '../widgets/lifetime_total_card.dart';
import '../widgets/montly_bar_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _amountController = TextEditingController();
  int totalSavedSats = 0;
  bool loading = false;
  bool roundUpEnabled = true;
  List<MonthlySummary> monthlySummaries = [];
  bool _monthlyDataLoaded = false;

  // Track expanded/collapsed state for each day
  final Map<DateTime, bool> _expandedDays = {};

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMonthlyData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadMonthlyData() async {
    await fetchMonthTotalsFromFirestore();
    setState(() => _monthlyDataLoaded = true);
  }

  double _roundUp(double amount) {
    // Round up to nearest 10
    final roundedUp = (amount / 10).ceil() * 10;
    final spareChange = roundedUp - amount;

    // If amount is already multiple of 10, go to next 10
    return spareChange < 0.01 ? 10.0 : spareChange;
  }

  int _euroToSats(double euro) {
    const satsPerEuro = 2500;
    return (euro * satsPerEuro).round();
  }

  Future<void> fetchMonthTotalsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('transactions')
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
            }).toList()
            // Line 108 - Change to:
            ..sort((a, b) {
              final yearCompare = b.year.compareTo(a.year);
              return yearCompare != 0
                  ? yearCompare
                  : b.month.compareTo(a.month);
            });

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching month totals: $e');
    }
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
      final sats = _euroToSats(roundUpEuro);
      final newTotal = totalSavedSats + sats;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentTotal = (userDoc.data()?['totalSavedSats'] as num?)?.toInt() ?? 0;

        transaction.update(userRef, {
          'totalSavedSats': currentTotal + sats,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        transaction.set(
          userRef.collection('transactions').doc(),
          {
            'spendAmount': amount,
            'roundUpEuro': roundUpEuro,
            'sats': sats,
            'createdAt': FieldValue.serverTimestamp(),
            'userId': user!.uid,
          },
        );
      });

      setState(() {
        totalSavedSats = newTotal;
        loading = false;
        _amountController.clear();
      });

      await _loadMonthlyData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $sats sats (€${roundUpEuro.toStringAsFixed(2)})!',
            ),
          ),
        );
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

  Future<void> _toggleRoundUp(bool value) async {
    setState(() => roundUpEnabled = value);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'roundUpEnabled': value});
    } catch (e) {
      setState(() => roundUpEnabled = !value);
      debugPrint('Error updating roundUp setting: $e');
    }
  }

  void _toggleDayExpansion(DateTime day) {
    setState(() {
      _expandedDays[day] = !(_expandedDays[day] ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BTC Round-Up'),
        actions: [
          // Expand/Collapse all button
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: 'Collapse All',
            onPressed: () {
              setState(() {
                for (final key in _expandedDays.keys) {
                  _expandedDays[key] = false;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more),
            tooltip: 'Expand All',
            onPressed: () {
              setState(() {
                for (final key in _expandedDays.keys) {
                  _expandedDays[key] = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
          await _loadMonthlyData();
        },
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SwitchListTile(
                    title: const Text('Enable Round-Up'),
                    subtitle: const Text('Automatically save spare change'),
                    value: roundUpEnabled,
                    onChanged: _toggleRoundUp,
                  ),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Total Saved',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.formatSats(totalSavedSats),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Add near the TextField
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _amountController,
                    builder: (context, value, child) {
                      final amount = double.tryParse(value.text) ?? 0;
                      if (amount <= 0) return const SizedBox.shrink();

                      final spareChange = _roundUp(amount);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Will save: €${spareChange.toStringAsFixed(2)} → ${_euroToSats(spareChange)} sats',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Enter spend amount (€)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (!roundUpEnabled || loading)
                          ? null
                          : _handleRoundUp,
                      icon: loading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.savings),
                      label: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Round-up & Save'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // Monthly Bar Chart
            if (_monthlyDataLoaded && monthlySummaries.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Savings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: monthlySummaries.length >= 2
                            ? MonthlyBarChart(
                                summaries: monthlySummaries,
                                onMonthSelected: (year, month) {
                                  debugPrint('Selected: $month/$year');
                                },
                              )
                            : const Center(
                                child: Text(
                                  'Need more data for chart',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            // Transaction History Header
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Round-Up History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to collapse',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Transaction List with Collapsible Sections
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('transactions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                // Group by day
                final Map<DateTime, List<QueryDocumentSnapshot>> groupedByDay =
                    {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['createdAt'] as Timestamp).toDate();
                  final dayKey = DateTime(date.year, date.month, date.day);
                  groupedByDay.putIfAbsent(dayKey, () => []).add(doc);
                }

                final sortedDays = groupedByDay.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // Initialize all days as expanded by default
                for (final day in sortedDays) {
                  if (!_expandedDays.containsKey(day)) {
                    _expandedDays[day] = true;
                  }
                }

                // Calculate lifetime totals
                final double lifetimeEuroTotal = docs.fold(0.0, (total, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return total +
                      ((data['roundUpEuro'] as num?) ?? 0).toDouble();
                });

                final int lifetimeSatsTotal = docs.fold(
                  0,
                  (total, doc) => total + ((doc['sats'] as num?)?.toInt() ?? 0),
                );

                // Build list items
                final List<Widget> listItems = [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: LifetimeTotalCard(
                      euroTotal: lifetimeEuroTotal,
                      satsTotal: lifetimeSatsTotal,
                    ),
                  ),
                ];

                // Collapsible day sections
                for (final day in sortedDays) {
                  final dayDocs = groupedByDay[day]!;
                  final isExpanded = _expandedDays[day] ?? true;

                  // Calculate daily totals
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

                  // Collapsible day header
                  listItems.add(
                    InkWell(
                      onTap: () => _toggleDayExpansion(day),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExpanded
                                ? Colors.orange.shade200
                                : Colors.grey.shade300,
                            width: isExpanded ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Expand/collapse icon
                                AnimatedRotation(
                                  turns: isExpanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: isExpanded
                                        ? Colors.orange
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.yMMMMd().format(day),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isExpanded
                                            ? Colors.orange.shade800
                                            : Colors.black87,
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
                      ),
                    ),
                  );

                  // Animated transaction list
                  listItems.add(
                    AnimatedCrossFade(
                      firstChild: Column(
                        children: dayDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final date = (data['createdAt'] as Timestamp)
                              .toDate();
                          return Card(
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
                                  'Spent: €${((data['spendAmount'] as num?) ?? 0).toStringAsFixed(2)} → Saved: €${((data['roundUpEuro'] as num?) ?? 0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
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
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade400,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      secondChild: const SizedBox.shrink(),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
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
