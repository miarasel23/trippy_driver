import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../home/controller/home_controller.dart';
import '../../home/helper/accepted_trip_card_helper.dart';
import '../../home/model/rental_trip_model.dart';
import '../../home/repository/home_repository.dart';
import '../../home/widget/translated_text_widget.dart';
import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';

class BidsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final void Function(int count)? onCountChanged;
  final ValueNotifier<int>? refreshTrigger;

  const BidsScreen({
    super.key,
    this.onNavigateToHome,
    this.onCountChanged,
    this.refreshTrigger,
  });

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
    // Listen for external refresh triggers (e.g. tab tap from NavbarScreen)
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    _fetchBids(showLoading: true);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBids({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await HomeRepository().getDriverRequestedRentalTrips();
    if (mounted && result != null) {
      widget.onCountChanged?.call(result.totalFound);
      setState(() {
        _trips = result.trips;
        _isLoading = false;
      });
    } else if (mounted) {
      widget.onCountChanged?.call(0);
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
    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    final rawServiceUpper = rawService.toUpperCase();
    final isRideShare = rawServiceUpper.contains('RIDE') || rawServiceUpper == 'RIDE_SHARE';
    final totalDuration = isRideShare ? const Duration(minutes: 2) : const Duration(hours: 1);
    final expireTime = createdAt.add(totalDuration);
    var remaining = expireTime.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    final pickupLoc = AcceptedTripCardHelper.getEffectivePickup(trip);
    final dropoffLoc = AcceptedTripCardHelper.getEffectiveDropoff(trip);
    
    final pickup = pickupLoc?.address ?? '';
    final dropoff = dropoffLoc?.address ?? '';
    final bidAmount = trip.myBid?.amount ?? trip.customerOfferAmmount;
    final totalAmount = trip.myBid?.totalAmount ?? bidAmount;
    final currency = isBangla ? '৳' : 'BDT';
    final displayTotalAmount = AcceptedTripCardHelper.translateNumbersAndCommonWords(totalAmount.round().toString(), isBangla);

    final customerName = trip.customer.isNotEmpty && trip.customer.first.name.isNotEmpty 
        ? trip.customer.first.name 
        : loc.translate('customer');
    final customerAvatar = trip.customer.isNotEmpty ? trip.customer.first.profilePicture : '';
    final int totalTrips = trip.customer.isNotEmpty ? trip.customer.first.totalTripComplete : trip.totalTripComplete;
    final String rawRating = trip.customer.isNotEmpty ? trip.customer.first.averageRating.toStringAsFixed(1) : "5.0";
    final String customerRating = totalTrips > 0 
        ? "${AcceptedTripCardHelper.translateNumbersAndCommonWords(rawRating, isBangla)} (${AcceptedTripCardHelper.translateNumbersAndCommonWords(totalTrips.toString(), isBangla)})" 
        : AcceptedTripCardHelper.translateNumbersAndCommonWords(rawRating, isBangla);
    final formattedTotalDistance = AcceptedTripCardHelper.translateNumbersAndCommonWords(AcceptedTripCardHelper.calculateTripDistance(trip), isBangla);

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
      timeStr = AcceptedTripCardHelper.translateNumbersAndCommonWords(timeStr, isBangla);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Header Row: Timer Badge & Service Badge ───────────
          Row(
            children: [
              AcceptedTripCardHelper.buildTimerBadge(timeStr),
              const Spacer(),
              AcceptedTripCardHelper.buildServiceBadge(rawService, hoursBooked: trip.hoursBooked),
            ],
          ),
          const SizedBox(height: 8),

          // ── 2. Accent Divider Line ───────────────────────────────────
          Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD4E157),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // ── 3. Customer Info & Price Row ─────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: customerAvatar.isNotEmpty
                    ? NetworkImage(customerAvatar.startsWith('http') ? customerAvatar : '${AppUrls.imageBaseUrl}$customerAvatar')
                    : null,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: customerAvatar.isEmpty
                    ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 22)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          customerRating,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$currency $displayTotalAmount",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedTotalDistance,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),

          // ── 4. Hourly Booked Time (if applicable) ────────────────────
          if (trip.hoursBooked != null && trip.hoursBooked! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF7B1FA2)),
                const SizedBox(width: 6),
                Text(
                  "${isBangla ? 'বুকিং সময়: ' : 'Booked Time: '}${AcceptedTripCardHelper.translateNumbersAndCommonWords('${trip.hoursBooked}', isBangla)} ${isBangla ? 'ঘণ্টা' : 'Hours'}",
                  style: const TextStyle(
                    color: Color(0xFF7B1FA2),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          // ── 5. Date & Time Row ───────────────────────────────────────
          if (trip.startDatetime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF1E88E5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AcceptedTripCardHelper.formatStartDatetime(trip.startDatetime, isBangla),
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // ── 6. Locations A & B ───────────────────────────────────────
          if (pickup.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcceptedTripCardHelper.buildLocationBadgeA(),
                const SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    pickup,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    isBangla: isBangla,
                    location: pickupLoc,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (dropoff.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AcceptedTripCardHelper.buildLocationBadgeB(),
                const SizedBox(width: 8),
                Expanded(
                  child: TranslatedText(
                    dropoff,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9), fontWeight: FontWeight.w500, fontSize: 13),
                    isBangla: isBangla,
                    location: dropoffLoc,
                  ),
                ),
              ],
            ),
          ],

          if (trip.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.note,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── 7. View Other Bidders Button (if any) ────────────────────
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
                  padding: const EdgeInsets.only(bottom: 8),
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
                        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                        side: BorderSide(
                          color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.4),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],

          // ── 8. Preview on Map Button ─────────────────────────────────
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
                backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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

    final myBidAmount = trip.myBid?.amount ?? trip.customerOfferAmmount;
    final myBidStr = isBangla
        ? _toBanglaDigits(myBidAmount.round().toString())
        : myBidAmount.round().toString();

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
                      color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      size: 20,
                    ),
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
              // My Bid highlighted card at the top of the bidders list
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBangla ? "আপনার বিড (My Bid)" : "Your Bid (My Bid)",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$currency $myBidStr",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                                color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
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
                                color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                "$currency $amtStr",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
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
