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
      // Attempt to load user data from local store safely
      try {
        await UserDataStore.getUserData();
        // print removed
      } catch (e, stack) {
        // print removed
        // print removed
      }

      try {
        await UserDataStore.getAccessToken();
        // print removed
      } catch (e) {
        // print removed
      }

      try {
        await UserDataStore.getUuid();
      } catch (e) {}

      // Start the 4-second animation timer
      final animationFuture = Future.delayed(const Duration(seconds: 4));

      // Fetch fresh user data from API in the background so ride status is up to date
      if (UserDataStore.accessToken != null && UserDataStore.accessToken!.isNotEmpty) {
        try {
          String platform = "web";
          if (Theme.of(context).platform == TargetPlatform.android) platform = "android";
          else if (Theme.of(context).platform == TargetPlatform.iOS) platform = "ios";
          
          final prefs = await SharedPreferences.getInstance();
          final lang = prefs.getString('active_language_code') ?? 'en';
          
          await SplashRepository().receivingUserData(
            plaform: platform, 
            languageCode: lang, 
            actionWhen: "admin_login", 
            token: UserDataStore.accessToken!
          );
        } catch (_) {}
      }
      
      await animationFuture;
      
      if (mounted) {
        final token = UserDataStore.accessToken;
        
        // If token is missing, redirect to login
        if (token == null || token.isEmpty) {
          // print removed
          await UserDataStore.clearAllData();
          Navigator.pushReplacementNamed(context, AppRoutes.navbar);
        } else {
          // print removed
          // If already logged in, automatically open home page
          Navigator.pushReplacementNamed(context, AppRoutes.navbar);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Match the animation background perfectly
      body: const SafeArea(
        child: Center(
          child: TrippyBrandAnimation(),
        ),
      ),
    );
  }
}
