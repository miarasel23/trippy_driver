import 'package:flutter/material.dart';
import '../../../../core/utils/localization/app_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/rental_trip_model.dart';
import '../controller/home_controller.dart';
import '../helper/new_request_card_helper.dart';
import '../helper/accepted_trip_card_helper.dart';
import 'translated_text.dart';
import 'offer_bottom_sheet.dart';
import '../../../../utils/app_urls.dart';
import '../../../../store/app_globals.dart';
class NewRequestCard extends StatefulWidget {
  final RentalTripModel trip;

  const NewRequestCard({super.key, required this.trip});

  @override
  State<NewRequestCard> createState() => _NewRequestCardState();
}

class _NewRequestCardState extends State<NewRequestCard> {
  bool _hasBidded = false;


  String _translateNumbersAndCommonWords(String text, bool isBangla) {
    if (!isBangla) return text;
    const englishToBangla = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };
    String result = text.split('').map((e) => englishToBangla[e] ?? e).join('');
    result = result.replaceAll('km', 'কি.মি.');
    result = result.replaceAll(' m', ' মি.');
    result = result.replaceAll('away', 'দূরে');
    result = result.replaceAll('min', 'মিনিট');
    return result;
  }

  String _formatEnum(String text, AppLocalizations loc) {
    final key = text.toLowerCase();
    final translated = loc.translate(key);
    if (translated != null && translated != key) return translated;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _calculateMinutes(String pickupKmStr) {
    double distanceKm = 0.0;
    final lower = pickupKmStr.toLowerCase();
    if (lower.contains('km')) {
      distanceKm = double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (lower.contains('m')) {
      distanceKm = (double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) / 1000.0;
    }
    final minutes = (distanceKm * 2.4).ceil();
    return minutes == 0 ? "1 min" : "$minutes min";
  }

  DateTime _getNow() => AcceptedTripCardHelper.getNow();

  DateTime _parseCreatedAt(String createdAtStr) => AcceptedTripCardHelper.parseCreatedAt(createdAtStr);

  @override
  Widget build(BuildContext context) {
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final createdAtStr = widget.trip.myBid?.createdAt ?? widget.trip.createdAt;
    final createdAt = _parseCreatedAt(createdAtStr);
    final rawService = widget.trip.serviceName.isNotEmpty
        ? widget.trip.serviceName
        : widget.trip.carService.serviceName;
    final isRideShare = rawService.toUpperCase().contains('RIDE') ||
        rawService.toUpperCase() == 'RIDE_SHARE';

    if (!isRideShare && widget.trip.myBid != null) {
      return const SizedBox.shrink();
    }

    final totalDuration = isRideShare ? const Duration(minutes: 1) : const Duration(hours: 1);
    final now = _getNow();
    final expireTime = createdAt.add(totalDuration);
    final remaining = expireTime.difference(now);

    if (remaining.isNegative) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.trip.myBid != null) {
          context.read<HomeController>().removeBidTrip(widget.trip.uuid);
        } else {
          context.read<HomeController>().removeTrip(widget.trip.uuid);
        }
      });
      return const SizedBox.shrink();
    }

    final int currentRound = now.difference(createdAt).inMinutes;
    final animationKey = "${createdAtStr}_$currentRound";

    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween<double>(begin: remaining.inSeconds.toDouble(), end: 0),
      duration: remaining,
      onEnd: () {
        if (widget.trip.myBid != null) {
          context.read<HomeController>().removeBidTrip(widget.trip.uuid);
        } else {
          context.read<HomeController>().removeTrip(widget.trip.uuid);
        }
      },
      builder: (context, value, child) {
        return _buildCardContent(context, value, totalDuration.inSeconds.toDouble(), isRideShare, isBangla);
      },
    );
  }

  Widget _buildCardContent(BuildContext context, double remainingSeconds, double totalSeconds, bool isRideShare, bool isBangla) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final currency = isBangla ? '৳' : 'BDT';

    final formattedCarType = _formatEnum(widget.trip.carCategory.carType, loc);
    final rawService = widget.trip.serviceName.isNotEmpty
        ? widget.trip.serviceName
        : widget.trip.carService.serviceName;
    String formattedService = _formatEnum(rawService, loc);
    if (rawService.toUpperCase() == 'HOURLY' && widget.trip.hoursBooked != null) {
      final hrsText = _translateNumbersAndCommonWords("${widget.trip.hoursBooked}", isBangla);
      formattedService = "$formattedService\n($hrsText ${isBangla ? 'ঘণ্টা' : 'Hours'})";
    }
    final formattedAmount = _translateNumbersAndCommonWords("${widget.trip.customerOfferAmmount.round()}", isBangla);
    final formattedTotalDistance = _translateNumbersAndCommonWords("${widget.trip.totalDistance} km", isBangla);
    final formattedPickupDistance = _translateNumbersAndCommonWords(
        "${widget.trip.pickupKm} away\n(~${_calculateMinutes(widget.trip.pickupKm)})", isBangla);
    final progress = remainingSeconds / totalSeconds;
    final isLow = progress < 0.2;

    final pickupLoc = AcceptedTripCardHelper.getEffectivePickup(widget.trip);
    final dropoffLoc = AcceptedTripCardHelper.getEffectiveDropoff(widget.trip);
    final pickupAddress = pickupLoc?.address ?? '';
    final dropoffAddress = dropoffLoc?.address ?? '';
    final distanceText = "~$formattedTotalDistance";
    final timeText = _translateNumbersAndCommonWords(_calculateMinutes(widget.trip.pickupKm), isBangla);
    final customerName = widget.trip.customer.isNotEmpty && widget.trip.customer.first.name.isNotEmpty 
        ? widget.trip.customer.first.name 
        : loc.translate('customer') ?? "Customer";
    final customerAvatar = widget.trip.customer.isNotEmpty ? widget.trip.customer.first.profilePicture : '';
    final int totalTrips = widget.trip.customer.isNotEmpty ? widget.trip.customer.first.totalTripCount : widget.trip.totalTripCount;
    final String rawRating = widget.trip.customer.isNotEmpty ? widget.trip.customer.first.averageRating.toStringAsFixed(1) : "4.5";
    final String customerRating = totalTrips > 0 
        ? "${_translateNumbersAndCommonWords(rawRating, isBangla)} (${_translateNumbersAndCommonWords(totalTrips.toString(), isBangla)})" 
        : _translateNumbersAndCommonWords(rawRating, isBangla);
    
    final String status = widget.trip.myBid?.status ?? widget.trip.tripStatus;
    final bool hasActiveBid = widget.trip.myBid != null && status != 'ACCEPTED' && status != 'CANCELLED' && !AcceptedTripCardHelper.isBidExpired(widget.trip);
    final String displayMyBid = isBangla 
        ? _translateNumbersAndCommonWords("${widget.trip.myBid?.amount.round() ?? widget.trip.customerOfferAmmount.round()}", isBangla) 
        : "${widget.trip.myBid?.amount.round() ?? widget.trip.customerOfferAmmount.round()}";

    // Theme responsive card
    Widget card = InkWell(
      onTap: hasActiveBid ? null : () {
        OfferBottomSheet.show(context, widget.trip, isRideShare);
        context.read<HomeController>().selectTripForPreview(widget.trip);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            distanceText,
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$currency $formattedAmount",
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Builder(
                        builder: (context) {
                          final int mins = (remainingSeconds / 60).floor();
                          final int secs = (remainingSeconds % 60).floor();
                          String timeStr = "$mins:${secs.toString().padLeft(2, '0')}";
                          if (isBangla) {
                            timeStr = _translateNumbersAndCommonWords(timeStr, isBangla);
                          }
                          final Color timerColor = remainingSeconds <= (isRideShare ? 20 : 20 * 60) ? Colors.redAccent : (theme.brightness == Brightness.dark ? Colors.lightGreenAccent : Colors.green.shade700);
                          return Container(
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
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AcceptedTripCardHelper.buildTripDateTimes(context, widget.trip, isBangla, theme),
                  TranslatedText(
                    pickupAddress,
                    isBangla: isBangla,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                    location: pickupLoc,
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    dropoffAddress,
                    isBangla: isBangla,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                    location: dropoffLoc,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.trip.carCategory.carType,
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.person,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Text(
                        _translateNumbersAndCommonWords("${widget.trip.carCategory.setCapacity}", isBangla),
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11),
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
                // Service avatar image
                () {
                  final carAvatar = widget.trip.carCategory.carAvatar.isNotEmpty
                      ? widget.trip.carCategory.carAvatar
                      : widget.trip.carService.avatar;
                  final avatarUrl = carAvatar.isNotEmpty
                      ? (carAvatar.startsWith('http') ? carAvatar : '${AppUrls.imageBaseUrl}$carAvatar')
                      : null;
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.directions_car_rounded,
                                    size: 28,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.directions_car_rounded,
                                size: 28,
                                color: theme.colorScheme.primary,
                              ),
                      );
                    }(),
                    const SizedBox(height: 6),
                    // Service name label
                    Text(
                      formattedService.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Visibility(
            visible: remainingSeconds > 0,
            maintainSize: false,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingSeconds <= (isRideShare ? 20 : 20 * 60) ? Colors.redAccent : const Color(0xFFC4F934),
              ),
              minHeight: 3,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
          ],
        ),
      ),
    );

    if (hasActiveBid) {
      return Stack(
        children: [
          card,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.5)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.translate('offering_your_fare') ?? 'Offering your fare',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$currency $displayMyBid.",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.translate('wait_for_reply') ?? 'Wait for the reply',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }
}

