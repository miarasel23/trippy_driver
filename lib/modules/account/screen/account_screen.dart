import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../controller/account_bloc.dart';
import '../model/package_details_model.dart';
import '../widget/account_recharge_dialog_widget.dart';
import '../widget/account_widget.dart';

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
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  Icon(Icons.error_outline,
                      size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AccountBloc>().add(FetchAccountHistory()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = state.accountData;
          if (data == null) {
            return const Center(child: Text('No data available'));
          }

          final dueBalance = data.dueBalance;
          final displayDueBalance = dueBalance.abs();
          final isDueCritical = dueBalance < 0;

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<AccountBloc>();
              bloc.add(FetchAccountHistory(filterType: state.filterType));
              await bloc.stream.firstWhere((s) => !s.isLoading);
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              children: [
                // ── Balances Row ────────────────────────────────────────────
                Row(
                  children: [
                    // Current Balance card
                    Expanded(
                      child: AccountBalanceCard(
                        title: loc.translate('current_balance') ??
                            'Current Balance',
                        amount: data.currentBalance,
                        iconColor: theme.colorScheme.primary,
                        isBangla: isBangla,
                        currency: currency,
                        icon: Icons.account_balance_wallet_rounded,
                        bottomWidget: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => BlocProvider.value(
                                  value: context.read<AccountBloc>(),
                                  child: AccountRechargeDialog(
                                    currency: currency,
                                    isBangla: isBangla,
                                    subscriptionUuid: data
                                            .activePackageDetails
                                            ?.subscriptionUuid ??
                                        '',
                                    dueBalance: dueBalance is num
                                        ? dueBalance.toDouble().abs()
                                        : 0.0,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.onSurface,
                              foregroundColor: theme.colorScheme.surface,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.translate('recharge') ?? 'Recharge',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Due Balance card
                    Expanded(
                      child: AccountBalanceCard(
                        title:
                            loc.translate('due_ammount') ?? 'Due Amount',
                        amount: displayDueBalance,
                        iconColor: isDueCritical
                            ? Colors.redAccent
                            : theme.colorScheme.secondary,
                        isBangla: isBangla,
                        currency: currency,
                        icon: Icons.money_off_rounded,
                        isCritical: isDueCritical,
                        bottomWidget: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: dueBalance <= -10
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => PayDueAmountDialog(
                                        dueBalance: dueBalance,
                                        displayDueBalance: displayDueBalance,
                                        isBangla: isBangla,
                                        currency: currency,
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.onSurface,
                              foregroundColor: theme.colorScheme.surface,
                              disabledBackgroundColor:
                                  theme.colorScheme.surface,
                              disabledForegroundColor: theme
                                  .colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: dueBalance <= -10
                                      ? Colors.transparent
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.2),
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              loc.translate('pay') ?? 'Pay',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Total Earning card
                AccountBalanceCard(
                  title:
                      loc.translate('total_earning') ?? 'Total Earning',
                  amount: data.totalEarning,
                  iconColor: Colors.green,
                  isBangla: isBangla,
                  currency: currency,
                  trailingWidget: AccountFilterDropdown(state: state),
                ),
                const SizedBox(height: 16),
                // ── Subscription Section ────────────────────────────────────
                _resolvePackageSection(
                    data.activePackageDetails, isBangla, currency),
                const SizedBox(height: 16),
                // ── Transaction History ─────────────────────────────────────
                AccountHistorySection(
                  state: state,
                  isBangla: isBangla,
                  currency: currency,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _resolvePackageSection(
      PackageDetailsModel? pkg, bool isBangla, String currency) {
    if (pkg != null && pkg.subscriptionUuid.isNotEmpty) {
      return AccountPackageSection(
        package: pkg,
        isBangla: isBangla,
        currency: currency,
      );
    }
    return const AccountEmptyPackageSection();
  }
}
