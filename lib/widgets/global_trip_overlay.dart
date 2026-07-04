import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/dashboard/model/create_rental_trip_model.dart';
import '../modules/dashboard/model/trip_status.dart';
import '../modules/dashboard/repository/create_trip_repository.dart';
import '../store/user_data_store.dart';
import '../core/utils/localization/app_localization.dart';
import '../utils/app_colors.dart';
import '../utils/app_urls.dart';
import '../routes/app_routes.dart';
import '../main.dart';

class GlobalTripOverlay extends StatefulWidget {
  final Widget child;

  const GlobalTripOverlay({super.key, required this.child});

  @override
  State<GlobalTripOverlay> createState() => _GlobalTripOverlayState();
}

class _GlobalTripOverlayState extends State<GlobalTripOverlay> {
  final CreateTripRepository _repo = CreateTripRepository();
  RentalTrip? _activeTrip;
  RentalTrip? _requestedTrip;
  Timer? _pollingTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
    globalRouteObserver.routeNotifier.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    globalRouteObserver.routeNotifier.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  void _startPolling() {
    _fetchActiveTrip(); // Initial fetch
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchActiveTrip();
    });
  }

  Future<void> _fetchActiveTrip() async {
    String? token = UserDataStore.accessToken;
    if (token == null || token.isEmpty) {
      // Check SharedPreferences directly to prevent race condition on app startup
      token = await UserDataStore.getAccessToken();
    }

    if (token == null || token.isEmpty) {
      final currentRoute = globalRouteObserver.currentRoute;
      if (currentRoute != null && 
          currentRoute != AppRoutes.splash && 
          currentRoute != AppRoutes.numberInput && 
          currentRoute != AppRoutes.otp) {
        UserDataStore.clearAllData();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.numberInput, (route) => false);
        }
      }
      return;
    }

    final customerUuid = UserDataStore.userData?.data?.user?.uuid;
    if (customerUuid == null || customerUuid.isEmpty) return;

    try {
      final loc = AppLocalizations.of(context);
      final langCode = loc.locale.languageCode;
      
      final activeFuture = _repo.fetchBids(
        customerUuid: customerUuid,
        langCode: langCode,
        tripStatus: TripStatus.all,
      );
      
      final requestedFuture = _repo.fetchBids(
        customerUuid: customerUuid,
        langCode: langCode,
        tripStatus: TripStatus.requested,
      );

      final results = await Future.wait([activeFuture, requestedFuture]);
      final activeResponse = results[0];
      final requestedResponse = results[1];

      if (mounted) {
        setState(() {
          if (activeResponse.trips.isNotEmpty) {
            // BUG FIX: Search for an active trip by status rather than blindly taking first
            final activeStatuses = [
              TripStatus.rideStarted,
              TripStatus.firstCompleted,
            ];
            final found = activeResponse.trips.where((t) => activeStatuses.contains(t.tripStatus)).toList();
            _activeTrip = found.isNotEmpty ? found.first : null;
          } else {
            _activeTrip = null;
          }

          if (requestedResponse.trips.isNotEmpty) {
            _requestedTrip = requestedResponse.trips.first;
          } else {
            _requestedTrip = null;
          }
        });
      }
    } catch (e) {
      // Silently ignore polling errors
    }
  }

  String _translate(String key, {Map<String, String>? args}) {
    final loc = AppLocalizations.of(context);
    String val = loc.translate(key);
    if (val == key) {
      if (key == 'overlay_finding_driver') return 'Finding your driver...';
      if (key == 'overlay_total_bids') return 'Total Bids: ${args?['count']}';
      if (key == 'overlay_lowest_bid') return 'Lowest Bid: ${args?['amount']} BDT';
      if (key == 'overlay_highest_bid') return 'Highest Bid: ${args?['amount']} BDT';
      if (key == 'overlay_your_offer') return 'Your Offer: ${args?['amount']} BDT';
      if (key == 'overlay_no_bids') return 'Waiting for bids...';
      return key;
    }
    if (args != null) {
      args.forEach((k, v) {
        val = val.replaceAll('{$k}', v);
      });
    }
    return val;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(dateStr);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final amPm = dt.hour >= 12 ? "PM" : "AM";
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      return "${dt.day} ${months[dt.month - 1]}, ${dt.year} - $hour12:$minute $amPm";
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getVehicleIcon(String? carType) {
    if (carType == null) return Icons.directions_car;
    final lower = carType.toLowerCase();
    if (lower.contains('bike') || lower.contains('motor')) {
      return Icons.motorcycle;
    } else if (lower.contains('cng') || lower.contains('auto')) {
      return Icons.electric_rickshaw;
    } else if (lower.contains('micro') || lower.contains('van') || lower.contains('bus')) {
      return Icons.airport_shuttle;
    }
    return Icons.directions_car;
  }

  Widget _buildBiddingOverlayContent(BuildContext context) {
    final trip = _requestedTrip!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);


    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () async {
          final customerUuid = UserDataStore.userData?.data?.user?.uuid;
          if (customerUuid != null) {
            final result = await globalNavigatorKey.currentState?.pushNamed(
              AppRoutes.biddingScreen,
              arguments: {
                'customerUuid': customerUuid,
                'tripUuid': trip.uuid ?? "",
              },
            );
            if (result == true && mounted) {
              setState(() { _requestedTrip = null; });
              _fetchActiveTrip();
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E26) : Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 24,
                      child: _AnimatedVehicleIcon(
                        iconData: _getVehicleIcon(trip.carCategory?.carType),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translate('overlay_finding_driver'),
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            trip.serviceName?.replaceAll('_', ' ') ?? "CAR RENTAL",
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final customerUuid = UserDataStore.userData?.data?.user?.uuid;
                        if (customerUuid != null) {
                          final result = await globalNavigatorKey.currentState?.pushNamed(
                            AppRoutes.biddingScreen,
                            arguments: {
                              'customerUuid': customerUuid,
                              'tripUuid': trip.uuid ?? "",
                            },
                          );
                          if (result == true && mounted) {
                            setState(() { _requestedTrip = null; });
                            _fetchActiveTrip();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        loc.translate('view_bids') == 'view_bids' ? "View Bids" : loc.translate('view_bids'),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.black : Colors.white),
                      ),
                    ),
                  ],
                ),
               
                if (trip.drivers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF13151B) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      itemCount: trip.drivers.length,
                      separatorBuilder: (context, index) => Divider(color: isDark ? Colors.white10 : Colors.grey.shade300, height: 24),
                      itemBuilder: (context, index) {
                        final driver = trip.drivers[index];
                        final currency = loc.locale.languageCode == 'bn' ? '৳' : 'BDT';
                        return Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isDark ? Colors.white24 : Colors.black12,
                              radius: 18,
                              backgroundImage: (driver.profilePicture != null && AppUrls.getImageUrl(driver.profilePicture) != null)
                                  ? NetworkImage(AppUrls.getImageUrl(driver.profilePicture)!)
                                  : null,
                              child: (driver.profilePicture == null || AppUrls.getImageUrl(driver.profilePicture) == null)
                                  ? Icon(Icons.person, color: isDark ? Colors.white : Colors.black, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.name?.toUpperCase() ?? "Driver",
                                    style: GoogleFonts.poppins(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        driver.averageRating?.toStringAsFixed(1) ?? '0.0',
                                        style: GoogleFonts.poppins(
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "$currency ${driver.totalAmount?.toStringAsFixed(0) ?? '0'}",
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Determine current route name, preferring the ModalRoute (available immediately) and falling back to the observer
    final routeName = ModalRoute.of(context)?.settings.name ?? globalRouteObserver.currentRoute;
    // Hide overlay on active trip screen (exact match or any sub‑route) to make this page fully invisible
    final hideActiveOverlay = routeName != null && (routeName == AppRoutes.activeTrip || routeName.startsWith(AppRoutes.activeTrip));
    
    // Hide bidding overlay on bidding screen (exact match or any sub-route)
    final hideBiddingOverlay = routeName != null && (routeName == AppRoutes.biddingScreen || routeName.startsWith(AppRoutes.biddingScreen));

    final showActiveOverlay = _activeTrip != null && !hideActiveOverlay;
    final showBiddingOverlay = !showActiveOverlay && _requestedTrip != null && !hideBiddingOverlay;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (showActiveOverlay)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _buildOverlayContent(context),
            ),
          if (showBiddingOverlay)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _buildBiddingOverlayContent(context),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    final trip = _activeTrip!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    List<LocationModel> allLocations = [];
    if (trip.tripStatus == TripStatus.firstCompleted) {
      allLocations.addAll(trip.dropoffLocations);
      allLocations.addAll(trip.pickupLocations);
    } else {
      allLocations.addAll(trip.pickupLocations);
      allLocations.addAll(trip.dropoffLocations);
    }

    if (allLocations.isEmpty) return const SizedBox.shrink();


    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy < 0 && _isExpanded) {
            setState(() { _isExpanded = false; });
          } else if (details.delta.dy > 0 && !_isExpanded) {
            setState(() { _isExpanded = true; });
          }
        },
        onTap: () {
          // Navigate to active trip screen when tapped
          final customerUuid = UserDataStore.userData?.data?.user?.uuid;
          if (customerUuid != null) {
            globalNavigatorKey.currentState?.pushNamed(AppRoutes.activeTrip, arguments: customerUuid);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E26) : Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(_getVehicleIcon(trip.carCategory?.carType), color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('trip_route') == 'trip_route' ? "Trip Route" : loc.translate('trip_route'),
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trip.tripStatus == TripStatus.firstCompleted ? "Leg 1 Complete" : "In Progress",
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final customerUuid = UserDataStore.userData?.data?.user?.uuid;
                        if (customerUuid != null) {
                          globalNavigatorKey.currentState?.pushNamed(AppRoutes.activeTrip, arguments: customerUuid);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        loc.translate('view') == 'view' ? "View" : loc.translate('view'),
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.black : Colors.white),
                      ),
                    ),
                  ],
                ),
                
                if (trip.serviceName != 'RIDE_SHARE' && trip.serviceName != 'RIDE_SHOW')
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pickup Date & Time",
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDate(trip.tripStatus == TripStatus.firstCompleted ? trip.endDatetime : trip.startDatetime),
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (trip.serviceName == 'RETURN' && trip.tripStatus != TripStatus.firstCompleted)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Return Time",
                                  style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDate(trip.endDatetime),
                                  style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(allLocations.length, (index) {
                        final isLast = index == allLocations.length - 1;
                        final isFirst = index == 0;
                        Color dotColor = isFirst ? Colors.green : (isLast ? Colors.red : Colors.yellow.shade700);
                        return Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF1C1E26) : Colors.white, width: 2),
                          ),
                        );
                      }),
                    ),
                    Align(
                      alignment: trip.tripStatus == TripStatus.firstCompleted ? const Alignment(0, 0) : const Alignment(-0.5, 0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getVehicleIcon(trip.carCategory?.carType), color: isDark ? Colors.black : Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 24),
                            ...List.generate(allLocations.length, (index) {
                              final isLast = index == allLocations.length - 1;
                              final isFirst = index == 0;
                              Color dotColor = isFirst ? Colors.green : (isLast ? Colors.red : Colors.yellow.shade700);

                              String label;
                              if (isFirst) {
                                label = loc.translate('pickup') == 'pickup' ? "Pickup" : loc.translate('pickup');
                              } else if (isLast) {
                                label = loc.translate('dropoff') == 'dropoff' ? "Dropoff" : loc.translate('dropoff');
                              } else {
                                label = "${loc.translate('stop') == 'stop' ? 'Stop' : loc.translate('stop')} $index";
                              }

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(isLast ? Icons.location_on : Icons.my_location, color: dotColor, size: 20),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: Colors.grey.withValues(alpha: 0.3),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label,
                                            style: GoogleFonts.poppins(
                                              color: isDark ? Colors.white54 : Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            allLocations[index].address ?? "Unknown",
                                            style: GoogleFonts.poppins(
                                              color: isDark ? Colors.white : Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (!isLast) const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedVehicleIcon extends StatefulWidget {
  final IconData iconData;
  final Color color;

  const _AnimatedVehicleIcon({required this.iconData, required this.color});

  @override
  State<_AnimatedVehicleIcon> createState() => _AnimatedVehicleIconState();
}

class _AnimatedVehicleIconState extends State<_AnimatedVehicleIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _slideAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: Icon(widget.iconData, color: widget.color, size: 24),
          ),
        );
      },
    );
  }
}
