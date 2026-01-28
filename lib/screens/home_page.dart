import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
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

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        totalSavedSats = doc['totalSavedSats'] ?? 0;
        roundUpEnabled = doc['roundUpEnabled'] ?? true;
      });
    }
  }

  double _roundUp(double amount) {
    return amount.ceilToDouble() - amount;
  }

  int _euroToSats(double euro) {
    const satsPerEuro = 2500; // mock rate
    return (euro * satsPerEuro).round();
  }

  Future<void> _handleRoundUp() async {
    if (!roundUpEnabled) return;

    final input = _amountController.text.trim();
    if (input.isEmpty) return;

    final amount = double.tryParse(input);
    if (amount == null || amount <= 0) return;

    setState(() => loading = true);

    final roundUpEuro = _roundUp(amount);
    final sats = _euroToSats(roundUpEuro);
    final newTotal = totalSavedSats + sats;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);

    final batch = FirebaseFirestore.instance.batch();

    // Update total
    batch.update(userRef, {'totalSavedSats': newTotal});

    // Add transaction
    batch.set(userRef.collection('transactions').doc(), {
      'spendAmount': amount,
      'roundUpEuro': roundUpEuro,
      'sats': sats,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    setState(() {
      totalSavedSats = newTotal;
      loading = false;
      _amountController.clear();
    });
    if (roundUpEuro <= 0) {
      setState(() => loading = false);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BTC Round-Up'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SwitchListTile(
                  title: const Text('Enable Round-Up'),
                  subtitle: const Text('Automatically save spare change'),
                  value: roundUpEnabled,
                  onChanged: (value) async {
                    setState(() => roundUpEnabled = value);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .update({'roundUpEnabled': value});
                  },
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
                        const Text('Total Saved'),
                        const SizedBox(height: 8),
                        Text(
                          '$totalSavedSats sats',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: (!roundUpEnabled || loading)
                      ? null
                      : _handleRoundUp,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Round-up & Save'),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Round-Up History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          /// 🔽 STREAM + CHART + LIST
          SliverFillRemaining(
            hasScrollBody: true,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('transactions')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No round-ups yet'));
                }

                final transactions = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'roundUp': data['roundUpEuro'] ?? 0,
                    'createdAt': (data['createdAt'] as Timestamp).toDate(),
                  };
                }).toList();

                final double lifetimeEuro = transactions.fold(
                  0.0,
                      (total, tx) => total + (tx['roundUp'] as num).toDouble(),
                );


                final int lifetimeSats = totalSavedSats;



                final monthlySummaries = AnalyticsService.buildMonthlySummaries(
                  transactions,
                );

                return Column(
                  children: [
                    if (monthlySummaries.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: MonthlyBarChart(summaries: monthlySummaries),
                      ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LifetimeTotalCard(
                        euroTotal: lifetimeEuro,
                        satsTotal: lifetimeSats,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.savings),
                              title: Text('+${data['sats']} sats'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );

              },
            ),
          ),
        ],
      ),
    );
  }
}
