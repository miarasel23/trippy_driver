import 'package:flutter/material.dart';
import 'package:flutter_sslcommerz/model/SSLCommerzInitialization.dart';
import 'package:flutter_sslcommerz/model/SSLCurrencyType.dart';
import 'package:flutter_sslcommerz/model/SSLCSdkType.dart';
import 'package:flutter_sslcommerz/model/SSLCTransactionInfoModel.dart';
import 'package:flutter_sslcommerz/sslcommerz.dart';

import '../../../data/services/api_key_repository.dart';

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

      final sslcommerz = Sslcommerz(
        initializer: SSLCommerzInitialization(
          store_id: storeId,
          store_passwd: storePassword,
          total_amount: widget.amount,
          currency: SSLCurrencyType.BDT,
          tran_id: tranId,
          product_category: 'Subscription',
          sdkType: sdkType,
        ),
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
        // User dismissed the payment UI
        Navigator.pop(context, false);
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
          onPressed: () => Navigator.pop(context, false),
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
                              onPressed: () => Navigator.pop(context, false),
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
