import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/utils/localization/app_localization.dart';

class TimelineTileWithDivider extends StatelessWidget {
  final Widget pickupIcon;
  final Widget dropOffIcon;

  final String pickupTitle;
  final String pickupLocation;

  final String dropOffTitle;
  final String dropOffLocation;

  const TimelineTileWithDivider({
    super.key,
    required this.pickupIcon,
    required this.dropOffIcon,
    required this.pickupTitle,
    required this.pickupLocation,
    required this.dropOffTitle,
    required this.dropOffLocation,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDE
        Column(
          children: [
            SizedBox(height: 8,),
            pickupIcon,

            Column(
              children: List.generate(
                10,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(
                    width: 2,
                    height: 4,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                ),
              ),
            ),

            dropOffIcon,
          ],
        ),

        const SizedBox(width: 14),

        // RIGHT SIDE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PICKUP
              Text(
                loc.translate(pickupTitle),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                loc.translate(pickupLocation),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Divider(
                thickness: 1,
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),

              const SizedBox(height: 16),

              // DROP OFF
              Text(
                loc.translate(dropOffTitle),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                loc.translate(dropOffLocation),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}