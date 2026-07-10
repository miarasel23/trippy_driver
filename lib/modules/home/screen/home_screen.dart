import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controller/home_controller.dart';
import '../repository/home_repository.dart';
import '../widget/home_top_bar.dart';
import '../widget/current_session_card.dart';
import '../widget/new_request_card.dart';
import '../widget/service_mode_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeController(HomeRepository()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

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
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Add a subtle gradient overlay
          Container(
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

          const SafeArea(
            child: Column(
              children: [
                // 2. Custom Top App Bar
                HomeTopBar(),
                
                // 3. Current Session Card
                CurrentSessionCard(),
                
                Spacer(),

                // 4. New Rental Request Card
                NewRequestCard(),
                
                SizedBox(height: 16),
              ],
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
              backgroundColor: state.isOnline ? Colors.green : Colors.red,
              child: const Icon(Icons.local_taxi, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
