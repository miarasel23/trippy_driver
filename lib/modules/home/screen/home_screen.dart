import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../utils/app_urls.dart';
import '../model/rental_trip_model.dart';
import '../controller/home_controller.dart';
import '../repository/home_repository.dart';
import '../widget/home_top_bar_widget.dart';
import '../widget/current_session_card_widget.dart';
import '../widget/new_request_card_widget.dart';
import '../widget/bid_trip_overlay_widget.dart';
import '../widget/pending_bid_trip_card_widget.dart';
import '../widget/accepted_trip_card_widget.dart';
import '../widget/accepted_rental_details_widget.dart';
import '../widget/service_mode_bottom_sheet_widget.dart';
import '../widget/review_bottom_sheet_widget.dart';

import '../../../routes/app_routes.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../store/user_data_store.dart';
import '../../../utils/images.dart';
import '../../../../core/utils/localization/app_localization.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeView();
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  bool _isReviewSheetOpen = false;

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16.0,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().checkAndUpdateRideStatusFromApi();
    });
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco as placeholder
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            BlocListener<HomeController, HomeState>(
              listenWhen: (previous, current) => previous.accountStatus != current.accountStatus && 
                  current.accountStatus.toUpperCase() != 'ACTIVE' && 
                  current.accountStatus.toUpperCase() != 'PROGRESS',
              listener: (context, state) {
                 final loc = AppLocalizations.of(context);
                 showDialog(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     title: Row(
                       children: [
                         const Icon(Icons.warning_rounded, color: Colors.red),
                         const SizedBox(width: 8),
                         Text(loc.translate('account_restricted_title'), style: const TextStyle(color: Colors.red, fontSize: 18)),
                       ],
                     ),
                     content: Text(loc.translate('account_restricted_support')),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(ctx),
                         child: Text(loc.translate('ok')),
                       )
                     ],
                   )
                 );
              },
              child: const SizedBox.shrink(),
            ),
            BlocListener<HomeController, HomeState>(
              listenWhen: (previous, current) => previous.toastMessageKey != current.toastMessageKey && current.toastMessageKey != null,
              listener: (context, state) {
                if (state.toastMessageKey != null) {
                   final loc = AppLocalizations.of(context);
                   final keyParts = state.toastMessageKey!.split('_');
                   final key = keyParts.length >= 3 ? keyParts.sublist(0, 3).join('_') : state.toastMessageKey!;
                   final msg = loc.translate(key) ?? "Customer cancelled trip";
                   UiUtils.showAppSnackBar(context, msg, type: 'error');
                }
              },
              child: const SizedBox.shrink(),
            ),
            BlocListener<HomeController, HomeState>(
              listenWhen: (previous, current) => previous.markers != current.markers && current.markers.isNotEmpty,
              listener: (context, state) async {
                if (state.markers.isEmpty) return;
                double minLat = state.markers.first.position.latitude;
                double minLong = state.markers.first.position.longitude;
                double maxLat = state.markers.first.position.latitude;
                double maxLong = state.markers.first.position.longitude;
                for (final marker in state.markers) {
                  if (marker.position.latitude < minLat) minLat = marker.position.latitude;
                  if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
                  if (marker.position.longitude < minLong) minLong = marker.position.longitude;
                  if (marker.position.longitude > maxLong) maxLong = marker.position.longitude;
                }
                final controller = await _mapController.future;
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(minLat, minLong),
                      northeast: LatLng(maxLat, maxLong),
                    ),
                    100.0,
                  ),
                );
              },
              child: const SizedBox.shrink(),
            ),
            BlocListener<HomeController, HomeState>(
              listenWhen: (previous, current) =>
                  !_isReviewSheetOpen &&
                  current.tripToReview != null &&
                  previous.tripToReview?.uuid != current.tripToReview?.uuid,
              listener: (context, state) async {
                if (state.tripToReview != null && !_isReviewSheetOpen) {
                  _isReviewSheetOpen = true;
                  final trip = state.tripToReview!;
                  try {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BlocProvider.value(
                        value: context.read<HomeController>(),
                        child: ReviewBottomSheet(trip: trip),
                      ),
                    );
                  } finally {
                    _isReviewSheetOpen = false;
                    if (mounted) {
                      context.read<HomeController>().clearTripToReview();
                    }
                  }
                }
              },
              child: const SizedBox.shrink(),
            ),
            // 1. Google Map Background
            BlocBuilder<HomeController, HomeState>(
              builder: (context, state) {
                return GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                    _goToCurrentLocation();
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  padding: const EdgeInsets.only(top: 140, bottom: 200), // Push controls down
                  markers: state.markers,
                  polylines: state.polylines,
                );
              },
            ),
          
            // ── Watermark logo — just above the bottom cards ─────────
            IgnorePointer(
              child: Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 0.88),
                  child: Opacity(
                    opacity: 0.18,
                    child: Image.asset(
                      Images.logo,
                      width: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Top App Bar (card)
                const HomeTopBar(),

                // Inactive/Restricted Account Banner
                BlocBuilder<HomeController, HomeState>(
                  builder: (context, state) {
                    final bool isNotActive = state.accountStatus.toUpperCase() != 'ACTIVE';
                    if (!isNotActive) return const SizedBox.shrink();

                    final loc = AppLocalizations.of(context);
                    final isProgress = state.accountStatus.toUpperCase() == 'PROGRESS';
                    final bgColor = isProgress ? const Color(0xFFF59E0B) : Colors.red.shade600;
                    final textColor = isProgress ? Colors.black87 : Colors.white;
                    final iconColor = isProgress ? Colors.black87 : Colors.white;
                    final shadowColor = isProgress ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3);

                    final warningText = isProgress 
                        ? loc.translate('account_progress_warning')
                        : loc.translate('account_restricted_support');

                    return GestureDetector(
                      onTap: () {
                        if (isProgress) {
                          Navigator.pushNamed(context, AppRoutes.registrationInfo);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                             BoxShadow(
                               color: shadowColor,
                               blurRadius: 10,
                               offset: const Offset(0, 4),
                             )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded, color: iconColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                warningText,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isProgress) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 16),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                ),
                
                // 3. Content Area (Stack for overlapping)
                Expanded(
                  child: Stack(
                    children: [
                      // Lower z-index: Active Bids Overlay
                      BlocBuilder<HomeController, HomeState>(
                        builder: (context, state) {
                          if (state.previewTrip != null) return const SizedBox.shrink();
                          return const Align(
                            alignment: Alignment.topCenter,
                            child: BidTripOverlay(),
                          );
                        }
                      ),
                      
                      // Higher z-index: New Rental Request Cards
                      BlocBuilder<HomeController, HomeState>(
                        builder: (context, state) {
                          if (!state.isOnline) {
                            return const SizedBox.shrink();
                          }
                          if (state.isLoadingTrips) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state.previewTrip != null) return const SizedBox.shrink();
                          
                          final rideShareBids = state.bidTrips.where((t) {
                            final service = t.serviceName.isNotEmpty ? t.serviceName : t.carService.serviceName;
                            final tripStatus = t.tripStatus.toUpperCase();
                            if (tripStatus == 'ACCEPTED' || tripStatus == 'IN_PROGRESS' || tripStatus == 'RIDE_STARTED' || tripStatus == 'FIRST_COMPLETED' || tripStatus == 'COMPLETED') {
                              return false;
                            }
                            final status = t.myBid?.status ?? t.tripStatus;
                            return service == 'RIDE_SHARE' && status != 'ACCEPTED' && status != 'CANCELLED';
                          }).toList();
                          
                          final rentalWithoutBids = state.rentalTrips.where((t) {
                            final service = t.serviceName.isNotEmpty ? t.serviceName : t.carService.serviceName;
                            final isRideShare = service.toUpperCase().contains('RIDE') || service.toUpperCase() == 'RIDE_SHARE';
                            if (!isRideShare && t.myBid != null) return false;
                            return true;
                          }).toList();
                          
                          final combinedTrips = List<RentalTripModel>.from(rentalWithoutBids)..addAll(rideShareBids);
                          
                          // Deduplicate by UUID
                          final uniqueTrips = <String, RentalTripModel>{};
                          for (var trip in combinedTrips) {
                            uniqueTrips[trip.uuid] = trip; // Bid trips added last will overwrite rental ones
                          }
                          
                          final sortedTrips = uniqueTrips.values.toList();
                          sortedTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                          if (sortedTrips.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: sortedTrips.length,
                            itemBuilder: (context, index) {
                              final trip = sortedTrips[index];
                              return NewRequestCard(key: ValueKey(trip.uuid), trip: trip);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Persistent Cards at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: BlocBuilder<HomeController, HomeState>(
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.previewTrip != null)
                        const AcceptedRentalDetails()
                      else ...[
                        const PendingBidTripCard(),
                        const AcceptedTripCard(),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
