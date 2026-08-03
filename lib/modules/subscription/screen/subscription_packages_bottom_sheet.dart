import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/sslcommerz_helper.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../store/user_data_store.dart';
import '../controller/subscription_bloc.dart';
import '../repository/subscription_repository.dart';
import '../model/subscription_package_model.dart';

class SubscriptionPackagesBottomSheet extends StatelessWidget {
  final bool isBangla;
  final String currency;

  const SubscriptionPackagesBottomSheet({
    Key? key,
    required this.isBangla,
    required this.currency,
  }) : super(key: key);

  static void show(BuildContext context, bool isBangla, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider(
        create: (context) => SubscriptionBloc(repository: SubscriptionRepository())
          ..add(FetchSubscriptionPackages()),
        child: SubscriptionPackagesBottomSheet(isBangla: isBangla, currency: currency),
      ),
    );
  }

  String _formatNumber(String number, bool isBangla) {
    if (!isBangla) return number;
    const englishToBanglaDigits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    String result = '';
    for (int i = 0; i < number.length; i++) {
      result += englishToBanglaDigits[number[i]] ?? number[i];
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.translate('choose_package') ?? 'Choose Package',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.errorMessage != null) {
                  return Center(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (state.packages.isEmpty) {
                  return Center(
                    child: Text(loc.translate('no_packages') ?? 'No packages available'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildPackageCard(context, state.packages[index], theme, loc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(BuildContext context, SubscriptionPackageModel package, ThemeData theme, AppLocalizations loc) {
    String title = package.subscriptionType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  loc.translate('active_status') ?? 'Active',
                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$currency ${_formatNumber(package.price.toStringAsFixed(0), isBangla)}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (package.previousPrice > package.price) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "$currency ${_formatNumber(package.previousPrice.toStringAsFixed(0), isBangla)}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "${loc.translate('valid_for') ?? 'Valid for'} ${_formatNumber(package.validateFor.toString(), isBangla)} ${loc.translate('days') ?? 'days'}",
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Fetch User Details
                final currentUser = UserDataStore.userData?.data?.user;
                final String fullName = currentUser?.fullName ?? "Driver User";
                final String email = currentUser?.email ?? "driver@example.com";
                final String phone = currentUser?.phoneNumber ?? "01700000000";
                
                // Pay Now via Helper (opens WebView payment screen)
                bool isSuccess = await SslcommerzHelper.initiatePayment(
                  context: context,
                  amount: package.price.toDouble(),
                  packageName: package.subscriptionType,
                  fullName: fullName,
                  email: email,
                  phone: phone,
                );
                
                if (!context.mounted) return;
                
                // Handle result
                if (isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Successful! 🎉'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment Failed or Cancelled.'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                loc.translate('subscribe') ?? 'Subscribe',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
