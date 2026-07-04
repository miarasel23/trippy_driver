import 'package:flutter/material.dart';

import '../modules/error/screen/error_screen.dart';
import '../modules/additionalService/screen/additionalService_screen.dart';
import '../modules/auth/screen/number_Input_screen.dart';
import '../modules/dashboard/screen/dashboard_screen.dart';
import '../modules/editProfile/screen/edit_profile_screen.dart';
import '../modules/helpCenter/screen/helpCenter_screen.dart';
import '../modules/mainBottomNavBar/screen/main_bottom_nav_bar_screen.dart';
import '../modules/notification/screen/notification_screen.dart';
import '../modules/offerDetails/screen/offerDetails_screen.dart';
import '../modules/otp/screen/otp_signin_screen.dart';
import '../modules/points/screen/points_screen.dart';
import '../modules/profile/screen/profile_screen.dart';
import '../modules/savedLocation/screen/savedLocation_screen.dart';
import '../modules/savedRoutes/screen/savedRoutes_screen.dart';
import '../modules/splash/screen/splash_screen.dart';
import '../modules/tripDetails/screen/trip_details_screen.dart';
import '../modules/userLevel/screen/user_level.dart';
import '../modules/voucher/screen/voucher_screen.dart';
import '../modules/dashboard/screen/bidding_screen.dart';
import '../modules/dashboard/screen/active_trip_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());

      case AppRoutes.numberInput:
        return MaterialPageRoute(settings: settings, builder: (_) => NumberInputScreen());

      case AppRoutes.otp:
        final number = settings.arguments as String? ?? "";
        return MaterialPageRoute(settings: settings, builder: (_) => OtpSignIn(number: number));

      case AppRoutes.dashboard:
        return MaterialPageRoute(settings: settings, builder: (_) => const DashboardScreen());

      case AppRoutes.editProfile:
        return MaterialPageRoute(settings: settings, builder: (_) => const EditprofileScreen());

      case AppRoutes.helpCenter:
        return MaterialPageRoute(settings: settings, builder: (_) => const HelpcenterScreen());
      case AppRoutes.bottomNav:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainBottomNavBarScreen(),
        );
      case AppRoutes.savedLoc:
        final autoOpenType = settings.arguments as String?;
        return MaterialPageRoute(settings: settings, builder: (_) => SavedlocationScreen(autoOpenLocationType: autoOpenType));
      case AppRoutes.savedRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const SavedroutesScreen());
      case AppRoutes.viewDetails:
        return MaterialPageRoute(settings: settings, builder: (_) => const OfferdetailsScreen());
      case AppRoutes.additionalService:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdditionalserviceScreen(),
        );
      case AppRoutes.tripDetails:
        return MaterialPageRoute(settings: settings, builder: (_) => const TripDetailsScreen());
      case AppRoutes.points:
        return MaterialPageRoute(settings: settings, builder: (_) => const PointsScreen());
      case AppRoutes.userLevel:
        return MaterialPageRoute(settings: settings, builder: (_) => const UserLevel());
      case AppRoutes.notification:
        return MaterialPageRoute(settings: settings, builder: (_) => const NotificationScreen());
      case AppRoutes.voucher:
        return MaterialPageRoute(settings: settings, builder: (_) => const VoucherScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProfileScreen());

      case AppRoutes.error:
        return MaterialPageRoute(settings: settings, builder: (_) => const ErrorScreen());

      case AppRoutes.biddingScreen:
        final args = settings.arguments;
        String customerUuid = "";
        String tripUuid = "";
        if (args is Map<String, dynamic>) {
          customerUuid = args['customerUuid'] as String? ?? "";
          tripUuid = args['tripUuid'] as String? ?? "";
        } else if (args is String) {
          customerUuid = args;
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BiddingScreen(
            customerUuid: customerUuid,
            tripUuid: tripUuid,
          ),
        );

      case AppRoutes.activeTrip:
        final customerUuid = settings.arguments as String? ?? "";
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ActiveTripScreen(customerUuid: customerUuid),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
