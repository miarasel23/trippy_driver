import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../store/user_data_store.dart';
import '../../subscription/repository/subscription_repository.dart';
import '../../subscription/screen/sslcommerz_payment_screen.dart';
import '../controller/account_bloc.dart';

class AccountRechargeDialog extends StatefulWidget {
  final String currency;
  final bool isBangla;
  final String subscriptionUuid;

  const AccountRechargeDialog({
    super.key,
    required this.currency,
    required this.isBangla,
    required this.subscriptionUuid,
  });

  @override
  State<AccountRechargeDialog> createState() => _AccountRechargeDialogState();
}

class _AccountRechargeDialogState extends State<AccountRechargeDialog> {
  final TextEditingController _amountController = TextEditingController();
  final List<int> _predefinedAmounts = [100, 200, 500, 700];
  int? _selectedPredefined;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text;
    if (text.isNotEmpty) {
      final val = int.tryParse(text);
      if (val != null) {
        if (_selectedPredefined != null && val != _selectedPredefined) {
          setState(() {
            _selectedPredefined = null;
          });
        }
        if (val < 10) {
          setState(() {
            _errorMessage = AppLocalizations.of(context).translate('min_recharge_msg') ?? 'Minimum recharge amount is 10';
          });
        } else {
          if (_errorMessage != null) {
            setState(() {
              _errorMessage = null;
            });
          }
        }
      }
    } else {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    }
  }

  void _selectPredefined(int amount) {
    setState(() {
      _selectedPredefined = amount;
      _amountController.text = amount.toString();
      _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
      _errorMessage = null;
    });
  }

  Future<void> _processRecharge(double amount) async {
    final ctx = context;
    final loc = AppLocalizations.of(ctx);
    Navigator.pop(ctx); // Close dialog

    final user = UserDataStore.userData?.data?.user;
    final result = await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (context) => SslcommerzPaymentScreen(
          amount: amount,
          packageName: 'Account Recharge',
          fullName: user?.fullName ?? 'Driver',
          email: user?.email ?? 'driver@trippy.com',
          phone: user?.phoneNumber ?? '',
        ),
      ),
    );

    if (result != null && result is String) {
      if (!ctx.mounted) return;
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      
      final success = await SubscriptionRepository().rechargeDriverAccount(result);
      
      if (ctx.mounted) Navigator.pop(ctx); // close loading dialog
      
      if (success) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(loc.translate('payment_successful') ?? 'Payment successful & account recharged!'),
              backgroundColor: Colors.green,
            ),
          );
          ctx.read<AccountBloc>().add(FetchAccountHistory());
        }
      } else {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(loc.translate('payment_failed') ?? 'Payment failed on server.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              loc.translate('recharge_account') ?? 'Recharge Account',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('recharge_amount_msg') ?? 'Select or enter the amount you want to recharge.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            
            // Predefined Amounts
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _predefinedAmounts.map((amount) {
                final isSelected = _selectedPredefined == amount;
                return ChoiceChip(
                  label: Text('${widget.currency} $amount', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface)),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  onSelected: (selected) {
                    if (selected) {
                      _selectPredefined(amount);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Custom Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: loc.translate('enter_amount') ?? 'Enter Amount',
                prefixText: '${widget.currency} ',
                errorText: _errorMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.translate('cancel') ?? 'Cancel', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final text = _amountController.text;
                      final val = double.tryParse(text) ?? 0;
                      if (val >= 10) {
                        _processRecharge(val);
                      } else {
                        setState(() {
                          _errorMessage = loc.translate('min_recharge_msg') ?? 'Minimum recharge amount is 10';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(loc.translate('recharge') ?? 'Recharge', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
