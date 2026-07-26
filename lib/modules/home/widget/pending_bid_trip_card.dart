import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import '../helper/accepted_trip_card_helper.dart';
import '../../../../store/app_globals.dart';

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

  DateTime _getNow() {
    if (AppGlobals.countryCode.toUpperCase() == 'BD') {
      final utc = DateTime.now().toUtc().add(const Duration(hours: 6));
      return DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second, utc.millisecond, utc.microsecond);
    }
    return DateTime.now();
  }

  DateTime _parseCreatedAt(String createdAtStr) {
    final now = _getNow();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {

        if (!state.isOnline) return const SizedBox.shrink();

        final now = _getNow();
        final pendingTrips = state.bidTrips.where((t) {
          // Must have placed a bid and status is still pending (not ACCEPTED or CANCELLED)
          if (t.myBid == null) return false;
          
          final tripStatus = t.tripStatus.toUpperCase();
          if (tripStatus == 'ACCEPTED' || tripStatus == 'RIDE_STARTED' || tripStatus == 'FIRST_COMPLETED' || tripStatus == 'IN_PROGRESS' || tripStatus == 'COMPLETED') {
            return false;
          }
          
          final bidStatus = t.myBid!.status.toUpperCase();
          if (bidStatus == 'ACCEPTED' || bidStatus == 'CANCELLED') return false;
          
          final createdAtStr = t.myBid?.createdAt ?? t.createdAt;
          final createdAt = _parseCreatedAt(createdAtStr);
          final rawService = t.serviceName.isNotEmpty ? t.serviceName : t.carService.serviceName;
          final isRideShare = rawService.toUpperCase().contains('RIDE') || rawService.toUpperCase() == 'RIDE_SHARE';
          if (!isRideShare) return false;
          final totalDuration = isRideShare ? const Duration(minutes: 1) : const Duration(hours: 1);
          
          final expireTime = createdAt.add(totalDuration);
          if (now.isAfter(expireTime)) {
            return false;
          }
          
          return true;
        }).toList();


        if (pendingTrips.isEmpty) return const SizedBox.shrink();

        final trip = pendingTrips.first;
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);
        final isBangla = Localizations.localeOf(context).languageCode == 'bn';

        final createdAtStr = trip.myBid?.createdAt ?? trip.createdAt;
        final createdAt = _parseCreatedAt(createdAtStr);
        final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
        final isRideShare = rawService.toUpperCase().contains('RIDE') || rawService.toUpperCase() == 'RIDE_SHARE';
        final totalDuration = isRideShare ? const Duration(minutes: 1) : const Duration(hours: 1);

        final expireTime = createdAt.add(totalDuration);
        var remaining = expireTime.difference(_getNow());
        if (remaining.isNegative) remaining = Duration.zero;

        return GestureDetector(
          onTap: () {
            context.read<HomeController>().selectTripForPreview(trip);
          },
          child: Container(
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
            child: AcceptedTripCardHelper.buildUnifiedTripCardContent(
              context: context,
              trip: trip,
              isBangla: isBangla,
              theme: theme,
              loc: loc,
              remaining: remaining,
              isRideShare: isRideShare,
              isMyBid: true,
            ),
          ),
        );
      },
    );
  }
}
