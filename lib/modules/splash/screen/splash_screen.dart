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
        debugPrint("Splash: Loaded user data successfully: ${UserDataStore.userData?.data?.user?.fullName}");
      } catch (e, stack) {
        debugPrint("Splash: Error loading user data: $e");
        debugPrint(stack.toString());
      }

      try {
        await UserDataStore.getAccessToken();
        debugPrint("Splash: Loaded access token: ${UserDataStore.accessToken}");
      } catch (e) {
        debugPrint("Splash: Error loading token: $e");
      }

      try {
        await UserDataStore.getUuid();
        debugPrint("Splash: Loaded UUID: ${UserDataStore.uuid}");
      } catch (e) {
        debugPrint("Splash: Error loading UUID: $e");
      }
      
      // Let the beautiful Trippy animation play for 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      
      if (mounted) {
        final token = UserDataStore.accessToken;
        
        // If token is missing, redirect to login
        if (token == null || token.isEmpty) {
          debugPrint("Splash: Token is null or empty, redirecting to home for demo");
          await UserDataStore.clearAllData();
          Navigator.pushReplacementNamed(context, AppRoutes.navbar);
        } else {
          debugPrint("Splash: Token found, redirecting to home");
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
