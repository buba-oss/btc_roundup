// lib/screens/history/history_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required User user});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Track which days are expanded
  final Set<String> _expandedDays = {};

  // Your existing transaction data structure
  final Map<String, List<Transaction>> _groupedTransactions = {
    'Today': [
      Transaction(name: 'Starbucks', sats: 1250, time: '14:30'),
      Transaction(name: 'Amazon', sats: 3400, time: '09:15'),
    ],
    'Yesterday': [
      Transaction(name: 'Uber', sats: 890, time: '18:45'),
      Transaction(name: 'Grocery Store', sats: 2100, time: '12:20'),
      Transaction(name: 'Netflix', sats: 450, time: '08:00'),
    ],
    'Feb 19': [
      Transaction(name: 'Gas Station', sats: 1800, time: '16:30'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groupedTransactions.length,
        itemBuilder: (context, index) {
          final date = _groupedTransactions.keys.elementAt(index);
          final transactions = _groupedTransactions[date]!;
          final isExpanded = _expandedDays.contains(date);

          return _DaySection(
            date: date,
            transactions: transactions,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                if (isExpanded) {
                  _expandedDays.remove(date);
                } else {
                  _expandedDays.add(date);
                }
              });
            },
          );
        },
      ),
    );
  }
}

// Your existing _DaySection widget moved here
class _DaySection extends StatelessWidget {
  final String date;
  final List<Transaction> transactions;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DaySection({
    required this.date,
    required this.transactions,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final totalSats = transactions.fold<int>(0, (sum, t) => sum + t.sats);

    return Column(
      children: [
        // Day Header (always visible)
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalSats sats',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: transactions.map((t) => _TransactionDetail(
              transaction: t,
            )).toList(),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        const Divider(height: 1),
      ],
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 16, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  transaction.time,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${transaction.sats} sats',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF7931A),
            ),
          ),
        ],
      ),
    );
  }
}

// Your existing model
class Transaction {
  final String name;
  final int sats;
  final String time;

  Transaction({
    required this.name,
    required this.sats,
    required this.time,
  });
}