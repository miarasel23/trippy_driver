import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import 'translated_text.dart';
import 'new_request_card.dart';

class BidTripOverlay extends StatelessWidget {
  const BidTripOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        if (!state.isOnline || (state.serviceMode != 'RIDE SHARE' && state.serviceMode != 'BOTH')) {
          return const SizedBox.shrink();
        }
        final pendingTrips = state.bidTrips.where((t) {
          final status = t.myBid?.status ?? t.tripStatus;
          return status != 'ACCEPTED';
        }).toList();

        if (pendingTrips.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.gavel, size: 20, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('active_bid') ?? 'Active Bid',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            loc.translate('wait_customer_acceptance') ?? 'Waiting for customer acceptance...',
                            style: const TextStyle(
                              color: Colors.orange, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingTrips.length}',
                        style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: pendingTrips.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final trip = pendingTrips[index];
                    return _BidTripItem(trip: trip);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BidTripItem extends StatefulWidget {
  final RentalTripModel trip;

  const _BidTripItem({Key? key, required this.trip}) : super(key: key);

  @override
  State<_BidTripItem> createState() => _BidTripItemState();
}

class _BidTripItemState extends State<_BidTripItem> {
  Timer? _timer;
  late DateTime _expireTime;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateExpiration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void didUpdateWidget(covariant _BidTripItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.myBid?.createdAt != widget.trip.myBid?.createdAt) {
      _calculateExpiration();
    }
  }

  void _calculateExpiration() {
    final createdAtStr = widget.trip.myBid?.createdAt ?? widget.trip.createdAt;
    DateTime createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    
    // Apply 7-hour timezone offset fix if it's in the future
    final now = DateTime.now();
    if (createdAt.isAfter(now.add(const Duration(hours: 1)))) {
      createdAt = createdAt.subtract(const Duration(hours: 7));
    }
    
    _expireTime = createdAt.add(const Duration(minutes: 20));
    _updateRemaining();
  }

  void _updateRemaining() {
    if (mounted) {
      setState(() {
        _remaining = _expireTime.difference(DateTime.now());
      });
    }
  }

  String _toBanglaDigits(String input) {
    const englishToBanglaDigits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };
    return input.split('').map((char) => englishToBanglaDigits[char] ?? char).join();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final myBid = widget.trip.myBid;
    final amount = myBid?.amount ?? widget.trip.customerOfferAmmount;
    final status = myBid?.status ?? widget.trip.tripStatus;
    
    final pickupLoc = widget.trip.pickupLocations.isNotEmpty ? widget.trip.pickupLocations.first : null;
    final dropoffLoc = widget.trip.dropoffLocations.isNotEmpty ? widget.trip.dropoffLocations.first : null;
    
    final pickup = pickupLoc?.address ?? 'Unknown';
    final dropoff = dropoffLoc?.address ?? 'Unknown';

    bool isExpired = _remaining.isNegative;

    if (isExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeController>().removeBidTrip(widget.trip.uuid);
        }
      });
      return const SizedBox.shrink();
    }

    String timeString = "${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}";

    if (isBangla) {
      timeString = _toBanglaDigits(timeString);
    }
    
    final displayAmount = isBangla ? _toBanglaDigits(amount.toString()) : amount.toString();
    final displayStatus = isBangla ? (loc.translate(status?.toLowerCase() ?? '') ?? status ?? '') : (status ?? '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "${loc.translate('my_bid') ?? 'My Bid'}: \৳$displayAmount",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: isExpired ? Colors.red : theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isExpired ? Colors.red : theme.colorScheme.primary, 
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.my_location, size: 12, color: Colors.blue.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TranslatedText(
                      pickup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.9), fontWeight: FontWeight.w500),
                      isBangla: isBangla,
                      location: pickupLoc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 12, color: Colors.red.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TranslatedText(
                      dropoff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.9), fontWeight: FontWeight.w500),
                      isBangla: isBangla,
                      location: dropoffLoc,
                    ),
                  ),
                ],
              ),
              if (widget.trip.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 12, color: Colors.amber[800]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.trip.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12, 
                            color: theme.colorScheme.onSurface.withOpacity(0.85), 
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
