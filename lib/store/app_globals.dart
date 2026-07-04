import 'dart:io';
import 'package:flutter/foundation.dart';

class AppGlobals {
  static String platform = "web";
  static String countryCode = "BD";

  static void init() {
    try {
      if (Platform.isAndroid) {
        platform = "android";
      } else if (Platform.isIOS) {
        platform = "ios";
      }
      
      // Get the system locale (e.g., 'en_US', 'bn_BD') and extract the country code
      String localeName = Platform.localeName;
      if (localeName.contains('_')) {
        countryCode = localeName.split('_').last;
      }
    } catch (e) {
      debugPrint('AppGlobals: $e');
    }
  }
}
