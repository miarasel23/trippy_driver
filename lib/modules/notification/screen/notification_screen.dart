import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/colors_code.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("notification_appbar_title"),
          style: GoogleFonts.poppins(fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17.0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.clear_all, size: 13),
                  SizedBox(width: 3),
                  Text(
                    loc.translate("notification_clear_all"),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 50),
            SizedBox(height: 4),
            Text(
              loc.translate("notification_empty_warning"),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            Text(
              loc.translate("notification_saying_no_notification"),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              loc.translate("notification_come_back_message"),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
