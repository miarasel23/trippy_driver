import 'package:flutter/material.dart';
import '../../modules/subscription/screen/sslcommerz_payment_screen.dart';

class SslcommerzHelper {
  static Future<String?> initiatePayment({
    required BuildContext context,
    required double amount,
    required String packageName,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => SslcommerzPaymentScreen(
          amount: amount,
          packageName: packageName,
          fullName: fullName,
          email: email,
          phone: phone,
        ),
      ),
    );
    if (result is String) {
      return result;
    } else if (result == true) {
      return "UNKNOWN_TRX_ID";
    }
    return null;
  }
}
