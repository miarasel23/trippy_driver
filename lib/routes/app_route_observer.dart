import 'package:flutter/material.dart';
import '../store/user_data_store.dart';
import 'app_routes.dart';

class AppRouteObserver extends NavigatorObserver {
  void _saveRoute(Route<dynamic>? route) {
    if (route != null && route.settings.name != null) {
      final String routeName = route.settings.name!;
      
      // We don't want to save the splash screen or error screens as the last route.
      // And we might only want to save specific root-level routes, but the user requested:
      // "any exiting route when user open apps apps should be open same route"
      if (routeName != AppRoutes.splash) {
        UserDataStore.saveLastRoute(routeName);
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _saveRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // When popping a route, the active route becomes the previousRoute.
    _saveRoute(previousRoute);
  }
}
