import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../model/rental_trip_model.dart';
import '../../../../store/app_globals.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../widget/translated_text.dart';
import '../../../../utils/app_urls.dart';

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

  static bool isBidTimestampExpired(String createdAtStr, String serviceName, String bidStatus, [String? tripStatus]) {
    final statusStr = bidStatus.toUpperCase();
    final tripStatusStr = (tripStatus ?? '').toUpperCase();
    if (statusStr == 'ACCEPTED' || 
        tripStatusStr == 'ACCEPTED' || 
        tripStatusStr == 'RIDE_STARTED' || 
        tripStatusStr == 'FIRST_COMPLETED' || 
        tripStatusStr == 'IN_PROGRESS' || 
        tripStatusStr == 'COMPLETED') {
      return false;
    }
    if (statusStr == 'REJECTED' || statusStr == 'CANCELLED' || statusStr == 'EXPIRED') {
      return true;
    }
    if (createdAtStr.isEmpty) return false;
    try {
      final createdAt = parseCreatedAt(createdAtStr);
      final isRideShare = serviceName.toUpperCase().contains('RIDE') || serviceName.toUpperCase() == 'RIDE_SHARE';
      final totalDuration = isRideShare ? const Duration(minutes: 1) : const Duration(hours: 1);
      final expireTime = createdAt.add(totalDuration);
      if (getNow().isAfter(expireTime) || expireTime.difference(getNow()).inSeconds <= 0) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static bool isBidExpired(RentalTripModel trip) {
    if (trip.myBid == null) return false;
    final status = trip.tripStatus.toUpperCase();
    final bidStatus = trip.myBid!.status.toUpperCase();
    if (status == 'ACCEPTED' || 
        status == 'RIDE_STARTED' || 
        status == 'FIRST_COMPLETED' || 
        status == 'IN_PROGRESS' || 
        status == 'COMPLETED' || 
        bidStatus == 'ACCEPTED') {
      return false;
    }
    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    return isBidTimestampExpired(trip.myBid!.createdAt, rawService, trip.myBid!.status, trip.tripStatus);
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

    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    if (rawService.toUpperCase() == 'HOURLY' && trip.hoursBooked != null) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 4));
      final hrsVal = translateNumbersAndCommonWords("${trip.hoursBooked}", isBangla);
      widgets.add(
        Row(
          children: [
            Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.purple.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "${isBangla ? 'বুকিং সময়: ' : 'Booked Time: '}$hrsVal ${isBangla ? 'ঘণ্টা' : 'Hours'}",
                style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.w900, fontSize: 13.5),
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

  static Widget buildUnifiedTripCardContent({
    required BuildContext context,
    required RentalTripModel trip,
    required bool isBangla,
    required ThemeData theme,
    required AppLocalizations loc,
    required Duration remaining,
    required bool isRideShare,
    bool isMyBid = false,
  }) {
    final pickupLoc = getEffectivePickup(trip);
    final dropoffLoc = getEffectiveDropoff(trip);
    final pickupAddress = pickupLoc?.address ?? '';
    final dropoffAddress = dropoffLoc?.address ?? '';
    
    final formattedTotalDistance = translateNumbersAndCommonWords("${trip.totalDistance} km", isBangla);
    final distanceText = "~$formattedTotalDistance";
    final timeText = translateNumbersAndCommonWords("${calculateMinutes(trip.pickupKm)} min", isBangla);
    
    final customerName = trip.customer.isNotEmpty && trip.customer.first.name.isNotEmpty 
        ? trip.customer.first.name 
        : loc.translate('customer') ?? "Customer";
    final customerAvatar = trip.customer.isNotEmpty ? trip.customer.first.profilePicture : '';
    final int totalTrips = trip.customer.isNotEmpty ? trip.customer.first.totalTripCount : trip.totalTripCount;
    final String rawRating = trip.customer.isNotEmpty ? trip.customer.first.averageRating.toStringAsFixed(1) : "4.5";
    final String customerRating = totalTrips > 0 
        ? "${translateNumbersAndCommonWords(rawRating, isBangla)} (${translateNumbersAndCommonWords(totalTrips.toString(), isBangla)})" 
        : translateNumbersAndCommonWords(rawRating, isBangla);
        
    final amountToDisplay = isMyBid ? (trip.myBid?.amount ?? trip.customerOfferAmmount) : trip.customerOfferAmmount;
    final currency = isBangla ? '৳' : 'BDT';
    final formattedAmount = translateNumbersAndCommonWords("${amountToDisplay.round()}", isBangla);
    
    final int totalSeconds = remaining.inSeconds.clamp(0, double.maxFinite.toInt());
    final int hours = totalSeconds ~/ 3600;
    final int mins = (totalSeconds % 3600) ~/ 60;
    final int secs = totalSeconds % 60;
    String timeStr;
    if (hours > 0) {
      timeStr = "$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    } else {
      timeStr = "$mins:${secs.toString().padLeft(2, '0')}";
    }
    if (isBangla) {
      timeStr = translateNumbersAndCommonWords(timeStr, isBangla);
    }
    final Color timerColor = remaining.inSeconds <= (isRideShare ? 20 : 20 * 60)
        ? Colors.redAccent
        : (theme.brightness == Brightness.dark ? Colors.lightGreenAccent : Colors.green.shade700);

    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    String formattedService = rawService.replaceAll('_', ' ').toUpperCase();
    if (rawService.toUpperCase() == 'HOURLY' && trip.hoursBooked != null) {
      final hrsText = translateNumbersAndCommonWords("${trip.hoursBooked}", isBangla);
      formattedService = "$formattedService\n($hrsText ${isBangla ? 'ঘণ্টা' : 'Hours'})";
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Avatar, Name, Rating, Time
        SizedBox(
          width: 70,
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: customerAvatar.isNotEmpty
                    ? NetworkImage(customerAvatar.startsWith('http') ? customerAvatar : '${AppUrls.imageBaseUrl}$customerAvatar')
                    : null,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: customerAvatar.isEmpty
                    ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 28)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                customerName,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    customerRating,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                timeText,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Middle Column: Distance, Price, Locations
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        distanceText,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (isMyBid) ...[
                        Text(
                          "  •  ",
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                        ),
                        Text(
                          loc.translate('my_bid') ?? 'My Bid',
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "$currency $formattedAmount",
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: timerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: timerColor.withOpacity(0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: timerColor),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(color: timerColor, fontSize: 13, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              buildTripDateTimes(context, trip, isBangla, theme),
              TranslatedText(
                pickupAddress,
                isBangla: isBangla,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                location: pickupLoc,
              ),
              const SizedBox(height: 4),
              TranslatedText(
                dropoffAddress,
                isBangla: isBangla,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                location: dropoffLoc,
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trip.carCategory.carType,
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Text(
                        translateNumbersAndCommonWords("${trip.carCategory.setCapacity}", isBangla),
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Right Column: Service Avatar + Service Name
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Builder(
              builder: (context) {
                final carAvatar = trip.carCategory.carAvatar.isNotEmpty
                    ? trip.carCategory.carAvatar
                    : trip.carService.avatar;
                final avatarUrl = carAvatar.isNotEmpty
                    ? (carAvatar.startsWith('http') ? carAvatar : '${AppUrls.imageBaseUrl}$carAvatar')
                    : null;
                return Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.directions_car_rounded,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.directions_car_rounded,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                );
              },
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                formattedService,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
