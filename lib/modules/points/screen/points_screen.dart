import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/colors_code.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/yellow_star_badge.dart';
import '../controller/points_bloc.dart';
import '../controller/points_event.dart';
import '../controller/points_state.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 18, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAppBar(loc: loc, title: "points"),
            SizedBox(height: 15),
            _buildAvailablePointsWithLevelButtonWidget(loc, context),
            SizedBox(height: 15),
            Text(
              loc.translate("points_history_text"),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            _buildpointsUsageHistory(loc, context),

            SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<PointsBloc, PointsState>(
                builder: (context, state) {
                  switch (state.selectedIndex) {
                    case 0:
                      return _buildEarnedWidget(context, loc);
                    case 1:
                      return _buildBenefitsWidget(context, loc);
                    case 2:
                      return _buildSpentWidget(context, loc);
                    default:
                      return SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsWidget(BuildContext context, AppLocalizations loc) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: 3,
      itemBuilder: (BuildContext context, int index) {
        return _buildBenefitsWidgetElement(context, loc);
      },
    );
  }

  Widget _buildBenefitsWidgetElement(BuildContext context, AppLocalizations loc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.notification_add, size: 26),
              SizedBox(width: 11),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate("points_history_benefits_data_title"),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  SizedBox(
                    width: 150,
                    child: Text(
                      loc.translate("points_history_benefits_data_description"),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppColors
                            .pointsScreenPointsHistoryBenefitsDescriptionData,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate(
                        "points_history_benefits_data_points_score",
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors
                            .pointsScreenPointsHistoryBenefitsPointsData,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text(
                      loc.translate("points_history_benefits_data_points_text"),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors
                            .pointsScreenPointsHistoryBenefitsPointsData,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Center _buildSpentWidget(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.notifications, size: 50),
          SizedBox(height: 4),
          Text(
            loc.translate("points_history_spent_data_title"),
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          SizedBox(
            width: 230,
            child: Text(
              loc.translate("points_history_spent_data_message_1"),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedWidget(BuildContext context, AppLocalizations loc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              YellowStarBadge(iconSize: 26),
              SizedBox(width: 9),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate("points_history_earned_data_title"),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    loc.translate("points_history_earned_data_date"),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.pointsScreenPointsHistoryEarnedDateData,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    loc.translate("points_history_earned_data_points_score"),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    loc.translate("points_history_earned_data_points_text"),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildpointsUsageHistory(AppLocalizations loc, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BlocBuilder<PointsBloc, PointsState>(
          builder: (context, state) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: Size.zero,
                side: (state.selectedIndex == 0)
                    ? BorderSide(
                        color: AppColors
                            .pointsScreenPointsHistoryButtonsColorIfSelected,
                        width: 1.5,
                      )
                    : null,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () {
                context.read<PointsBloc>().add(ChangeScreenEvent(0));
              },
              child: Text(
                loc.translate("points_history_earned_button"),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: (state.selectedIndex == 0)
                      ? AppColors
                            .pointsScreenPointsHistoryButtonsColorIfSelected
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
        BlocBuilder<PointsBloc, PointsState>(
          builder: (context, state) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: Size.zero,
                side: (state.selectedIndex == 1)
                    ? BorderSide(
                        color: AppColors
                            .pointsScreenPointsHistoryButtonsColorIfSelected,
                        width: 1.5,
                      )
                    : null,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () {
                context.read<PointsBloc>().add(ChangeScreenEvent(1));
              },
              child: Text(
                loc.translate("points_history_benefits_button"),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: (state.selectedIndex == 1)
                      ? AppColors
                            .pointsScreenPointsHistoryButtonsColorIfSelected
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
        BlocBuilder<PointsBloc, PointsState>(
          builder: (context, state) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: Size.zero,
                side: (state.selectedIndex == 2)
                    ? BorderSide(
                        color: (state.selectedIndex == 2)
                            ? AppColors
                                  .pointsScreenPointsHistoryButtonsColorIfSelected
                            : Theme.of(context).colorScheme.onSurface,
                        width: 1.5,
                      )
                    : null,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () {
                context.read<PointsBloc>().add(ChangeScreenEvent(2));
              },
              child: Text(
                loc.translate("points_history_spent_button"),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: (state.selectedIndex == 2)
                      ? AppColors
                            .pointsScreenPointsHistoryButtonsColorIfSelected
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvailablePointsWithLevelButtonWidget(
    AppLocalizations loc,
    BuildContext context,
  ) {
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
          YellowStarBadge(iconSize: 38),
          SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate("points_available_point_text"),
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    loc.translate("points_available_point_value"),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    loc.translate("points_available_pts_text"),
                    style: GoogleFonts.poppins(fontSize: 22),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.userLevel);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.badge, size: 17),
                  SizedBox(width: 5),
                  Text(
                    loc.translate("points_button_text"),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  SizedBox(width: 7),
                  Icon(Icons.arrow_forward_ios, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
