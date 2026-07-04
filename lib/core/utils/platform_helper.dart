import 'package:flutter/material.dart';
import '../../store/app_globals.dart';

/// A helper class to handle platform specific logic relying on the global platform state.
class PlatformHelper {
  /// Returns true if the app platform global state is set to android
  static bool get isAndroid => AppGlobals.platform.toLowerCase() == 'android';

  /// Returns true if the app platform global state is set to ios
  static bool get isIOS => AppGlobals.platform.toLowerCase() == 'ios';

  /// Returns true if the app platform global state is set to web
  static bool get isWeb => AppGlobals.platform.toLowerCase() == 'web';
}

/// A widget builder that renders different widgets based on the global platform state.
class PlatformWidgetBuilder extends StatelessWidget {
  final WidgetBuilder androidBuilder;
  final WidgetBuilder iosBuilder;
  final WidgetBuilder? defaultBuilder;

  const PlatformWidgetBuilder({
    super.key,
    required this.androidBuilder,
    required this.iosBuilder,
    this.defaultBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isAndroid) {
      return androidBuilder(context);
    } else if (PlatformHelper.isIOS) {
      return iosBuilder(context);
    } else {
      return defaultBuilder != null ? defaultBuilder!(context) : androidBuilder(context);
    }
  }
}
