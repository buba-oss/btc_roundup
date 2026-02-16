import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BtcPriceService {
  static const String _krakenApiUrl = 'https://api.kraken.com/0/public/Ticker?pair=XBTEUR';

  static Future<double> getBtcEurPrice() async {
    try {
      final response = await http.get(Uri.parse(_krakenApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result']['XXBTZEUR'];
        final lastPrice = double.parse(result['c'][0]);
        return lastPrice;
      } else {
        throw Exception('Failed to fetch price: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Price fetch error: $e');
      return 50000.0;
    }
  }

  // FIX: Make this async and await the price
  static Future<int> euroToSats(double euro) async {
    final price = await getBtcEurPrice();
    final btc = euro / price;
    final sats = (btc * 100000000).round();
    return sats;
  }
}