import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCCustomerInfoInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCShipmentInfoInitializer.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';

import '../../../data/services/api_key_repository.dart';
import '../../../store/user_data_store.dart';

class SslcommerzPaymentScreen extends StatefulWidget {
  final double amount;
  final String packageName;
  final String fullName;
  final String email;
  final String phone;

  const SslcommerzPaymentScreen({
    Key? key,
    required this.amount,
    required this.packageName,
    required this.fullName,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  State<SslcommerzPaymentScreen> createState() =>
      _SslcommerzPaymentScreenState();
}

class _SslcommerzPaymentScreenState extends State<SslcommerzPaymentScreen> {
  // userAgent constants matching the server's API_KEY_TOKEN_USE enum
  static const _agentStoreId = 'SSLCOMMERZ_STORE_ID';
  static const _agentStorePassword = 'SSLCOMMERZ_STORE_PASSWORD';

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-start as soon as the first frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) => _initiatePayment());
  }

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // ── 1. Load API keys from server (cached after first call) ────────────
      final keys = await ApiKeyRepository.fetchAll();

      final storeId = keys[_agentStoreId]?.apiKey;
      final storePassword = keys[_agentStorePassword]?.apiKey;

      if (storeId == null || storeId.isEmpty ||
          storePassword == null || storePassword.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Payment configuration is unavailable. Please try again later.';
        });
        return;
      }

      // ── 2. Determine sandbox vs live from api_url returned by server ───────
      final sslApiUrl = keys[_agentStoreId]?.apiUrl ?? '';
      final isSandbox = sslApiUrl.contains('sandbox');
      final sdkType = isSandbox ? SSLCSdkType.TESTBOX : SSLCSdkType.LIVE;

      // ── 3. Launch SSLCommerz SDK ──────────────────────────────────────────
      final tranId = 'TRX_${DateTime.now().millisecondsSinceEpoch}';

      var user = UserDataStore.userData?.data?.user;
      if (user == null) {
        final currentUserModel = await UserDataStore.getUserData();
        user = currentUserModel?.data?.user;
      }

      final String rawName = widget.fullName.trim();
      final String rawEmail = widget.email.trim();
      final String rawPhone = widget.phone.trim();

      final String customerName = rawName.isNotEmpty
          ? rawName
          : ((user?.fullName != null && user!.fullName!.trim().isNotEmpty)
              ? user.fullName!.trim()
              : 'Driver User');

      final String customerEmail = (rawEmail.isNotEmpty && rawEmail.contains('@'))
          ? rawEmail
          : ((user?.email != null && user!.email!.trim().isNotEmpty && user.email!.contains('@'))
              ? user.email!.trim()
              : 'driver@trippy.com');

      String formattedPhone = rawPhone.isNotEmpty
          ? rawPhone
          : ((user?.phoneNumber != null && user!.phoneNumber!.trim().isNotEmpty)
              ? user.phoneNumber!.trim()
              : '01700000000');

      // Sanitize phone number (strip non-digits and leading country code 88 if present)
      String cleanPhone = formattedPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.startsWith('880')) {
        cleanPhone = cleanPhone.substring(2);
      }
      final String customerPhone = (cleanPhone.length >= 11) ? cleanPhone : '01700000000';


      final customerInfo = SSLCCustomerInfoInitializer(
        customerName: customerName,
        customerEmail: customerEmail,
        customerAddress1: 'Dhaka',
        customerAddress2: 'Dhaka',
        customerCity: 'Dhaka',
        customerState: 'Dhaka',
        customerPostCode: '1206',
        customerCountry: 'Bangladesh',
        customerPhone: customerPhone,
        customerFax: customerPhone,
      );

      Sslcommerz sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          store_id: storeId,
          store_passwd: storePassword,
          total_amount: widget.amount,
          currency: SSLCurrencyType.BDT,
          tran_id: tranId,
          product_category: widget.packageName.isNotEmpty ? widget.packageName : 'Subscription',
          sdkType: sdkType,
        ),
      );

      sslcommerz = sslcommerz.addCustomerInfoInitializer(
        customerInfoInitializer: customerInfo,
      );


      final SSLCTransactionInfoModel result = await sslcommerz.payNow();

      if (!mounted) return;

      // ── 4. Handle result ──────────────────────────────────────────────────
      final status = result.status?.toLowerCase() ?? '';
      if (status == 'success' || status == 'valid' || status == 'validated') {
        final returnedTranId = result.tranId ?? tranId;
        Navigator.pop(context, returnedTranId);
      } else if (status == 'failed' || status == 'cancelled') {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Payment failed. Please try again.';
        });
      } else {
        Navigator.pop(context, null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to payment gateway...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Go Back'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              // Force refresh keys on retry (in case they changed)
                              onPressed: () async {
                                await ApiKeyRepository.fetchAll(
                                    forceRefresh: true);
                                _initiatePayment();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
