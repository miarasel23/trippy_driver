import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../controller/account_bloc.dart';
import '../model/package_details_model.dart';
import '../../subscription/screen/subscription_packages_bottom_sheet.dart';
import '../model/transaction_model.dart';
import '../../subscription/screen/sslcommerz_payment_screen.dart';
import '../../subscription/repository/subscription_repository.dart';
import '../../../store/user_data_store.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Fetch data when screen loads if not already loaded
    final bloc = context.read<AccountBloc>();
    if (bloc.state.accountData == null && !bloc.state.isLoading) {
      bloc.add(FetchAccountHistory());
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AccountBloc>().add(LoadMoreAccountHistory());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatNumber(String numberStr, bool isBangla) {
    if (!isBangla) return numberStr;
    const e2b = {'0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'};
    return numberStr.split('').map((e) => e2b[e] ?? e).join('');
  }

  String _formatDate(String dateStr, bool isBangla) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('dd MMM yyyy, hh:mm a');
      String formatted = formatter.format(date);
      return _formatNumber(formatted, isBangla);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = loc.locale.languageCode == 'bn';
    final currency = isBangla ? '৳' : 'BDT';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('nav_account') ?? 'Account',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state.isLoading && state.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AccountBloc>().add(FetchAccountHistory()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = state.accountData;
          if (data == null) {
            return const Center(child: Text("No data available"));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AccountBloc>().add(FetchAccountHistory());
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildBalancesSection(theme, data, state, loc, isBangla, currency),
                const SizedBox(height: 16),
                if (data.activePackageDetails != null)
                  _buildPackageSection(theme, data.activePackageDetails!, loc, isBangla, currency),
                const SizedBox(height: 16),
                _buildHistorySection(theme, state, loc, isBangla, currency),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalancesSection(ThemeData theme, data, AccountState state, AppLocalizations loc, bool isBangla, String currency) {
    final currentBalance = data.currentBalance;
    final dueBalance = data.dueBalance;
    final isDueCritical = dueBalance < 0;
    final displayDueBalance = dueBalance.abs();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBalanceCard(
                theme,
                loc.translate('current_balance') ?? 'Current Balance',
                currentBalance,
                theme.colorScheme.primary,
                isBangla,
                currency,
                icon: Icons.account_balance_wallet_rounded,
                bottomWidget: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      SubscriptionPackagesBottomSheet.show(context, isBangla, currency);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(loc.translate('recharge') ?? 'Recharge', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceCard(
                theme,
                loc.translate('due_ammount') ?? 'Due Ammount',
                displayDueBalance,
                isDueCritical ? Colors.redAccent : theme.colorScheme.secondary,
                isBangla,
                currency,
                icon: Icons.money_off_rounded,
                isCritical: isDueCritical,
                bottomWidget: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: dueBalance <= -10 ? () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.redAccent, size: 40),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    loc.translate('pay_due_ammount') ?? 'Pay Due Ammount',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    loc.translate('due_amount_msg') ?? 'Please pay your outstanding due balance to continue using the services smoothly.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          loc.translate('due_ammount') ?? 'Due Ammount',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '$currency ${_formatNumber(displayDueBalance.toStringAsFixed(0), isBangla)}',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(ctx),
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
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            final user = UserDataStore.userData?.data?.user;
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SslcommerzPaymentScreen(
                                                  amount: displayDueBalance,
                                                  packageName: 'Due Payment',
                                                  fullName: user?.fullName ?? 'Driver',
                                                  email: user?.email ?? 'driver@trippy.com',
                                                  phone: user?.phoneNumber ?? '',
                                                ),
                                              ),
                                            );

                                            if (result != null && result is String) {
                                              if (!context.mounted) return;
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (c) => const Center(child: CircularProgressIndicator()),
                                              );
                                              
                                              final subUuid = data.activePackageDetails?.subscriptionUuid ?? '';
                                              final success = await SubscriptionRepository().rechargeDriverAccount(subUuid, result);
                                              
                                              if (context.mounted) Navigator.pop(context); // close loading dialog
                                              
                                              if (success) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(loc.translate('payment_successful') ?? 'Payment successful & account recharged!'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                  context.read<AccountBloc>().add(FetchAccountHistory());
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(loc.translate('payment_failed') ?? 'Payment failed on server.'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.colorScheme.primary,
                                            foregroundColor: theme.colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                          ),
                                          child: Text(loc.translate('pay_now') ?? 'Pay Now', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface,
                      foregroundColor: theme.colorScheme.surface,
                      disabledBackgroundColor: theme.colorScheme.surface,
                      disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: dueBalance <= -10 ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.2),
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(loc.translate('pay') ?? 'Pay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBalanceCard(
          theme,
          loc.translate('total_earning') ?? 'Total Earning',
          data.totalEarning,
          Colors.green,
          isBangla,
          currency,
          trailingWidget: _buildFilterDropdown(theme, state, loc),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(ThemeData theme, String title, double amount, Color iconColor, bool isBangla, String currency, {IconData? icon, bool isCritical = false, Widget? trailingWidget, Widget? bottomWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCritical ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                          color: isCritical ? Colors.redAccent : theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: isCritical ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: iconColor, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "$currency ${_formatNumber(amount.toStringAsFixed(0), isBangla)}",
                  style: TextStyle(
                    color: isCritical ? Colors.redAccent : theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (bottomWidget != null) ...[
                  const SizedBox(height: 12),
                  bottomWidget,
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: 16),
            trailingWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildPackageSection(ThemeData theme, PackageDetailsModel package, AppLocalizations loc, bool isBangla, String currency) {
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
        color: isExpired ? Colors.redAccent.withOpacity(0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isExpired ? Border.all(color: Colors.redAccent.withOpacity(0.5)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                loc.translate('subscription_details') ?? 'Subscription Details',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(loc.translate('subscription_type') ?? 'Package Type', package.carSubscriptionType, theme, highlight: true),
          const SizedBox(height: 8),
          _buildInfoRow(loc.translate('renewal_date') ?? 'Renewal Date', _formatDate(package.subscriptionRenewalDateTime, isBangla), theme),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.translate('expiry_date') ?? 'Expiry Date',
            _formatDate(package.subscriptionExpiryDateTime, isBangla),
            theme,
            valueColor: statusColor,
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              loc.translate('days_left') ?? 'Days Left',
              _formatNumber(daysLeft.toString(), isBangla),
              theme,
              valueColor: daysLeft <= 10 ? Colors.redAccent : Colors.green,
            ),
            if (daysLeft <= 5) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    SubscriptionPackagesBottomSheet.show(context, isBangla, currency);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpired ? Colors.redAccent : theme.colorScheme.onSurface,
                    foregroundColor: isExpired ? Colors.white : theme.colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    loc.translate('renew') ?? 'Renew',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme, {bool highlight = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
        ),
        Text(
          value.replaceAll('_', ' '),
          style: TextStyle(
            color: valueColor ?? (highlight ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            fontSize: 14,
            fontWeight: highlight || valueColor != null ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(ThemeData theme, AccountState state, AppLocalizations loc) {
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.filterType,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 24),
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
          items: filters.entries.map((e) {
            return DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              context.read<AccountBloc>().add(FetchAccountHistory(filterType: val));
            }
          },
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel tx, String displayDesc, bool isCredit, String amountStr, bool isBangla, String currency, ThemeData theme, AppLocalizations loc) {
    String? transId;
    final transMatch = RegExp(r'trans:\s*([A-Za-z0-9_-]+)', caseSensitive: false).firstMatch(tx.description);
    if (transMatch != null) {
      transId = transMatch.group(1);
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(loc.translate('transaction_details') ?? 'Transaction Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayDesc,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.translate('amount') ?? 'Amount', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    "${isCredit ? '+' : '-'}$currency $amountStr",
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
                  Text(loc.translate('date') ?? 'Date', style: TextStyle(color: Colors.grey[600])),
                  Text(_formatDate(tx.createdAt, isBangla)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.translate('current_balance') ?? 'Balance', style: TextStyle(color: Colors.grey[600])),
                  Text("$currency ${_formatNumber(tx.mainBalance.toStringAsFixed(0), isBangla)}"),
                ],
              ),
              if (transId != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.translate('transaction_id') ?? 'Transaction ID',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        color: theme.colorScheme.primary,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: transId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transaction ID copied!'),
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
              onPressed: () => Navigator.pop(context),
              child: Text(loc.translate('close') ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorySection(ThemeData theme, AccountState state, AppLocalizations loc, bool isBangla, String currency) {
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
                loc.translate('no_accepted_trips') ?? "No transactions found.",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
          )
        else
          ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.transactions.length + (state.isFetchingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == state.transactions.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final tx = state.transactions[index];
            final isCredit = tx.credit > 0;
            final amount = isCredit ? tx.credit : tx.debit;
            final amountStr = _formatNumber(amount.toStringAsFixed(0), isBangla);
            
            String displayDesc = tx.description.replaceAll(RegExp(r'\(Booking: [\d.]+\)\s*&\s*Service charge:\s*[\d.]+'), '& Service charge');

            return GestureDetector(
              onTap: () => _showTransactionDetails(context, tx, displayDesc, isCredit, amountStr, isBangla, currency, theme, loc),
              child: Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
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
                      color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(tx.createdAt, isBangla),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isCredit ? '+' : '-'}$currency $amountStr",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${loc.translate('current_balance') ?? 'Balance'}: ${_formatNumber(tx.mainBalance.toStringAsFixed(0), isBangla)}",
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
        ),
      ],
    );
  }
}
