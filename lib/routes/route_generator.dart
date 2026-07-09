import 'package:flutter/material.dart';

import '../modules/auth/screen/number_Input_screen.dart';
import '../modules/editProfile/screen/edit_profile_screen.dart';
import '../modules/home/screen/home_screen.dart';
import '../modules/navbar/screen/navbar_screen.dart';
import '../modules/otp/screen/otp_signin_screen.dart';
import '../modules/profile/screen/profile_screen.dart';
import '../modules/splash/screen/splash_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());

      case AppRoutes.home:
        return MaterialPageRoute(settings: settings, builder: (_) => const NavbarScreen());

      case AppRoutes.navbar:
        return MaterialPageRoute(settings: settings, builder: (_) => const NavbarScreen());

      case AppRoutes.numberInput:
        return MaterialPageRoute(settings: settings, builder: (_) => NumberInputScreen());

      case AppRoutes.otp:
        final number = settings.arguments as String? ?? "";
        return MaterialPageRoute(settings: settings, builder: (_) => OtpSignIn(number: number));

      case AppRoutes.editProfile:
        return MaterialPageRoute(settings: settings, builder: (_) => const EditprofileScreen());

      case AppRoutes.profile:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Route not found"))),
        );
    }
  }
}
