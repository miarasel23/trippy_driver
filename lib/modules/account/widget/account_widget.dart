import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../controller/account_bloc.dart';
import '../model/package_details_model.dart';
import '../model/transaction_model.dart';
import '../../subscription/screen/subscription_packages_bottom_sheet.dart';
import '../../subscription/screen/sslcommerz_payment_screen.dart';
import '../../subscription/repository/subscription_repository.dart';
import '../../../store/user_data_store.dart';
import '../../../main.dart';

// ─── Utility functions (shared by all widgets) ─────────────────────────────

String formatAccountNumber(String numberStr, bool isBangla) {
  if (!isBangla) return numberStr;
  const e2b = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
  };
  return numberStr.split('').map((e) => e2b[e] ?? e).join('');
}

String formatAccountDate(String dateStr, bool isBangla) {
  if (dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    String formatted = formatter.format(date);
    return formatAccountNumber(formatted, isBangla);
  } catch (_) {
    return dateStr;
  }
}

// ─── AccountBalanceCard ─────────────────────────────────────────────────────

class AccountBalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color iconColor;
  final bool isBangla;
  final String currency;
  final IconData? icon;
  final bool isCritical;
  final Widget? trailingWidget;
  final Widget? bottomWidget;

  const AccountBalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.iconColor,
    required this.isBangla,
    required this.currency,
    this.icon,
    this.isCritical = false,
    this.trailingWidget,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCritical
            ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isCritical
                              ? Colors.redAccent
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight:
                              isCritical ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: iconColor, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$currency ${isCritical ? '-' : ''}${formatAccountNumber(amount.toStringAsFixed(0), isBangla)}',
                  style: TextStyle(
                    color: isCritical ? Colors.redAccent : theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (bottomWidget != null) ...[
                  const SizedBox(height: 12),
                  bottomWidget!,
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: 16),
            trailingWidget!,
          ],
        ],
      ),
    );
  }
}

// ─── PayDueAmountDialog ─────────────────────────────────────────────────────

class PayDueAmountDialog extends StatelessWidget {
  final double dueBalance;
  final double displayDueBalance;
  final bool isBangla;
  final String currency;

  const PayDueAmountDialog({
    super.key,
    required this.dueBalance,
    required this.displayDueBalance,
    required this.isBangla,
    required this.currency,
  });

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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              loc.translate('pay_due_ammount') ?? 'Pay Due Amount',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('due_amount_msg') ??
                  'Please pay your outstanding due balance to continue using the services smoothly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.translate('due_ammount') ?? 'Due Amount',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$currency ${dueBalance < 0 ? '-' : ''}${formatAccountNumber(displayDueBalance.toStringAsFixed(0), isBangla)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      loc.translate('cancel') ?? 'Cancel',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog
                      final user = UserDataStore.userData?.data?.user;
                      final navContext = globalNavigatorKey.currentContext;
                      if (navContext == null) return;

                      final result = await Navigator.push(
                        navContext,
                        MaterialPageRoute(
                          builder: (context) => SslcommerzPaymentScreen(
                            amount: displayDueBalance,
                            packageName: 'Due Payment',
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

                        final success = await SubscriptionRepository()
                            .rechargeDriverAccount(result);

                        if (globalNavigatorKey.currentState?.canPop() == true) {
                          globalNavigatorKey.currentState!.pop(); // close loading dialog
                        }

                        if (success) {
                          globalScaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.translate('payment_successful') ??
                                    'Payment successful & account recharged!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          final accountCtx = globalNavigatorKey.currentContext;
                          if (accountCtx != null) {
                            try {
                              accountCtx.read<AccountBloc>().add(FetchAccountHistory());
                            } catch (_) {}
                          }
                        } else {
                          globalScaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.translate('payment_failed') ??
                                    'Payment failed on server.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      loc.translate('pay_now') ?? 'Pay Now',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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

// ─── AccountPackageSection ──────────────────────────────────────────────────

class AccountPackageSection extends StatelessWidget {
  final PackageDetailsModel package;
  final bool isBangla;
  final String currency;

  const AccountPackageSection({
    super.key,
    required this.package,
    required this.isBangla,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    DateTime? expiryDate;
    try {
      expiryDate = DateTime.parse(package.subscriptionExpiryDateTime);
    } catch (_) {}

    Color statusColor = Colors.green;
    String statusText = loc.translate('active') ?? 'Active';
    int? daysLeft;

    if (expiryDate != null) {
      if (now.isAfter(expiryDate)) {
        statusColor = Colors.redAccent;
        statusText = loc.translate('expired') ?? 'Expired';
        daysLeft = 0;
      } else {
        daysLeft = expiryDate.difference(now).inDays;
        if (daysLeft <= 10) {
          statusColor = Colors.amber.shade700;
          statusText = loc.translate('expiring_soon') ?? 'Expiring Soon';
        }
      }
    }

    final isExpired = daysLeft != null && daysLeft <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.redAccent.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isExpired
            ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('subscription_details') ??
                    'Subscription Details',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          AccountInfoRow(
            label: loc.translate('subscription_type') ?? 'Package Type',
            value: package.carSubscriptionType,
            highlight: true,
          ),
          const SizedBox(height: 8),
          AccountInfoRow(
            label: loc.translate('renewal_date') ?? 'Renewal Date',
            value: formatAccountDate(
                package.subscriptionRenewalDateTime, isBangla),
          ),
          const SizedBox(height: 8),
          AccountInfoRow(
            label: loc.translate('expiry_date') ?? 'Expiry Date',
            value: formatAccountDate(
                package.subscriptionExpiryDateTime, isBangla),
            valueColor: statusColor,
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 8),
            AccountInfoRow(
              label: loc.translate('days_left') ?? 'Days Left',
              value: formatAccountNumber(daysLeft.toString(), isBangla),
              valueColor:
                  daysLeft <= 10 ? Colors.redAccent : Colors.green,
            ),
            if (daysLeft <= 5) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    SubscriptionPackagesBottomSheet.show(
                        context, isBangla, currency);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpired
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface,
                    foregroundColor:
                        isExpired ? Colors.white : theme.colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.translate('renew') ?? 'Renew',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── AccountEmptyPackageSection ─────────────────────────────────────────────

class AccountEmptyPackageSection extends StatelessWidget {
  const AccountEmptyPackageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.translate('subscription_details') ??
                    'Subscription Details',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loc.translate('inactive') ?? 'Inactive',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_membership_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.translate('no_active_subscription') ??
                      'No Active Subscription',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    loc.translate('no_active_subscription_msg') ??
                        'You currently have no active subscription package.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AccountInfoRow ─────────────────────────────────────────────────────────

class AccountInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? valueColor;

  const AccountInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 13),
        ),
        Text(
          value.replaceAll('_', ' '),
          style: TextStyle(
            color: valueColor ??
                (highlight
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface),
            fontSize: 14,
            fontWeight: highlight || valueColor != null
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── AccountFilterDropdown ──────────────────────────────────────────────────

class AccountFilterDropdown extends StatelessWidget {
  final AccountState state;

  const AccountFilterDropdown({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final Map<String, String> filters = {
      'today': loc.translate('today') ?? 'Today',
      'this_week': loc.translate('this_week') ?? 'This Week',
      'last_week': loc.translate('last_week') ?? 'Last Week',
      'last_month': loc.translate('last_month') ?? 'Last Month',
      'last_three_month': loc.translate('last_three_month') ?? 'Last 3 Months',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.filterType,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 24),
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          items: filters.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              context
                  .read<AccountBloc>()
                  .add(FetchAccountHistory(filterType: val));
            }
          },
        ),
      ),
    );
  }
}

// ─── AccountTransactionItem ─────────────────────────────────────────────────

class AccountTransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final bool isBangla;
  final String currency;

  const AccountTransactionItem({
    super.key,
    required this.tx,
    required this.isBangla,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    String displayDesc = tx.description.replaceAll(
        RegExp(r'\(Booking: [\d.]+\)\s*&\s*Service charge:\s*[\d.]+'),
        '& Service charge');

    final isOpeningBalance =
        displayDesc.toLowerCase().contains('opening balance');
    final isDebit = tx.debit >= 1 && !isOpeningBalance;
    final isCredit =
        (tx.credit > 0 || isOpeningBalance) && !isDebit;
    final amount = (isOpeningBalance && tx.credit == 0 && tx.debit > 0)
        ? tx.debit
        : (isCredit ? tx.credit : tx.debit);
    final amountStr =
        formatAccountNumber(amount.toStringAsFixed(0), isBangla);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => _showTransactionDetails(
            context, tx, displayDesc, isCredit, amountStr, isBangla,
            currency, theme, loc),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCredit
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isCredit ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDesc,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatAccountDate(tx.createdAt, isBangla),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${isCredit ? '+' : '-'}$amountStr',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.translate('current_balance') ?? 'Balance'}: ${formatAccountNumber(tx.mainBalance.toStringAsFixed(0), isBangla)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionModel tx,
    String displayDesc,
    bool isCredit,
    String amountStr,
    bool isBangla,
    String currency,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    String? transId;
    final transMatch = RegExp(r'trans:\s*([A-Za-z0-9_-]+)',
            caseSensitive: false)
        .firstMatch(tx.description);
    if (transMatch != null) {
      transId = transMatch.group(1);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
              loc.translate('transaction_details') ?? 'Transaction Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayDesc,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.translate('amount') ?? 'Amount',
                      style: TextStyle(color: Colors.grey[600])),
                  Text(
                    '$currency ${isCredit ? '+' : '-'}$amountStr',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.translate('date') ?? 'Date',
                      style: TextStyle(color: Colors.grey[600])),
                  Text(formatAccountDate(tx.createdAt, isBangla)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.translate('current_balance') ?? 'Balance',
                      style: TextStyle(color: Colors.grey[600])),
                  Text(
                      '$currency ${formatAccountNumber(tx.mainBalance.toStringAsFixed(0), isBangla)}'),
                ],
              ),
              if (transId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(
                      left: 12, right: 4, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('transaction_id') ??
                                  'Transaction ID',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transId,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        color: theme.colorScheme.primary,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: transId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction ID copied!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text(loc.translate('close') ?? 'Close'),
            ),
          ],
        );
      },
    );
  }
}

// ─── AccountHistorySection ──────────────────────────────────────────────────

class AccountHistorySection extends StatelessWidget {
  final AccountState state;
  final bool isBangla;
  final String currency;

  const AccountHistorySection({
    super.key,
    required this.state,
    required this.isBangla,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            loc.translate('transaction_history') ?? 'History',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (state.transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                loc.translate('no_accepted_trips') ??
                    'No transactions found.',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false, // handled per-item by RepaintBoundary
            itemCount:
                state.transactions.length + (state.isFetchingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == state.transactions.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return AccountTransactionItem(
                key: ValueKey(state.transactions[index].uuid),
                tx: state.transactions[index],
                isBangla: isBangla,
                currency: currency,
              );
            },
          ),
      ],
    );
  }
}
