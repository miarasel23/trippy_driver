import 'package:flutter/material.dart';
import '../../modules/subscription/screen/sslcommerz_payment_screen.dart';
import '../../store/user_data_store.dart';

class SslcommerzHelper {
  static Future<String?> initiatePayment({
    required BuildContext context,
    required double amount,
    required String packageName,
    String? fullName,
    String? email,
    String? phone,
  }) async {
    var user = UserDataStore.userData?.data?.user;
    if (user == null) {
      final currentUserModel = await UserDataStore.getUserData();
      user = currentUserModel?.data?.user;
    }

    final finalFullName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (user?.fullName?.trim().isNotEmpty == true
            ? user!.fullName!.trim()
            : 'Driver User');

    final finalPhone = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim()
        : (user?.phoneNumber?.trim().isNotEmpty == true
            ? user!.phoneNumber!.trim()
            : '01700000000');

    final finalEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : (user?.email?.trim().isNotEmpty == true
            ? user!.email!.trim()
            : 'driver@trippy.com');

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => SslcommerzPaymentScreen(
          amount: amount,
          packageName: packageName,
          fullName: finalFullName,
          email: finalEmail,
          phone: finalPhone,
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
