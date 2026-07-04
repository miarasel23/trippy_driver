import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/colors_code.dart';

class HelpcenterScreen extends StatelessWidget {
  const HelpcenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("help_center"),
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.call,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 70,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.translate("how_can_we_help"),
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                helpCenterCommonTasks(
                  context: context,
                  operation: loc.translate('chat_support'),
                  icon: Icon(
                    Icons.chat_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 30,
                  ),
                ),
                helpCenterCommonTasks(
                  context: context,
                  operation: loc.translate('customer_care'),
                  icon: Icon(
                    Icons.chat_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 30,
                  ),
                ),
                helpCenterCommonTasks(
                  context: context,
                  operation: 'support@garibook.com',
                  icon: Icon(
                    Icons.mail,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 30,
                  ),
                ),
                helpCenterCommonTasks(
                  context: context,
                  operation: loc.translate('emergency_service'),
                  icon: Icon(
                    Icons.emergency,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Column helpCenterCommonTasks({
    required BuildContext context,
    required String operation,
    required Widget icon,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            print("clicked");
          },
          child: Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon,
                    SizedBox(width: 5),
                    Text(
                      operation,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}
