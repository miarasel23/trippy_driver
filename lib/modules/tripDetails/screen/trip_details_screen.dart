import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/colors_code.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/timeline_tile_with_divider.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      body: Padding(
        padding: EdgeInsets.only(top: 20, left: 18, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildAppBar(context, loc),
            SizedBox(height: 20),
            _buildVehicleInfoAndTripType(context, loc),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              padding: EdgeInsets.only(
                left: 13,
                top: 15,
                right: 13,
                bottom: 13,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimelineTileWithDivider(
                    pickupIcon: Icon(Icons.star),
                    dropOffIcon: Icon(Icons.star),
                    pickupTitle: 'pickup',
                    pickupLocation: 'trip_detail_pickup_address',
                    dropOffTitle: 'drop_off',
                    dropOffLocation: 'trip_detail_drop_off_address',
                  ),
                  SizedBox(height: 12),
                  tripDetailsOthersInfo(
                    context,
                    Theme.of(context).colorScheme.onSurface,
                    Icon(Icons.scanner, size: 25),
                    loc.translate("trip_detail_booking_text"),
                    loc.translate("trip_detail_booking_id_value"),
                  ),
                  SizedBox(height: 12),
                  tripDetailsOthersInfo(
                    context,
                    Theme.of(context).colorScheme.onSurface,
                    Icon(Icons.wallet, size: 25),
                    loc.translate("trip_detail_fare_text"),
                    loc.translate("trip_detail_fare_amount"),
                  ),
                  SizedBox(height: 12),
                  tripDetailsOthersInfo(
                    context,
                    Theme.of(context).colorScheme.onSurface,
                    Icon(Icons.calendar_view_week_rounded, size: 25),
                    loc.translate("trip_detail_date_time_text"),
                    loc.translate("trip_detail_date_time_info"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tripDetailsOthersInfo(
    BuildContext context,
    Color value,
    Icon icon,
    String title,
    String data,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        SizedBox(width: 14),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(data, style: GoogleFonts.poppins(fontSize: 18, color: value)),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleInfoAndTripType(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.car_crash, size: 55),
          SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.translate("trip_details_car_name"),
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.people,
                        color: AppColors.tripDetailsScreenSeatInfoLogo,
                        size: 17,
                      ),
                      SizedBox(width: 5),
                      Text(
                        loc.translate("trip_details_seat_info"),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          tripTypeInfo(context, loc),
        ],
      ),
    );
  }

  Widget tripTypeInfo(BuildContext context, AppLocalizations loc) {
    return IntrinsicWidth(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
          elevation: 0,
          disabledBackgroundColor: Color(0xffeef7fe),
          disabledForegroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.arrow_upward, size: 18),
            SizedBox(width: 5),
            Text(
              loc.translate("trip_details_trip_type"),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppLocalizations loc) {
    return CustomAppBar(loc: loc, title: 'trip_details_appBar_title',);
  }
}
