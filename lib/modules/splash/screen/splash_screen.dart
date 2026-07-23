import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';
import '../../../store/user_data_store.dart';
import '../repository/splash_repository.dart';
import '../widget/trippy_brand_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load saved credentials from local store
      try { await UserDataStore.getUserData(); } catch (_) {}
      try { await UserDataStore.getAccessToken(); } catch (_) {}
      try { await UserDataStore.getUuid(); } catch (_) {}

      final token = UserDataStore.accessToken;
      final isLoggedIn = token != null && token.isNotEmpty;

      if (isLoggedIn) {
        // ✅ Already logged in — go to home immediately, no animation wait
        // Refresh user profile silently in the background
        _refreshUserDataInBackground(token);

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.navbar);
        }
      } else {
        // 🔐 Not logged in — show brand animation for 3 seconds, then go to login
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          await UserDataStore.clearAllData();
          Navigator.pushReplacementNamed(context, AppRoutes.numberInput);
        }
      }
    });
  }

  /// Refreshes driver profile data from the API silently in background.
  /// Does NOT block navigation — app opens immediately.
  void _refreshUserDataInBackground(String token) async {
    try {
      String platform = "web";
      if (mounted) {
        final p = Theme.of(context).platform;
        if (p == TargetPlatform.android) platform = "android";
        else if (p == TargetPlatform.iOS) platform = "ios";
      }

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('active_language_code') ?? 'en';

      await SplashRepository().receivingUserData(
        plaform: platform,
        languageCode: lang,
        actionWhen: "admin_login",
        token: token,
      );
    } catch (_) {
      // Silently ignore — app uses cached data from SharedPreferences
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: const SafeArea(
        child: Center(
          child: TrippyBrandAnimation(),
        ),
      ),
    );
  }
}
