
import 'package:cloud_firestore/cloud_firestore.dart';

class RoundUpEntry {
  final double amount;
  final DateTime date;

  RoundUpEntry({required this.amount, required this.date});

  // Converts Firestore doc to RoundUpEntry
  factory RoundUpEntry.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoundUpEntry(
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

