import 'dart:io';
import 'package:flutter/foundation.dart';

class AppGlobals {
  static String platform = "web";
  static String countryCode = "BD";

  /// Maps language codes to their corresponding country codes globally.
  /// Bangla (bn) → BD, English (en) → GB
  static const Map<String, String> languageCountryMap = {
    'bn': 'BD',
    'en': 'GB',
  };

  /// Returns the country code for the given language code.
  /// Falls back to [countryCode] if no mapping is found.
  static String countryCodeForLanguage(String languageCode) {
    return languageCountryMap[languageCode] ?? countryCode;
  }

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
      // print removed
    }
  }
}
