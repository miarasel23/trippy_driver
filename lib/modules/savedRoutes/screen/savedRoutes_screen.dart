import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/colors_code.dart';
import '../../../widgets/customAdd_button.dart';
import '../../../widgets/timeline_tile.dart';

class SavedroutesScreen extends StatelessWidget {
  const SavedroutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("saved_routes"),
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TimelineTile(
                          isLast: false,
                          icon: Icon(Icons.star, size: 30, color: Theme.of(context).colorScheme.onSurface),
                          tiles: 4,
                          child: Text(
                            loc.translate("Narayanganj"),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TimelineTile(
                          isLast: true,
                          icon: Icon(Icons.star, size: 30, color: Theme.of(context).colorScheme.onSurface),
                          tiles: 4,
                          child: Text(
                            loc.translate("Narayanganj"),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Icon(
                            Icons.edit_outlined,
                            size: 30,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 7),
                        GestureDetector(
                          onTap: () {},
                          child: Icon(
                            Icons.delete_outlined,
                            size: 30,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: CustomAddButton(
                loc: loc,
                labelKey: "add_routes",
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: AppColors.savedRoutesScreenButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
