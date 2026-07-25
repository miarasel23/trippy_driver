import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../model/rental_trip_model.dart';
import '../../../../store/app_globals.dart';

class AcceptedTripCardHelper {
  static DateTime getNow() {
    if (AppGlobals.countryCode.toUpperCase() == 'BD') {
      final utc = DateTime.now().toUtc().add(const Duration(hours: 6));
      return DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second, utc.millisecond, utc.microsecond);
    }
    return DateTime.now();
  }

  static DateTime parseCreatedAt(String createdAtStr) {
    final now = getNow();
    DateTime parsed = DateTime.tryParse(createdAtStr) ?? now;
    if (parsed.isUtc) {
      if (AppGlobals.countryCode.toUpperCase() == 'BD') {
        final dhaka = parsed.add(const Duration(hours: 6));
        parsed = DateTime(dhaka.year, dhaka.month, dhaka.day, dhaka.hour, dhaka.minute, dhaka.second);
      } else {
        final local = parsed.toLocal();
        parsed = DateTime(local.year, local.month, local.day, local.hour, local.minute, local.second);
      }
    }
    if (parsed.difference(now).inHours >= 5) {
      return parsed.subtract(const Duration(hours: 7));
    }
    return parsed;
  }

  static DateTime parseTripDateTime(String dtStr) {
    final now = getNow();
    DateTime parsed = DateTime.tryParse(dtStr) ?? now;
    if (parsed.isUtc) {
      if (AppGlobals.countryCode.toUpperCase() == 'BD') {
        final dhaka = parsed.add(const Duration(hours: 6));
        return DateTime(dhaka.year, dhaka.month, dhaka.day, dhaka.hour, dhaka.minute, dhaka.second);
      } else {
        final local = parsed.toLocal();
        return DateTime(local.year, local.month, local.day, local.hour, local.minute, local.second);
      }
    }
    return parsed;
  }

  static bool shouldShowAcceptedTripCard(RentalTripModel trip) {
    final status = trip.tripStatus.toUpperCase();
    if (status == 'RIDE_STARTED' || status == 'IN_PROGRESS' || status == 'COMPLETED') {
      return true;
    }

    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    if (rawService.toUpperCase().contains('RIDE') || rawService.toUpperCase() == 'RIDE_SHARE') {
      return true;
    }

    final isReturnTrip = rawService.toUpperCase() == 'RETURN' || rawService.toUpperCase() == 'ROUND_TRIP';
    String startStr = trip.startDatetime;
    if (isReturnTrip && status == 'FIRST_COMPLETED') {
      startStr = trip.endDatetime.isNotEmpty ? trip.endDatetime : trip.startDatetime;
    }

    if (startStr.isEmpty) return true;

    try {
      final startTime = parseTripDateTime(startStr);
      final now = getNow();
      if (startTime.difference(now).inMinutes > 120) {
        return false;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  static String formatStartDatetime(String datetimeStr, bool isBangla) {
    if (datetimeStr.isEmpty) return datetimeStr;
    try {
      final date = DateTime.parse(datetimeStr);
      final formatter = DateFormat("d MMM yyyy 'and' h:mm a");
      final formatted = formatter.format(date);
      return isBangla ? translateNumbersAndCommonWords(formatted, isBangla) : formatted;
    } catch (e) {
      return isBangla ? translateNumbersAndCommonWords(datetimeStr, isBangla) : datetimeStr;
    }
  }
  static Widget buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> launchPhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  static Future<void> launchNavigation(LocationModel? pickupLoc) async {
    if (pickupLoc != null) {
      final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${pickupLoc.latitude},${pickupLoc.longitude}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  static LocationModel? getEffectivePickup(RentalTripModel trip) {
    final isReturnTrip = trip.serviceName.toUpperCase() == 'RETURN' || trip.serviceName.toUpperCase() == 'ROUND_TRIP';
    final currentStatus = trip.tripStatus == 'REQUESTED' ? (trip.myBid?.status ?? trip.tripStatus) : trip.tripStatus;
    if (isReturnTrip && currentStatus == 'FIRST_COMPLETED') {
      return trip.dropoffLocations.isNotEmpty ? trip.dropoffLocations.first : (trip.pickupLocations.isNotEmpty ? trip.pickupLocations.first : null);
    }
    return trip.pickupLocations.isNotEmpty ? trip.pickupLocations.first : null;
  }

  static LocationModel? getEffectiveDropoff(RentalTripModel trip) {
    final isReturnTrip = trip.serviceName.toUpperCase() == 'RETURN' || trip.serviceName.toUpperCase() == 'ROUND_TRIP';
    final currentStatus = trip.tripStatus == 'REQUESTED' ? (trip.myBid?.status ?? trip.tripStatus) : trip.tripStatus;
    if (isReturnTrip && currentStatus == 'FIRST_COMPLETED') {
      return trip.pickupLocations.isNotEmpty ? trip.pickupLocations.first : (trip.dropoffLocations.isNotEmpty ? trip.dropoffLocations.first : null);
    }
    return trip.dropoffLocations.isNotEmpty ? trip.dropoffLocations.first : null;
  }

  static Widget buildTripDateTimes(BuildContext context, RentalTripModel trip, bool isBangla, ThemeData theme) {
    if (trip.serviceName.toUpperCase() == 'RIDE_SHARE') {
      return const SizedBox.shrink();
    }
    final isReturnTrip = trip.serviceName.toUpperCase() == 'RETURN' || trip.serviceName.toUpperCase() == 'ROUND_TRIP';
    final currentStatus = trip.tripStatus == 'REQUESTED' ? (trip.myBid?.status ?? trip.tripStatus) : trip.tripStatus;

    String startStr = trip.startDatetime;
    String endStr = trip.endDatetime;

    if (isReturnTrip && currentStatus == 'FIRST_COMPLETED') {
      startStr = trip.endDatetime.isNotEmpty ? trip.endDatetime : trip.startDatetime;
      endStr = '';
    }

    final List<Widget> widgets = [];
    if (startStr.isNotEmpty) {
      widgets.add(
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                formatStartDatetime(startStr, isBangla),
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
            ),
          ],
        ),
      );
    }

    if (endStr.isNotEmpty && isReturnTrip && currentStatus != 'FIRST_COMPLETED') {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 4));
      widgets.add(
        Row(
          children: [
            Icon(Icons.event_repeat_rounded, size: 16, color: Colors.orange.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                formatStartDatetime(endStr, isBangla),
                style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
            ),
          ],
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widgets,
        const SizedBox(height: 8),
      ],
    );
  }

  static String translateNumbersAndCommonWords(String text, bool isBangla) {
    if (!isBangla) return text;
    const e2b = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯'
    };
    String result = text.split('').map((e) => e2b[e] ?? e).join('');
    result = result.replaceAll('km', 'কি.মি.');
    result = result.replaceAll(' m', ' মি.');
    result = result.replaceAll('away', 'দূরে');
    result = result.replaceAll('min', 'মিনিট');
    result = result.replaceAll('and', 'এবং');
    result = result.replaceAll('Jan', 'জানু');
    result = result.replaceAll('Feb', 'ফেব');
    result = result.replaceAll('Mar', 'মার্চ');
    result = result.replaceAll('Apr', 'এপ্রিল');
    result = result.replaceAll('May', 'মে');
    result = result.replaceAll('Jun', 'জুন');
    result = result.replaceAll('Jul', 'জুলাই');
    result = result.replaceAll('Aug', 'আগস্ট');
    result = result.replaceAll('Sep', 'সেপ্টে');
    result = result.replaceAll('Oct', 'অক্টো');
    result = result.replaceAll('Nov', 'নভে');
    result = result.replaceAll('Dec', 'ডিসে');
    result = result.replaceAll('AM', 'এএম');
    result = result.replaceAll('PM', 'পিএম');
    return result;
  }

  static String calculateMinutes(String pickupKmStr) {
    double distanceKm = 0.0;
    final lower = pickupKmStr.toLowerCase();
    if (lower.contains('km')) {
      distanceKm = double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (lower.contains('m')) {
      distanceKm = (double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) / 1000;
    }
    int minutes = (distanceKm / 40 * 60).round();
    return minutes < 1 ? "1" : minutes.toString();
  }
}
