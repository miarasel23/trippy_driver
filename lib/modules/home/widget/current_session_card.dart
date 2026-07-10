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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat(
            theme,
            title: loc.translate('today_earn'),
            value: "142.50 $currency",
            icon: Icons.account_balance_wallet_rounded,
          ),
          Container(
            width: 1,
            height: 36,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          _buildCompactStat(
            theme,
            title: loc.translate('trippy_due'),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
