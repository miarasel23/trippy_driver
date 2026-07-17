import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/utils/localization/app_localization_delegate.dart';
import 'core/utils/localization/app_localization.dart';
import 'modules/auth/controller/send_otp_bloc.dart';
import 'modules/auth/repository/send_otp_repository.dart';
import 'modules/editProfile/controller/edit_profile_info_bloc.dart';
import 'modules/editProfile/controller/edit_profile_picture_bloc.dart';
import 'modules/editProfile/repository/edit_profile_repository.dart';
import 'modules/localization/Controller/localization_controller.dart';

import 'modules/otp/controller/otp_receive_bloc.dart';
import 'modules/otp/repository/otp_receive_repository.dart';
import 'modules/splash/controller/splash_bloc.dart';
import 'modules/splash/repository/splash_repository.dart';
import 'modules/home/controller/home_controller.dart';
import 'modules/home/repository/home_repository.dart';
import 'modules/home/widget/accepted_trip_card.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'store/user_data_store.dart';

import 'store/app_globals.dart';
import 'core/utils/theme/app_theme.dart';
import 'modules/theme/controller/theme_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppGlobals.init();
  await initializeBackgroundService();
  
  final prefs = await SharedPreferences.getInstance();
  final initialLang = prefs.getString('active_language_code') ?? 'en';
  
  runApp(MyApp(initialLanguageCode: initialLang));
}

final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class MyRouteObserver extends NavigatorObserver {
  String? currentRoute;
  final ValueNotifier<String?> routeNotifier = ValueNotifier<String?>(null);

  void _persistRoute(String? routeName) {
    if (routeName != null && routeName != AppRoutes.splash) {
      UserDataStore.saveLastRoute(routeName);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = route.settings.name;
    routeNotifier.value = currentRoute;
    _persistRoute(currentRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = previousRoute?.settings.name;
    routeNotifier.value = currentRoute;
    _persistRoute(currentRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentRoute = newRoute?.settings.name;
    routeNotifier.value = currentRoute;
    _persistRoute(currentRoute);
  }
}

final MyRouteObserver globalRouteObserver = MyRouteObserver();

class MyApp extends StatefulWidget {
  final String? initialLanguageCode;
  const MyApp({super.key, this.initialLanguageCode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isFirstCheck = true;
  
  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasInternet = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (_isFirstCheck && hasInternet) {
      _isFirstCheck = false;
      return;
    }
    _isFirstCheck = false;

    String noInternetStr = "No Internet Connection";
    String backOnlineStr = "Back Online";
    final context = globalScaffoldMessengerKey.currentContext;
    if (context != null) {
      final loc = AppLocalizations.of(context);
      noInternetStr = loc.translate("no_internet");
      backOnlineStr = loc.translate("back_online");
    }

    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.black : Colors.white;

    if (!hasInternet) {
      globalScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      globalScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(noInternetStr, style: TextStyle(color: textColor)),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(days: 1),
        ),
      );
    } else {
      globalScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      globalScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(backOnlineStr, style: TextStyle(color: textColor)),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => LocalizationBloc(Locale(widget.initialLanguageCode ?? 'en'))),
        BlocProvider(
          create: (_) => OtpReceiveBloc(repository: OtpReceiveRepository()),
        ),
        BlocProvider(
          create: (_) => SendOtpBloc(repository: SendOtpRepository()),
        ),
        BlocProvider(create: (_) => SplashBloc(repository: SplashRepository())),
        BlocProvider(create: (_) => HomeController(HomeRepository())),
        BlocProvider(
          create: (_) => EditProfilePictureBloc(
            repository: EditProfileRepository(repository: SplashRepository()),
          ),
        ),
        BlocProvider(
          create: (_) => EditProfileInfoBloc(
            repository: EditProfileRepository(repository: SplashRepository()),
          ),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, localizationState) {
              return MaterialApp(
                navigatorKey: globalNavigatorKey,
                scaffoldMessengerKey: globalScaffoldMessengerKey,
                themeMode: themeState.themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                debugShowCheckedModeBanner: false,

                // 🌍 Localization
                locale: localizationState.locale,
            supportedLocales: const [Locale('en'), Locale('bn')],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // 🔥 ROUTING
            initialRoute: AppRoutes.splash,
            onGenerateRoute: RouteGenerator.generateRoute,
            navigatorObservers: [globalRouteObserver],
            builder: (context, child) {
              return Stack(
                children: [
                  child!,
                  ValueListenableBuilder<String?>(
                    valueListenable: globalRouteObserver.routeNotifier,
                    builder: (context, route, _) {
                      if (route == AppRoutes.splash || 
                          route == AppRoutes.numberInput || 
                          route == AppRoutes.otp) {
                        return const SizedBox.shrink();
                      }
                      return const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Material(
                          type: MaterialType.transparency,
                          child: SafeArea(
                            child: AcceptedTripCard(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      );
      },
    ),
    );
  }
}
