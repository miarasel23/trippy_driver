import 'package:flutter/material.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/colors_code.dart';
import '../../../utils/images.dart';

class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("offers"),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 2),
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [offerBanner(loc, context), SizedBox(height: 20)],
            );
          },
        ),
      ),
    );
  }

  Widget offerBanner(AppLocalizations loc, BuildContext context) {
    return Column(
      children: [
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          width: double.infinity,
          height: 120,
          child: Image.asset(
            Images.OfferScreenBannerImg,
            fit: BoxFit.contain,
            height: 80,
          ),
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate("offer_title"),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                loc.translate("offer_desc"),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  // getIt<AppRouter>().push(ViewdetailsScreen());
                  Navigator.pushNamed(context, AppRoutes.viewDetails);
                },
                child: Text(
                  loc.translate("see_details"),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    decorationColor: AppColors.offerScreenButtonTextDecoration,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
