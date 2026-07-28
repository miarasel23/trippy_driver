import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../home/controller/home_controller.dart';
import '../../home/helper/accepted_trip_card_helper.dart';
import '../../home/model/rental_trip_model.dart';
import '../../home/repository/home_repository.dart';

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
      });
    }

    final result = await HomeRepository().getHistoryTrips();
    if (mounted) {
      widget.onCountChanged?.call(result?.totalAcceptedCount ?? 0);
      setState(() {
        _trips = result?.trips ?? [];
        _isLoading = false;
      });
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
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: theme.colorScheme.primary,
            tabs: [
              Tab(text: loc.translate('accepted')),
              Tab(text: loc.translate('completed')),
              Tab(text: loc.translate('cancelled')),
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
            : TabBarView(
                children: [
                  _buildHistoryList('ACCEPTED', theme, loc, isBangla),
                  _buildHistoryList('COMPLETED', theme, loc, isBangla),
                  _buildHistoryList('CANCELLED', theme, loc, isBangla),
                ],
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
              itemCount: filteredTrips.length,
              itemBuilder: (context, index) {
                final trip = filteredTrips[index];
                return _buildTripCard(context, trip, theme, loc, isBangla, status);
              },
            ),
    );
  }

  Widget _buildTripCard(BuildContext context, RentalTripModel trip, ThemeData theme, AppLocalizations loc, bool isBangla, String status) {
    final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
    final isRideShare = rawService.toUpperCase().contains('RIDE') || rawService.toUpperCase() == 'RIDE_SHARE';

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
          AcceptedTripCardHelper.buildUnifiedTripCardContent(
            context: context,
            trip: trip,
            isBangla: isBangla,
            theme: theme,
            loc: loc,
            remaining: Duration.zero,
            isRideShare: isRideShare,
            isMyBid: true,
            showTimer: false,
          ),
          if (status == 'ACCEPTED') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<HomeController>().selectTripForPreview(trip);
                  widget.onNavigateToHome?.call();
                },
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: Text(
                  loc.translate('details') ?? 'Details',
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
        ],
      ),
    );
  }
}
