import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../utils/app_urls.dart';
import '../model/rental_trip_model.dart';
import '../controller/home_controller.dart';
import '../repository/home_repository.dart';
import '../widget/home_top_bar.dart';
import '../widget/current_session_card.dart';
import '../widget/new_request_card.dart';
import '../widget/bid_trip_overlay.dart';
import '../widget/pending_bid_trip_card.dart';
import '../widget/accepted_trip_card.dart';
import '../widget/service_mode_bottom_sheet.dart';
import '../widget/review_bottom_sheet.dart';

import '../../../core/utils/ui_utils.dart';
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
      context.read<HomeController>().fetchRentalTrips();
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
              listenWhen: (previous, current) => previous.tripToReview?.uuid != current.tripToReview?.uuid && current.tripToReview != null,
              listener: (context, state) {
                if (state.tripToReview != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: context.read<HomeController>(),
                      child: ReviewBottomSheet(trip: state.tripToReview!),
                    ),
                  ).whenComplete(() {
                    context.read<HomeController>().clearTripToReview();
                  });
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
          

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Top App Bar
                const HomeTopBar(),
                
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
                          
                          final combinedTrips = List<RentalTripModel>.from(state.rentalTrips)..addAll(rideShareBids);
                          
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
          
          // Persistent Accepted Trip Card (if any) at the bottom
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PendingBidTripCard(),
                  AcceptedTripCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
