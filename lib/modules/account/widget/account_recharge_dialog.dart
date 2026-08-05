import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../main.dart';
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _amountFocusNode = FocusNode();
  final List<int> _predefinedAmounts = [100, 300, 500, 700, 900, 1000, 1500, 2000, 2500, 3000];
  int? _selectedPredefined;
  String? _errorMessage;
  bool _isEditingAmount = false;

  @override
  void initState() {
    super.initState();
    // Default selection
    _selectedPredefined = _predefinedAmounts.first;
    _amountController.text = _selectedPredefined.toString();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _scrollController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text;
    if (text.isNotEmpty) {
      final val = int.tryParse(text);
      if (val != null) {
        // Check if the typed value matches a predefined option
        if (_predefinedAmounts.contains(val)) {
          setState(() => _selectedPredefined = val);
        } else {
          setState(() => _selectedPredefined = null);
        }
        if (val < 10) {
          setState(() {
            _errorMessage = AppLocalizations.of(context).translate('min_recharge_msg') ?? 'Minimum recharge amount is 10';
          });
        } else {
          if (_errorMessage != null) setState(() => _errorMessage = null);
        }
      }
    } else {
      if (_errorMessage != null) setState(() => _errorMessage = null);
    }
  }

  void _selectPredefined(int amount) {
    setState(() {
      _selectedPredefined = amount;
      _amountController.text = amount.toString();
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
      _errorMessage = null;
      _isEditingAmount = false;
    });
    _amountFocusNode.unfocus();
  }

  Future<void> _processRecharge(double amount) async {
    final loc = AppLocalizations.of(context);
    Navigator.pop(context); // Close dialog
    final user = UserDataStore.userData?.data?.user;
    final navContext = globalNavigatorKey.currentContext;
    if (navContext == null) return;

    final result = await Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (context) => SslcommerzPaymentScreen(
          amount: amount,
          packageName: 'Account Recharge',
          fullName: user?.fullName ?? '',
          email: user?.email ?? '',
          phone: user?.phoneNumber ?? '',
        ),
      ),
    );
    if (result != null && result is String) {
      final loadingCtx = globalNavigatorKey.currentContext;
      if (loadingCtx == null) return;

      showDialog(
        context: loadingCtx,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final success = await SubscriptionRepository().rechargeDriverAccount(result);
      // Close loading dialog
      if (globalNavigatorKey.currentState?.canPop() == true) {
        globalNavigatorKey.currentState!.pop();
      }

      if (success) {
        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(loc.translate('payment_successful') ?? 'Payment successful & account recharged!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh account data
        final accountCtx = globalNavigatorKey.currentContext;
        if (accountCtx != null && accountCtx.mounted) {
          try {
            accountCtx.read<AccountBloc>().add(FetchAccountHistory());
          } catch (_) {}
        }
      } else {
        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(loc.translate('payment_failed') ?? 'Payment failed on server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final surfaceColor = theme.colorScheme.surface;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded, color: onSurfaceColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('recharge_account') ?? 'Recharge Account',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.translate('recharge_amount_msg') ?? 'Select the amount to recharge.',
                        style: TextStyle(fontSize: 13, color: onSurfaceColor.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Selected Amount Display (inline editable) ─────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _isEditingAmount
                    ? onSurfaceColor.withOpacity(0.02)
                    : onSurfaceColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isEditingAmount ? onSurfaceColor : onSurfaceColor.withOpacity(0.15),
                  width: _isEditingAmount ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceColor.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Inline: show TextField when editing, else show Text
                        _isEditingAmount
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.currency} ',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: onSurfaceColor,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      focusNode: _amountFocusNode,
                                      autofocus: true,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: onSurfaceColor,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: onSurfaceColor.withOpacity(0.3),
                                        ),
                                      ),
                                      onSubmitted: (_) {
                                        setState(() => _isEditingAmount = false);
                                        _amountFocusNode.unfocus();
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '${widget.currency} ${_amountController.text.isEmpty ? '0' : _amountController.text}',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: onSurfaceColor,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Edit / Done icon
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingAmount = !_isEditingAmount;
                        if (_isEditingAmount) {
                          _selectedPredefined = null;
                          // Place cursor at end
                          _amountController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _amountController.text.length),
                          );
                          Future.delayed(const Duration(milliseconds: 50), () {
                            _amountFocusNode.requestFocus();
                          });
                        } else {
                          _amountFocusNode.unfocus();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isEditingAmount ? onSurfaceColor : onSurfaceColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEditingAmount ? Icons.check_rounded : Icons.edit_rounded,
                        color: _isEditingAmount ? surfaceColor : onSurfaceColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Error message display - clean, outside of input card to prevent design breaking
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),

            const SizedBox(height: 20),

            // ── Horizontal Scrollable Amount Chips ────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Select',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor.withOpacity(0.55),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _predefinedAmounts.length,
                    itemBuilder: (context, index) {
                      final amount = _predefinedAmounts[index];
                      final isSelected = _selectedPredefined == amount;
                      return GestureDetector(
                        onTap: () => _selectPredefined(amount),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? onSurfaceColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? onSurfaceColor : onSurfaceColor.withOpacity(0.15),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: onSurfaceColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            '${widget.currency} $amount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? surfaceColor : onSurfaceColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Action Buttons ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: onSurfaceColor.withOpacity(0.2)),
                      foregroundColor: onSurfaceColor.withOpacity(0.8),
                    ),
                    child: Text(
                      loc.translate('cancel') ?? 'Cancel',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = _amountController.text;
                      final val = double.tryParse(text) ?? 0;
                      if (val >= 10) {
                        _processRecharge(val);
                      } else {
                        setState(() {
                          _errorMessage = loc.translate('min_recharge_msg') ?? 'Minimum recharge amount is 10';
                          _isEditingAmount = true;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onSurfaceColor,
                      foregroundColor: surfaceColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 18, color: surfaceColor),
                        const SizedBox(width: 6),
                        Text(
                          loc.translate('recharge') ?? 'Recharge',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
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
