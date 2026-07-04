import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class CustomMapBodyBuilder {
  static String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  static Map<String, dynamic> build({
    required String actionWhen,
    required String languageCode,
    Map<String, dynamic>? data,
  }) {
    return {
      "platform": getPlatform(),
      "language_code": languageCode,
      "action_when": actionWhen,
      ...?data,
    };
  }
}
