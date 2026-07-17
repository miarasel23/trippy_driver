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
import '../widget/accepted_trip_card.dart';
import '../widget/service_mode_bottom_sheet.dart';

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
                  markers: state.markers,
                  polylines: state.polylines,
                );
              },
            ),
          
          // Add a subtle gradient overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Top App Bar
                const HomeTopBar(),
                
                // 3. Current Session Card
                const CurrentSessionCard(),
                
                // 4. Content Area (Stack for overlapping)
                Expanded(
                  child: Stack(
                    children: [
                      // Lower z-index: Active Bids Overlay
                      const Align(
                        alignment: Alignment.topCenter,
                        child: BidTripOverlay(),
                      ),
                      
                      // Higher z-index: New Rental Request Cards
                      BlocBuilder<HomeController, HomeState>(
                        builder: (context, state) {
                          if (state.isLoadingTrips) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state.rentalTrips.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 100),
                            itemCount: state.rentalTrips.length,
                            itemBuilder: (context, index) {
                              final trip = state.rentalTrips[index];
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
            bottom: 32,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AcceptedTripCard(),
            ),
          ),
        ],
      ),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 12), // Pushes the FAB down 12 pixels closer to the navbar
        child: BlocBuilder<HomeController, HomeState>(
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () => ServiceModeBottomSheet.show(context, theme),
              backgroundColor: state.isOnline ? Colors.lightGreen : Colors.red,
              child: const Icon(Icons.local_taxi, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
