import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../home/controller/home_controller.dart';
import '../../home/helper/accepted_trip_card_helper.dart';
import '../../home/model/rental_trip_model.dart';
import '../../home/repository/home_repository.dart';

import '../../../utils/app_urls.dart';
import '../../home/widget/translated_text_widget.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final void Function(int count)? onCountChanged;
  final ValueNotifier<int>? refreshTrigger;

  const HistoryScreen({super.key, this.onNavigateToHome, this.onCountChanged, this.refreshTrigger});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RentalTripModel> _trips = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory(showLoading: true);
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  void _onRefreshTriggered() {
    _fetchHistory(showLoading: true);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  Future<void> _fetchHistory({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    final result = await HomeRepository().getHistoryTrips(page: 1);
    if (mounted) {
      widget.onCountChanged?.call(result?.totalAcceptedCount ?? 0);
      setState(() {
        _trips = result?.trips ?? [];
        _isLoading = false;
        if ((result?.trips.length ?? 0) < 15) {
          _hasMoreData = false;
        }
      });
    }
  }

  Future<void> _fetchMoreHistory() async {
    setState(() {
      _isFetchingMore = true;
    });

    final nextPage = _currentPage + 1;
    final result = await HomeRepository().getHistoryTrips(page: nextPage);
    
    if (mounted) {
      if (result != null && result.trips.isNotEmpty) {
        setState(() {
          _trips.addAll(result.trips);
          _currentPage = nextPage;
          if (result.trips.length < 15) {
            _hasMoreData = false;
          }
          _isFetchingMore = false;
        });
      } else {
        setState(() {
          _hasMoreData = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  List<RentalTripModel> _filterTripsByStatus(String status) {
    return _trips.where((t) {
      final tripStatus = t.tripStatus.toUpperCase();
      final bidStatus = t.myBid?.status.toUpperCase() ?? '';
      
      if (status == 'ACCEPTED') {
        return tripStatus == 'ACCEPTED' || bidStatus == 'ACCEPTED' || tripStatus == 'RIDE_STARTED' || tripStatus == 'IN_PROGRESS' || tripStatus == 'FIRST_COMPLETED';
      } else if (status == 'COMPLETED') {
        return tripStatus == 'COMPLETED' || bidStatus == 'COMPLETED';
      } else if (status == 'CANCELLED') {
        return tripStatus == 'CANCELLED' || bidStatus == 'CANCELLED' || bidStatus == 'REJECTED' || tripStatus == 'REJECTED';
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            loc.translate('nav_history'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          bottom: TabBar(
            labelColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.45),
            indicatorColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                text: loc.translate('accepted'),
              ),
              Tab(
                icon: const Icon(Icons.task_alt_rounded, size: 20),
                text: loc.translate('completed'),
              ),
              Tab(
                icon: const Icon(Icons.cancel_outlined, size: 20),
                text: loc.translate('cancelled'),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _fetchHistory(showLoading: true),
              tooltip: 'Refresh History',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                    if (!_isFetchingMore && _hasMoreData && !_isLoading) {
                      _fetchMoreHistory();
                    }
                  }
                  return false;
                },
                child: TabBarView(
                  children: [
                    _buildHistoryList('ACCEPTED', theme, loc, isBangla),
                    _buildHistoryList('COMPLETED', theme, loc, isBangla),
                    _buildHistoryList('CANCELLED', theme, loc, isBangla),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHistoryList(String status, ThemeData theme, AppLocalizations loc, bool isBangla) {
    final filteredTrips = _filterTripsByStatus(status);
    
    String emptyMessage = '';
    if (status == 'ACCEPTED') {
      emptyMessage = loc.translate('no_accepted_trips');
    } else if (status == 'COMPLETED') {
      emptyMessage = loc.translate('no_completed_trips');
    } else if (status == 'CANCELLED') {
      emptyMessage = loc.translate('no_cancelled_trips');
    }

    return RefreshIndicator(
      onRefresh: () => _fetchHistory(showLoading: true),
      child: filteredTrips.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        emptyMessage,
                        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 100, left: 16, right: 16),
              itemCount: filteredTrips.length + (_isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredTrips.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final trip = filteredTrips[index];
                return _buildTripCard(context, trip, theme, loc, isBangla, status);
              },
            ),
    );
  }

  Widget _buildTripCard(BuildContext context, RentalTripModel trip, ThemeData theme, AppLocalizations loc, bool isBangla, String status) {
    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    final rawServiceUpper = rawService.toUpperCase();
    final isRideShare = rawServiceUpper.contains('RIDE') || rawServiceUpper == 'RIDE_SHARE';

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

    // Calculate timer if status is ACCEPTED
    Duration remaining = Duration.zero;
    bool showTimer = false;
    if (status == 'ACCEPTED') {
      try {
        final createdAt = AcceptedTripCardHelper.parseCreatedAt(trip.myBid?.createdAt ?? trip.createdAt);
        final totalDuration = isRideShare ? const Duration(minutes: 2) : const Duration(hours: 1);
        final expireTime = createdAt.add(totalDuration);
        final now = AcceptedTripCardHelper.getNow();
        if (expireTime.isAfter(now)) {
          remaining = expireTime.difference(now);
          showTimer = true;
        }
      } catch (_) {}
    }

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

    // Top Left Badge
    Widget topLeftBadge;
    if (showTimer) {
      topLeftBadge = AcceptedTripCardHelper.buildTimerBadge(timeStr);
    } else if (status == 'COMPLETED') {
      topLeftBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 15),
            const SizedBox(width: 4),
            Text(
              loc.translate('completed'),
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'CANCELLED') {
      topLeftBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel_rounded, color: Color(0xFFC62828), size: 15),
            const SizedBox(width: 4),
            Text(
              loc.translate('cancelled'),
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      topLeftBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 15),
            const SizedBox(width: 4),
            Text(
              loc.translate('accepted'),
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
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
          // ── 1. Top Header Row: Status/Timer Badge & Service Badge ────
          Row(
            children: [
              topLeftBadge,
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

          AcceptedTripCardHelper.buildAllLocationRows(
            context: context,
            trip: trip,
            isBangla: isBangla,
            theme: theme,
          ),

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

          // ── 7. Details Button for ACCEPTED status ────────────────────
          if (status == 'ACCEPTED') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<HomeController>().selectTripForPreview(trip);
                  widget.onNavigateToHome?.call();
                },
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: Text(
                  loc.translate('details'),
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
        ],
      ),
    );
  }
}
