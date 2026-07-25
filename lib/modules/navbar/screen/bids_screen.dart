import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../home/controller/home_controller.dart';
import '../../home/helper/accepted_trip_card_helper.dart';
import '../../home/model/rental_trip_model.dart';
import '../../home/repository/home_repository.dart';
import '../../home/widget/translated_text.dart';
import '../../../store/user_data_store.dart';

class BidsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;

  const BidsScreen({super.key, this.onNavigateToHome});

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  List<RentalTripModel> _trips = [];
  bool _isLoading = true;
  Timer? _timer;
  int _secondsCounter = 0;

  @override
  void initState() {
    super.initState();
    _fetchBids(showLoading: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _secondsCounter++;
        if (_secondsCounter % 15 == 0) {
          _fetchBids(showLoading: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBids({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final fetched = await HomeRepository().getDriverRequestedRentalTrips();
    if (mounted && fetched != null) {
      setState(() {
        _trips = fetched;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _toBanglaDigits(String input) {
    const englishToBanglaDigits = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯',
    };
    return input
        .split('')
        .map((char) => englishToBanglaDigits[char] ?? char)
        .join();
  }

  List<RentalTripModel> _getFilteredTrips() {
    final now = AcceptedTripCardHelper.getNow();
    return _trips.where((t) {
      // Exclude RIDE_SHARE (only show rental car trips)
      final rawService =
          t.serviceName.isNotEmpty ? t.serviceName : t.carService.serviceName;
      final isRideShare = rawService.toUpperCase().contains('RIDE') ||
          rawService.toUpperCase() == 'RIDE_SHARE';
      if (isRideShare) return false;

      // Only show REQUESTED trips waiting for customer acceptance
      final status = t.myBid?.status.isNotEmpty == true ? t.myBid!.status : t.tripStatus;
      if (status.toUpperCase() != 'REQUESTED') return false;

      // Calculate 1 hour expiration from creation / bid time
      final createdAtStr = t.myBid?.createdAt ?? t.createdAt;
      final createdAt = AcceptedTripCardHelper.parseCreatedAt(createdAtStr);
      final expireTime = createdAt.add(const Duration(hours: 1));

      // Only show active bids waiting for acceptance within the 1-hour window
      if (now.isAfter(expireTime)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final filteredTrips = _getFilteredTrips();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          loc.translate('nav_bids'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchBids(showLoading: true),
            tooltip: 'Refresh Bids',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchBids(showLoading: true),
              child: filteredTrips.isEmpty
                  ? _buildEmptyState(theme, loc)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 100, left: 16, right: 16),
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
                        return _buildBidCard(context, trip, theme, loc, isBangla);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations loc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.car_rental,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                loc.translate('no_active_bids'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBidCard(BuildContext context, RentalTripModel trip,
      ThemeData theme, AppLocalizations loc, bool isBangla) {
    final now = AcceptedTripCardHelper.getNow();
    final createdAtStr = trip.myBid?.createdAt ?? trip.createdAt;
    final createdAt = AcceptedTripCardHelper.parseCreatedAt(createdAtStr);
    final expireTime = createdAt.add(const Duration(hours: 1));
    var remaining = expireTime.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    String timeString =
        "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
    if (isBangla) {
      timeString = _toBanglaDigits(timeString);
    }

    final Color timerColor = remaining.inMinutes < 10
        ? Colors.redAccent
        : (remaining.inMinutes < 30 ? Colors.orange : Colors.green);

    final pickupLoc = AcceptedTripCardHelper.getEffectivePickup(trip);
    final dropoffLoc = AcceptedTripCardHelper.getEffectiveDropoff(trip);

    final pickup = pickupLoc?.address ?? 'Unknown';
    final dropoff = dropoffLoc?.address ?? 'Unknown';

    final customerOffer = trip.customerOfferAmmount;
    final myBid = trip.myBid?.amount ?? customerOffer;
    final currency = isBangla ? '৳' : 'BDT';

    final displayCustomerOffer = isBangla
        ? _toBanglaDigits(customerOffer.round().toString())
        : customerOffer.round().toString();
    final displayMyBid = isBangla
        ? _toBanglaDigits(myBid.round().toString())
        : myBid.round().toString();

    String headerTitle = loc.translate('wait_customer_acceptance');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status title + 1 Hour Counting Timer Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_rounded,
                          color: Colors.orange, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headerTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: timerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: timerColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_bottom_rounded,
                        size: 14, color: timerColor),
                    const SizedBox(width: 5),
                    Text(
                      timeString,
                      style: TextStyle(
                        color: timerColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1 Hour Progress Indicator (3600 seconds)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (remaining.inSeconds / 3600.0).clamp(0.0, 1.0),
              backgroundColor: timerColor.withOpacity(0.12),
              color: timerColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Service Name Badge (with HOURLY hours_booked if applicable)
          Builder(
            builder: (context) {
              final rawService = trip.serviceName.isNotEmpty
                  ? trip.serviceName
                  : trip.carService.serviceName;
              if (rawService.isEmpty) return const SizedBox.shrink();
              String serviceLabel = rawService.replaceAll('_', ' ').toUpperCase();
              if (rawService.toUpperCase() == 'HOURLY' && trip.hoursBooked != null) {
                final hrsText = isBangla ? _toBanglaDigits("${trip.hoursBooked}") : "${trip.hoursBooked}";
                serviceLabel = "$serviceLabel ($hrsText ${isBangla ? 'ঘণ্টা' : 'HOURS'})";
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car_rounded,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            serviceLabel,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Trip Dates & Times
          AcceptedTripCardHelper.buildTripDateTimes(
              context, trip, isBangla, theme),

          // Pickup Location
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location,
                    size: 14, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TranslatedText(
                  pickup,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14.5),
                  isBangla: isBangla,
                  location: pickupLoc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropoff Location
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on,
                    size: 14, color: Colors.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TranslatedText(
                  dropoff,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  isBangla: isBangla,
                  location: dropoffLoc,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),

          // Pricing Comparison Row (Customer Offer vs Your Bid)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        loc.translate('customer_offer'),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$currency $displayCustomerOffer",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        loc.translate('my_bid'),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$currency $displayMyBid",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // View Other Bidders Button
          if (trip.bidDetails.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final currentUuid = UserDataStore.uuid;
                final otherBids = trip.bidDetails.where((b) {
                  if (currentUuid != null && currentUuid.isNotEmpty) {
                    return b.driverUuid != currentUuid && b.uuid != trip.myBid?.uuid;
                  }
                  return b.uuid != trip.myBid?.uuid;
                }).toList();
                final countStr = isBangla ? _toBanglaDigits(otherBids.length.toString()) : otherBids.length.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showOtherBidders(context, trip, isBangla, currency),
                      icon: const Icon(Icons.people_alt_rounded, size: 18),
                      label: Text(
                        isBangla
                            ? "অন্যান্য বিডারদের তালিকা ($countStr)"
                            : "Other Bidders List ($countStr)",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          // Preview on Map Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<HomeController>().selectTripForPreview(trip);
                widget.onNavigateToHome?.call();
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: Text(
                loc.translate('view_on_map'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtherBidders(BuildContext context, RentalTripModel trip, bool isBangla, String currency) {
    final theme = Theme.of(context);
    final currentUuid = UserDataStore.uuid;
    var otherBids = trip.bidDetails.where((b) {
      if (currentUuid != null && currentUuid.isNotEmpty) {
        return b.driverUuid != currentUuid && b.uuid != trip.myBid?.uuid;
      }
      return b.uuid != trip.myBid?.uuid;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isBangla ? "অন্যান্য বিডারদের তালিকা" : "Other Bidders List",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isBangla ? "এই ট্রিপের জন্য অন্যান্য চালকদের দেওয়া বিড অ্যামাউন্ট:" : "Bid amounts submitted by other drivers for this trip:",
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (otherBids.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 36, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 10),
                      Text(
                        isBangla ? "এখনও অন্য কোনো বিডার বিড করেনি" : "No other drivers have bidded yet",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: otherBids.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final b = otherBids[index];
                      final amtStr = isBangla
                          ? _toBanglaDigits(b.bidAmount.round().toString())
                          : b.bidAmount.round().toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_outline_rounded, size: 18, color: theme.colorScheme.secondary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isBangla ? "বিডার #${_toBanglaDigits((index + 1).toString())}" : "Bidder #${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ),
                              child: Text(
                                "$currency $amtStr",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
