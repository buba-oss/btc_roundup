import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class MempoolService {
  static const String _baseUrl = 'https://mempool.space/api';

  static Future<bool> verifyPayment(String address, int expectedSats) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/address/$address'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chainStats = data['chain_stats'];
        final fundedTxoSum = chainStats['funded_txo_sum'] as int;

        return fundedTxoSum >= expectedSats;
      }
      return false;
    } catch (e) {
      debugPrint('Mempool check error: $e');
      return false;
    }
  }
}