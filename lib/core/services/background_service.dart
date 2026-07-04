import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../modules/myTrip/repository/my_trip_repository.dart';
import '../../store/user_data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'trip_bid_channel',
    'Trip Bids',
    description: 'Notifications for incoming driver bids.',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'trip_bid_channel',
      initialNotificationTitle: 'Trippy Customer Service',
      initialNotificationContent: 'Running in the background...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final repository = MyTripRepository();
  int lastNotifiedBidsCount = 0;

  // We run this every 10 seconds to poll for bids
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) {
        // If not in foreground service mode, we can still run, but typically we want it foreground
      }
    }

    try {
      // Must fetch from SharedPreferences in the new isolate
      final uuid = await UserDataStore.getUuid();
      final token = await UserDataStore.getAccessToken();

      // Only check if user is logged in
      if (uuid != null && uuid.isNotEmpty && token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final langCode = prefs.getString('active_language_code') ?? 'en';
        
        final response = await repository.fetchTrips("REQUESTED", langCode);

        int currentBids = 0;
        for (var trip in response.trips) {
          currentBids += (trip.totalBids ?? 0);
        }

        if (currentBids > lastNotifiedBidsCount) {
          String title = 'Driver Found!';
          String body = 'A driver has placed a bid on your requested trip. Tap to view bids.';
          
          try {
            final jsonStr = await rootBundle.loadString('assets/lang/$langCode.json');
            final Map<String, dynamic> translations = jsonDecode(jsonStr);
            title = translations['notification_new_bid_title'] ?? title;
            body = translations['notification_new_bid_body'] ?? body;
          } catch (err) {
            debugPrint("BackgroundService: Failed to load localization asset: $err");
            if (langCode == 'bn') {
              title = 'ড্রাইভার পাওয়া গেছে!';
              body = 'একজন ড্রাইভার আপনার অনুরোধ করা ট্রিপে বিড করেছেন। বিড দেখতে ট্যাপ করুন।';
            }
          }

          flutterLocalNotificationsPlugin.show(
            id: 889,
            title: title,
            body: body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'trip_bid_channel',
                'Trip Bids',
                channelDescription: 'Notifications for incoming driver bids.',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
        lastNotifiedBidsCount = currentBids;
      }
    } catch (e) {
      debugPrint('Background fetch error: $e');
    }
  });
}
