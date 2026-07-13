import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../store/user_data_store.dart';
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
        // print removed
      } catch (e) {
        // print removed
      }
      
      // Let the beautiful Trippy animation play for 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      
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
