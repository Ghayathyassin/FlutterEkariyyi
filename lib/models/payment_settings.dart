import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentSettings {
  final double amount;

  final double tax;

  final double commissionPercent;

  const PaymentSettings({
    required this.amount,
    required this.tax,
    required this.commissionPercent,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    double parse(dynamic value) =>
        double.tryParse(value?.toString().trim() ?? '') ?? 0;
    return PaymentSettings(
      amount: parse(json['PaymentAmountDLRC']),
      tax: parse(json['PaymentTaxDLRC']),
      commissionPercent: parse(json['PaymentAmountCommission']),
    );
  }

  double commissionFor(double base) => base * commissionPercent / 100;

  static const String _url =
      'https://test-app.lrc.gov.lb/api/configuration/payment-settings';


  static Future<PaymentSettings> fetch() async {
    final response = await http.get(Uri.parse(_url));
    if (kDebugMode) {
      debugPrint('[payment-settings] GET $_url');
      debugPrint(
          '[payment-settings] status=${response.statusCode} body=${response.body}');
    }
    if (response.statusCode == 200) {
      return PaymentSettings.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('payment-settings HTTP ${response.statusCode}');
  }
}
