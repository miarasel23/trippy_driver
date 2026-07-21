import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import 'translated_text.dart';
import 'cancel_trip_dialog.dart';

class PendingBidTripCard extends StatefulWidget {
  const PendingBidTripCard({Key? key}) : super(key: key);

  @override
  State<PendingBidTripCard> createState() => _PendingBidTripCardState();
}

class _PendingBidTripCardState extends State<PendingBidTripCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _toBanglaDigits(String input) {
    const englishToBanglaDigits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };
    return input.split('').map((char) => englishToBanglaDigits[char] ?? char).join();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {

        if (!state.isOnline) return const SizedBox.shrink();

        final now = DateTime.now();
        final pendingTrips = state.bidTrips.where((t) {
          // Must have placed a bid and status is still pending (not ACCEPTED or CANCELLED)
          if (t.myBid == null) return false;
          final status = t.myBid!.status.toUpperCase();
          if (status == 'ACCEPTED' || status == 'CANCELLED') return false;
          
          final createdAtStr = t.myBid?.createdAt ?? t.createdAt;
          DateTime createdAt = DateTime.tryParse(createdAtStr) ?? now;
          if (createdAt.isAfter(now.add(const Duration(hours: 1)))) {
            createdAt = createdAt.subtract(const Duration(hours: 7));
          }
          final expireTime = createdAt.add(const Duration(minutes: 1));
          if (expireTime.difference(DateTime.now()).isNegative) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<HomeController>().removeBidTrip(t.uuid);
              }
            });
            return false;
          }
          return true;
        }).toList();


        if (pendingTrips.isEmpty) return const SizedBox.shrink();

        final trip = pendingTrips.first;
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);
        final isBangla = Localizations.localeOf(context).languageCode == 'bn';

        // Timer is already validated, just calculate remaining for display
        final createdAtStr = trip.myBid?.createdAt ?? trip.createdAt;
        DateTime createdAt = DateTime.tryParse(createdAtStr) ?? now;
        if (createdAt.isAfter(now.add(const Duration(hours: 1)))) {
          createdAt = createdAt.subtract(const Duration(hours: 7));
        }
        final remaining = createdAt.add(const Duration(minutes: 1)).difference(DateTime.now());

        String timeString = "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
        if (isBangla) {
          timeString = _toBanglaDigits(timeString);
        }
        
        final Color timerColor = remaining.inSeconds <= 20 ? Colors.red : Colors.lightGreen;

        final pickupLoc = trip.pickupLocations.isNotEmpty ? trip.pickupLocations.first : null;
        final dropoffLoc = trip.dropoffLocations.isNotEmpty ? trip.dropoffLocations.first : null;
        
        var pickup = pickupLoc?.address ?? 'Unknown';
        var dropoff = dropoffLoc?.address ?? 'Unknown';
        
        final customerOffer = trip.customerOfferAmmount;
        final myBid = trip.myBid?.amount ?? customerOffer;
        
        final currency = isBangla ? '৳' : 'BDT';
        final displayCustomerOffer = isBangla ? _toBanglaDigits(customerOffer.round().toString()) : customerOffer.round().toString();
        final displayMyBid = isBangla ? _toBanglaDigits(myBid.round().toString()) : myBid.round().toString();

        String headerTitle = loc.translate('wait_customer_acceptance') ?? 'Waiting for customer response';

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer, color: Colors.orange, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            headerTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: timerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: timerColor),
                        const SizedBox(width: 4),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: timerColor, 
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (remaining.inSeconds / 60.0).clamp(0.0, 1.0),
                  backgroundColor: timerColor.withOpacity(0.1),
                  color: timerColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.my_location, size: 16, color: Colors.blue.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      pickup,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      isBangla: isBangla,
                      location: pickupLoc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red.withOpacity(0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      dropoff,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 14),
                      isBangla: isBangla,
                      location: dropoffLoc,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate('my_bid') ?? 'Your Bid',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "$currency $displayMyBid",
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
