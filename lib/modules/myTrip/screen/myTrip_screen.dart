import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/app_urls.dart';
import '../../../store/user_data_store.dart';
import '../../../routes/app_routes.dart';
import '../controller/my_trip_bloc.dart';
import '../controller/my_trip_event.dart';
import '../controller/my_trip_state.dart';
import '../../dashboard/model/create_rental_trip_model.dart';
import '../../../main.dart';
import '../../../widgets/cancel_trip_dialog.dart';
import '../../dashboard/repository/create_trip_repository.dart';

class MytripScreen extends StatefulWidget {
  const MytripScreen({super.key});

  @override
  State<MytripScreen> createState() => _MytripScreenState();
}

class _MytripScreenState extends State<MytripScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentTab(isSilent: false);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchCurrentTab(isSilent: true);
    });
  }

  void _fetchCurrentTab({bool isSilent = true}) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    final index = context.read<MyTripBloc>().state.selectedIndex;

    final statusMap = {0: "REQUESTED", 1: "ACCEPTED", 2: "ALL"};
    final tripStatus = statusMap[index] ?? "REQUESTED";

    context.read<MyTripBloc>().add(
      FetchTripsEvent(tripStatus: tripStatus, languageCode: loc.locale.languageCode, isSilent: isSilent),
    );
  }

  Future<void> _cancelTrip(BuildContext context, bool isDark, String tripUuid) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelTripDialog(isDark: isDark),
    );

    if (reason != null && reason.isNotEmpty) {
      final bgColor = isDark ? Colors.white : Colors.black;
      final textColor = isDark ? Colors.black : Colors.white;
      try {
        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("Cancelling trip...", style: TextStyle(color: textColor)), 
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating
          ),
        );
        final loc = AppLocalizations.of(context);
        final repo = CreateTripRepository();
        final response = await repo.cancelTrip(
          tripUuid: tripUuid,
          comment: reason,
          langCode: loc.locale.languageCode,
        );

        globalScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Trip cancelled successfully", style: TextStyle(color: textColor)),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Refresh the list immediately
        _fetchCurrentTab(isSilent: false);
      } catch (e) {
        globalScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: TextStyle(color: textColor)),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("my_trip"),
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<MyTripBloc, MyTripState>(
        builder: (context, state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSegmentedControl(context, state.selectedIndex, loc),
              Expanded(
                child: switch (state.selectedIndex) {
                  0 => _buildTripsList(context, state, state.requestedTrips, loc, isAccepted: false, isHistory: false),
                  1 => _buildTripsList(context, state, state.acceptedTrips, loc, isAccepted: true, isHistory: false),
                  2 => _buildTripsList(
                      context,
                      state,
                      state.historyTrips.where((trip) => trip.tripStatus == 'COMPLETED' || trip.tripStatus == 'CANCELLED').toList(),
                      loc,
                      isAccepted: false,
                      isHistory: true),
                  _ => SizedBox.shrink(),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context, int selectedIndex, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeBgColor = isDark ? Colors.white : Colors.black;
    final activeTextColor = isDark ? Colors.black : Colors.white;
    final inactiveTextColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252833) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildTab(context, loc.translate("requested"), 0, selectedIndex, activeBgColor, activeTextColor, inactiveTextColor),
          _buildTab(context, loc.translate("accepted"), 1, selectedIndex, activeBgColor, activeTextColor, inactiveTextColor),
          _buildTab(context, loc.translate("history"), 2, selectedIndex, activeBgColor, activeTextColor, inactiveTextColor),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String text, int index, int selectedIndex, Color activeBgColor, Color activeTextColor, Color inactiveTextColor) {
    final isActive = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<MyTripBloc>().add(ChangePackageEvent(index: index));
          if (!mounted) return;
          final loc = AppLocalizations.of(context);
          final statusMap = {0: "REQUESTED", 1: "ACCEPTED", 2: "ALL"};
          final tripStatus = statusMap[index] ?? "REQUESTED";
          context.read<MyTripBloc>().add(
            FetchTripsEvent(tripStatus: tripStatus, languageCode: loc.locale.languageCode, isSilent: false),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: isActive ? activeTextColor : inactiveTextColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, MyTripState state, List<RentalTrip> trips, AppLocalizations loc, {bool isAccepted = false, bool isHistory = false}) {
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage.isNotEmpty) {
      return Center(
        child: Text(state.errorMessage, style: TextStyle(color: Colors.red)),
      );
    }

    if (trips.isEmpty) {
      return _buildEmptyState(context, "No trips found");
    }

    return ListView.builder(
      padding: EdgeInsets.all(18),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildTripCard(context, trip, loc, isAccepted: isAccepted, isHistory: isHistory),
        );
      },
    );
  }

  Widget _buildTripCard(BuildContext context, RentalTrip trip, AppLocalizations loc, {bool isAccepted = false, bool isHistory = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeBgColor = isDark ? Colors.white : Colors.black;
    final activeTextColor = isDark ? Colors.black : Colors.white;

    final String currencySymbol = loc.locale.languageCode == 'bn' ? '৳' : 'BDT ';

    final String serviceNameRaw = trip.serviceName ?? "Ride Share";
    final String serviceName = serviceNameRaw.replaceAll('_', ' ');
    final String carType = trip.carCategory?.carType ?? "Car";
    final String carAvatar = trip.carCategory?.carAvatar ?? "";
    
    double price = trip.offerAmount ?? 0.0;
    double? discountAmount;

    RentalDriverBid? driver;
    if ((isAccepted || isHistory) && trip.drivers.isNotEmpty) {
      final acceptedDriverIdx = trip.drivers.indexWhere((d) => d.bidStatus == "ACCEPTED" || d.bidStatus == "COMPLETED");
      driver = acceptedDriverIdx >= 0 ? trip.drivers[acceptedDriverIdx] : trip.drivers.first;
      
      price = driver.totalAmount ?? price;
      discountAmount = driver.customerDiscountAmount;
    }

    final int bidsCount = trip.totalBids ?? 0;
    final bool hasBids = bidsCount > 0;
    
    final pickup = trip.pickupLocations.isNotEmpty ? trip.pickupLocations.first.address ?? "Pickup Location" : "Pickup Location";
    final dropoff = trip.dropoffLocations.isNotEmpty ? trip.dropoffLocations.first.address ?? "Drop-off Location" : "Drop-off Location";

    String statusText = "";
    Color statusColor = Colors.grey;
    if (isHistory) {
       statusText = trip.tripStatus?.replaceAll('_', ' ') ?? "UNKNOWN";
       if (trip.tripStatus == 'COMPLETED') statusColor = Colors.green;
       else if (trip.tripStatus == 'CANCELLED') statusColor = Colors.red;
       else statusColor = Color(0xFF2F66F6);
    } else if (isAccepted) {
       statusText = loc.translate("accepted");
       statusColor = Colors.green;
    } else if (hasBids) {
       statusText = loc.translate("pending_bids");
       statusColor = Colors.grey;
    } else {
       statusText = loc.translate("searching");
       statusColor = Color(0xFF2F66F6);
    }

    final bool canCancel = trip.tripStatus != 'COMPLETED' && trip.tripStatus != 'CANCELLED' && trip.tripStatus != 'NO_SHOW';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                width: 52,
                height: 52,
                child: (carAvatar.isNotEmpty && AppUrls.getImageUrl(carAvatar) != null)
                  ? Image.network(AppUrls.getImageUrl(carAvatar)!, fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car_outlined, color: isDark ? Colors.white : Color(0xFF2F66F6), size: 28))
                  : Icon(Icons.directions_car_outlined, color: isDark ? Colors.white : Color(0xFF2F66F6), size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      carType,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
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
                    loc.translate("est_price"),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (discountAmount != null && discountAmount > 0.0)
                    Text(
                      "$currencySymbol${(price + discountAmount).toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    "$currencySymbol${price.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (discountAmount != null && discountAmount > 0.0)
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Discount $currencySymbol${discountAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  // Show bids count only on Requested tab, and only when there are actual bids
                  if (!isAccepted && !isHistory && bidsCount > 0)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFF2F66F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "$bidsCount Bids",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F66F6),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTimeline(context, pickup, dropoff, loc),
          SizedBox(height: 16),
          
          if (driver != null) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF252833) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: (driver.profilePicture != null && AppUrls.getImageUrl(driver.profilePicture) != null)
                        ? NetworkImage(AppUrls.getImageUrl(driver.profilePicture)!)
                        : null,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    child: (driver.profilePicture == null || AppUrls.getImageUrl(driver.profilePicture) == null)
                        ? Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black54)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name ?? "N/A",
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          driver.carRegNumber ?? "N/A",
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          if (hasBids && !isHistory)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final customerUuid = UserDataStore.userData?.data?.user?.uuid ?? "";
                  Navigator.pushNamed(context, AppRoutes.biddingScreen, arguments: {
                    'customerUuid': customerUuid,
                    'tripUuid': trip.uuid ?? "",
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeBgColor,
                  foregroundColor: activeTextColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.translate("view_bids"), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            )
          else if (!isHistory || canCancel)
            Row(
              children: [
                if (!isHistory)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final customerUuid = UserDataStore.userData?.data?.user?.uuid ?? "";
                        if (isAccepted || isHistory) {
                          Navigator.pushNamed(context, AppRoutes.activeTrip, arguments: customerUuid);
                        } else {
                          Navigator.pushNamed(context, AppRoutes.biddingScreen, arguments: {
                            'customerUuid': customerUuid,
                            'tripUuid': trip.uuid ?? "",
                          });
                        }
                      },
                      icon: Icon(Icons.visibility_outlined, size: 18, color: activeTextColor),
                      label: Text(loc.translate("view"), style: GoogleFonts.poppins(color: activeTextColor)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeBgColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (canCancel) ...[
                  if (!isHistory) SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _cancelTrip(context, isDark, trip.uuid ?? "");
                      },
                      icon: Icon(Icons.close, size: 18, color: activeTextColor),
                      label: Text(loc.translate("cancel"), style: GoogleFonts.poppins(color: activeTextColor)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeBgColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            )
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, String pickup, String dropoff, AppLocalizations loc) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boxHeight = constraints.constrainHeight();
                        if (boxHeight <= 0) return SizedBox.shrink();
                        final dashHeight = 4.0;
                        final dashWidth = 1.0;
                        final dashCount = (boxHeight / (2 * dashHeight)).floor();
                        return Flex(
                          children: List.generate(dashCount, (_) {
                            return SizedBox(
                              width: dashWidth,
                              height: dashHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.grey.shade400),
                              ),
                            );
                          }),
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          direction: Axis.vertical,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(0xFF2F66F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate("pickup"),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      pickup,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate("drop_off"),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      dropoff,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
