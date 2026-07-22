import 'package:flutter/material.dart';
import '../../../../core/utils/localization/app_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/rental_trip_model.dart';
import '../controller/home_controller.dart';
import '../helper/new_request_card_helper.dart';
import 'translated_text.dart';
import 'offer_bottom_sheet.dart';
import '../../../../utils/app_urls.dart';
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

  DateTime _parseCreatedAt(String createdAtStr) {
    DateTime parsed = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    if (parsed.difference(DateTime.now()).inHours >= 5) {
      return parsed.subtract(const Duration(hours: 7));
    }
    return parsed;
  }


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
    final String status = widget.trip.myBid?.status ?? widget.trip.tripStatus;
    final bool hasActiveBid = widget.trip.myBid != null && status != 'ACCEPTED' && status != 'CANCELLED';

    final totalDuration = hasActiveBid ? const Duration(seconds: 100) : const Duration(minutes: 1);
    Duration remaining;
    int currentRound = 0;

    if (hasActiveBid) {
      final elapsed = DateTime.now().difference(createdAt);
      currentRound = elapsed.inMinutes;
      int remainingSeconds = totalDuration.inSeconds - (elapsed.inSeconds % totalDuration.inSeconds);
      if (remainingSeconds == totalDuration.inSeconds) remainingSeconds = 0;
      remaining = Duration(seconds: remainingSeconds);
    } else {
      final expireTime = createdAt.add(totalDuration);
      remaining = expireTime.difference(DateTime.now());
      if (remaining.isNegative) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<HomeController>().removeTrip(widget.trip.uuid);
        });
        return const SizedBox.shrink();
      }
    }

    final animationKey = "${createdAtStr}_$currentRound";

    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween<double>(begin: remaining.inSeconds.toDouble(), end: 0),
      duration: remaining,
      onEnd: () {
        if (!hasActiveBid) {
          context.read<HomeController>().removeTrip(widget.trip.uuid);
        } else {
          if (mounted) setState(() {});
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
    final formattedService = _formatEnum(
      widget.trip.serviceName.isNotEmpty
          ? widget.trip.serviceName
          : widget.trip.carService.serviceName,
      loc,
    );
    final formattedAmount = _translateNumbersAndCommonWords("${widget.trip.customerOfferAmmount.round()}", isBangla);
    final formattedTotalDistance = _translateNumbersAndCommonWords("${widget.trip.totalDistance} km", isBangla);
    final formattedPickupDistance = _translateNumbersAndCommonWords(
        "${widget.trip.pickupKm} away\n(~${_calculateMinutes(widget.trip.pickupKm)})", isBangla);
    final progress = remainingSeconds / totalSeconds;
    final isLow = progress < 0.2;

    final pickupAddress = widget.trip.pickupLocations.isNotEmpty ? widget.trip.pickupLocations.first.address : '';
    final dropoffAddress = widget.trip.dropoffLocations.isNotEmpty ? widget.trip.dropoffLocations.first.address : '';
    final distanceText = "~$formattedTotalDistance";
    final timeText = _translateNumbersAndCommonWords("${_calculateMinutes(widget.trip.pickupKm)} min", isBangla);
    final customerName = widget.trip.customer.isNotEmpty && widget.trip.customer.first.name.isNotEmpty 
        ? widget.trip.customer.first.name 
        : loc.translate('customer') ?? "Customer";
    final customerAvatar = widget.trip.customer.isNotEmpty ? widget.trip.customer.first.profilePicture : '';
    final customerRating = widget.trip.customer.isNotEmpty ? _translateNumbersAndCommonWords(widget.trip.customer.first.averageRating.toStringAsFixed(1), isBangla) : _translateNumbersAndCommonWords("4.5", isBangla);
    
    final String status = widget.trip.myBid?.status ?? widget.trip.tripStatus;
    final bool hasActiveBid = widget.trip.myBid != null && status != 'ACCEPTED' && status != 'CANCELLED';
    final String displayMyBid = isBangla 
        ? _translateNumbersAndCommonWords("${widget.trip.myBid?.amount.round() ?? widget.trip.customerOfferAmmount.round()}", isBangla) 
        : "${widget.trip.myBid?.amount.round() ?? widget.trip.customerOfferAmmount.round()}";

    // Theme responsive card
    Widget card = InkWell(
      onTap: hasActiveBid ? null : () => OfferBottomSheet.show(context, widget.trip, isRideShare),
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
                  Text(
                    distanceText,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$currency$formattedAmount",
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TranslatedText(
                    pickupAddress,
                    isBangla: isBangla,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    dropoffAddress,
                    isBangla: isBangla,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  ),
                ],
              ),
            ),
                // Right Column: Options icon
                SizedBox(
                  width: 24,
                  child: Icon(Icons.more_vert, color: theme.colorScheme.onSurface, size: 20),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingSeconds <= 20 ? Colors.redAccent : const Color(0xFFC4F934),
              ),
              minHeight: 6,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );

    if (isRideShare && hasActiveBid) {
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
                      "$currency$displayMyBid.",
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

