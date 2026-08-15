import 'package:flutter/material.dart';
import '../../../../core/utils/localization/app_localization.dart';

class CurrentSessionCard extends StatelessWidget {
  const CurrentSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final currency = Localizations.localeOf(context).languageCode == 'bn' ? '৳' : 'BDT';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat(
            theme,
            title: loc.translate('today_earn') ?? 'Earn',
            value: "142.50 $currency",
            icon: Icons.account_balance_wallet_rounded,
          ),
          Container(
            width: 1,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          _buildCompactStat(
            theme,
            title: loc.translate('trippy_due') ?? 'Due',
            value: "20.00 $currency",
            icon: Icons.receipt_long_rounded,
            valueColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(ThemeData theme, {required String title, required String value, required IconData icon, Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: valueColor ?? theme.colorScheme.onSurface),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
