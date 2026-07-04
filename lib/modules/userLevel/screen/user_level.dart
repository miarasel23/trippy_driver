import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/colors_code.dart';
import '../../../widgets/custom_progress_bar.dart';
import '../controller/faq_event.dart';
import '../controller/user_level_bloc.dart';
import '../controller/user_level_state.dart';

class UserLevel extends StatelessWidget {
  const UserLevel({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: Text(
              loc.translate("user_level_screen_appbar_title"),
              style: GoogleFonts.poppins(fontSize: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 18, right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  _buildUserLevelInfo(context, loc),
                  SizedBox(height: 13),
                  _buildPointsOfEachLevelInfo(context, loc),
                  SizedBox(height: 13),
                  _buildCompanyBrief(context),
                  SizedBox(height: 13),
                  Text(
                    loc.translate("user_level_faq_text"),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 13),
                  BlocBuilder<UserLevelBloc, UserLevelState>(
                    builder: (context, state) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_1"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            0,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_2"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            1,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_3"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            2,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_4"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            3,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_5"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            4,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_6"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            5,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_7"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            6,
                            state.expandedFaqIndex,
                            context,
                          ),
                          SizedBox(height: 8),
                          _buildFaqQuestion(
                            loc.translate("user_level_screen_faq_8"),
                            loc.translate("user_level_screen_faq_answer_1"),
                            7,
                            state.expandedFaqIndex,
                            context,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqQuestion(
    String title,
    String answer,
    int index,
    int expandedIndex,
    BuildContext context,
  ) {
    final isOpen = index == expandedIndex;
    return GestureDetector(
      onTap: () {
        context.read<UserLevelBloc>().add(ToggleFaqEvent(index));
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.arrow_downward,
                  size: 18,
                ),
              ],
            ),
            SizedBox(height: 8),
            if (isOpen) Text(answer, style: GoogleFonts.poppins(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyBrief(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(
          width: 1,
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore.",
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPointsOfEachLevelInfo(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLevelPointsInfo(
          context,
          Icon(Icons.circle_notifications, size: 43),
          loc.translate("user_level_bronze_text"),
          loc.translate("user_level_bronze_points"),
          AppColors.userLevelScreenLevelPointsInfo,
        ),
        _buildLevelPointsInfo(
          context,
          Icon(Icons.sign_language, size: 43),
          loc.translate("user_level_silver_text"),
          loc.translate("user_level_silver_points"),
          AppColors.userLevelScreenLevelPointsInfo,
        ),
        _buildLevelPointsInfo(
          context,
          Icon(Icons.sign_language, size: 43),
          loc.translate("user_level_gold_text"),
          loc.translate("user_level_gold_points"),
          AppColors.userLevelScreenLevelPointsInfo,
        ),
        _buildLevelPointsInfo(
          context,
          Icon(Icons.sign_language, size: 43),
          loc.translate("user_level_platinum_text"),
          loc.translate("user_level_platinum_points"),
          AppColors.userLevelScreenLevelPointsInfo,
        ),
      ],
    );
  }

  Widget _buildLevelPointsInfo(
    BuildContext context,
    Widget icon,
    String levelName,
    String points,
    Color backgroundColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: icon,
        ),
        SizedBox(height: 3),
        Text(
          levelName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        Text(
          points,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildUserLevelInfo(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate("user_level_user_dedicating_text"),
                    style: GoogleFonts.poppins(fontSize: 13, height: 1),
                  ),
                  SizedBox(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        loc.translate("user_level_bronze_text"),
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          color: AppColors.userLevelScreenPointsInfoLevelColor,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        loc.translate("user_level_user_text"),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.circle_notifications, size: 42),
            ],
          ),
          SizedBox(height: 9),
          CustomProgressBar(),
          SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              loc.translate("user_level_user_score"),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
