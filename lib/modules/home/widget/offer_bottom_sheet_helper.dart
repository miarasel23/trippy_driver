import 'package:flutter/material.dart';
import '../../../core/utils/localization/app_localization.dart';

import '../model/rental_trip_model.dart';
import 'translated_text_widget.dart';
import '../../../../utils/app_urls.dart';

// ─── Offer utility ──────────────────────────────────────────────────────────

String offerToBanglaDigits(String input) {
  const englishToBanglaDigits = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
  };
  return input
      .split('')
      .map((c) => englishToBanglaDigits[c] ?? c)
      .join();
}

String offerTranslate(String text, bool isBangla) {
  if (!isBangla) return text;
  String result = offerToBanglaDigits(text);
  result = result.replaceAll(' km', ' কি.মি.');
  result = result.replaceAll(' away', ' দূরে');
  return result;
}

// ─── OfferTimerHeader ────────────────────────────────────────────────────────

class OfferTimerHeader extends StatelessWidget {
  final RentalTripModel trip;
  final bool isRideShare;
  final double remainingSeconds;
  final double totalSeconds;
  final bool isBangla;

  const OfferTimerHeader({
    super.key,
    required this.trip,
    required this.isRideShare,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isBangla,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rawService = trip.serviceName.isNotEmpty
        ? trip.serviceName
        : trip.carService.serviceName;
    var serviceLabel = rawService.replaceAll('_', ' ').toUpperCase();
    if (rawService.toUpperCase() == 'HOURLY' && trip.hoursBooked != null) {
      final hrsText =
          offerTranslate('${trip.hoursBooked}', isBangla);
      serviceLabel =
          '$serviceLabel ($hrsText ${isBangla ? 'ঘণ্টা' : 'HOURS'})';
    }

    final progress = totalSeconds > 0 ? (remainingSeconds / totalSeconds) : 0.0;
    final int mins = (remainingSeconds / 60).floor();
    final int secs = (remainingSeconds % 60).floor();
    String timeStr = '$mins:${secs.toString().padLeft(2, '0')}';
    if (isBangla) timeStr = offerTranslate(timeStr, isBangla);

    final Color timerColor =
        remainingSeconds <= (isRideShare ? 20 : 20 * 60)
            ? Colors.redAccent
            : (theme.brightness == Brightness.dark
                ? Colors.lightGreenAccent
                : Colors.green.shade700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: timerColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: timerColor),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                        color: timerColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5),
              ),
              child: Text(
                serviceLabel,
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (remainingSeconds > 0)
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              remainingSeconds <= (isRideShare ? 20 : 20 * 60)
                  ? Colors.redAccent
                  : const Color(0xFFC4F934),
            ),
            minHeight: 3,
            borderRadius: BorderRadius.circular(4),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── OfferCustomerRow ────────────────────────────────────────────────────────

class OfferCustomerRow extends StatelessWidget {
  final RentalTripModel trip;
  final bool isBangla;
  final String currency;
  final String formattedAmount;
  final String distanceText;

  const OfferCustomerRow({
    super.key,
    required this.trip,
    required this.isBangla,
    required this.currency,
    required this.formattedAmount,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final customerAvatar = trip.customer.isNotEmpty
        ? trip.customer.first.profilePicture
        : '';
    final customerName = trip.customer.isNotEmpty &&
            trip.customer.first.name.isNotEmpty
        ? trip.customer.first.name
        : loc.translate('customer') ?? 'Customer';
    final int totalTrips = trip.customer.isNotEmpty
        ? trip.customer.first.totalTripCount
        : trip.totalTripCount;
    final String rawRating = trip.customer.isNotEmpty
        ? trip.customer.first.averageRating.toStringAsFixed(1)
        : '4.5';
    final String customerRating = totalTrips > 0
        ? '${offerTranslate(rawRating, isBangla)} (${offerTranslate(totalTrips.toString(), isBangla)})'
        : offerTranslate(rawRating, isBangla);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: customerAvatar.isNotEmpty
              ? NetworkImage(customerAvatar.startsWith('http')
                  ? customerAvatar
                  : '${AppUrls.imageBaseUrl}$customerAvatar')
              : null,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: customerAvatar.isEmpty
              ? Icon(Icons.person,
                  color: theme.colorScheme.onSurfaceVariant, size: 24)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 2),
              Text(
                customerRating,
                style: TextStyle(
                    color: theme.colorScheme.onSurface, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$currency $formattedAmount',
              maxLines: 1,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              distanceText,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── OfferLocationRow ────────────────────────────────────────────────────────

class OfferLocationRow extends StatelessWidget {
  final String label;
  final Color dotColor;
  final String address;
  final bool isBangla;
  final dynamic location; // LocationModel

  const OfferLocationRow({
    super.key,
    required this.label,
    required this.dotColor,
    required this.address,
    required this.isBangla,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TranslatedText(
            address,
            isBangla: isBangla,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: theme.colorScheme.onSurface, fontSize: 15),
            location: location,
          ),
        ),
      ],
    );
  }
}

// ─── OfferBidSection ─────────────────────────────────────────────────────────

class OfferBidSection extends StatelessWidget {
  final bool isEditingFare;
  final bool isSubmitting;
  final TextEditingController bidController;
  final String? bidError;
  final bool isBangla;
  final String currency;
  final int bid10;
  final int bid18;
  final VoidCallback onToggleEdit;
  final ValueChanged<String> onBidChanged;
  final VoidCallback onBidSubmitFromField;
  final ValueChanged<double> onQuickBid;

  const OfferBidSection({
    super.key,
    required this.isEditingFare,
    required this.isSubmitting,
    required this.bidController,
    required this.bidError,
    required this.isBangla,
    required this.currency,
    required this.bid10,
    required this.bid18,
    required this.onToggleEdit,
    required this.onBidChanged,
    required this.onBidSubmitFromField,
    required this.onQuickBid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.translate('offer_your_fare') ?? 'Offer your fare',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (isEditingFare)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: bidController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        loc.translate('offer_amount') ?? 'Offer Amount',
                    labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 12),
                    errorText: bidError,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    prefixText: '$currency ',
                    prefixStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  onChanged: onBidChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: bidError != null ? 68 : 52,
                  child: ElevatedButton(
                    onPressed: (bidError == null && !isSubmitting)
                        ? onBidSubmitFromField
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                      disabledBackgroundColor: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                      disabledForegroundColor: (theme.brightness == Brightness.dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      loc.translate('bid_now') ?? 'Bid',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isSubmitting ? null : () => onQuickBid(bid10.toDouble()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    disabledBackgroundColor: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                    disabledForegroundColor: (theme.brightness == Brightness.dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: Text(
                    '$currency ${offerTranslate(bid10.toString(), isBangla)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isSubmitting ? null : () => onQuickBid(bid18.toDouble()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    disabledBackgroundColor: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                    disabledForegroundColor: (theme.brightness == Brightness.dark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: Text(
                    '$currency ${offerTranslate(bid18.toString(), isBangla)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onToggleEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Icon(Icons.edit, size: 20),
              ),
            ],
          ),
      ],
    );
  }
}
