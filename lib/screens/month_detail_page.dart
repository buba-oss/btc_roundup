import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MonthDetailPage extends StatelessWidget {
  final DateTime month;

  const MonthDetailPage({
    super.key,
    required this.month, required DateTime selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final euroFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final satsFormat = NumberFormat.decimalPattern('de_DE');

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(month)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc('user-id') // TODO: replace with real uid
            .collection('transactions')
            .where(
          'createdAt',
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(DateTime(month.year, month.month, 1)),
        )
            .where(
          'createdAt',
          isLessThan:
          Timestamp.fromDate(DateTime(month.year, month.month + 1, 1)),
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No transactions for this month.'),
            );
          }

          // ✅ totals
          double totalEuro = 0;
          int totalSats = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalEuro += (data['roundUpEuro'] as num).toDouble();
            totalSats += (data['sats'] as num).toInt();
          }

          return Column(
            children: [
              // ✅ MONTHLY HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMM().format(month),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            label: 'Total €',
                            value: euroFormat.format(totalEuro),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            label: 'Total sats',
                            value:
                            '${satsFormat.format(totalSats)} sats',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ✅ TRANSACTIONS
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    final date =
                    (data['createdAt'] as Timestamp).toDate();

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.savings),
                        title: Text('+${data['sats']} sats'),
                        subtitle: Text(
                          '€${(data['spendAmount'] as num).toStringAsFixed(2)} → '
                              '€${(data['roundUpEuro'] as num).toStringAsFixed(2)}\n'
                              '${DateFormat.yMMMd().format(date)}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _statCard({required String label, required String value}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}