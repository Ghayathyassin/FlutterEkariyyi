import 'package:flutter/material.dart';

class PaymentProvider with ChangeNotifier {
  double _totalAmount = 0.0;

  double get totalAmount => _totalAmount;

  void setTotalAmount(double amount) {
    _totalAmount = amount;
    notifyListeners();
  }
}
