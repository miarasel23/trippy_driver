import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:equatable/equatable.dart';

import '../../../store/user_data_store.dart';
import '../model/rental_trip_model.dart';
import '../repository/home_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../utils/app_urls.dart';

class HomeState extends Equatable {
  final bool isOnline;
  final String serviceMode;
  final List<RentalTripModel> rentalTrips;
  final List<RentalTripModel> bidTrips;
  final bool isLoadingTrips;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const HomeState({
    required this.isOnline,
    required this.serviceMode,
    this.rentalTrips = const [],
    this.bidTrips = const [],
    this.isLoadingTrips = false,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
  });

  HomeState copyWith({
    bool? isOnline,
    String? serviceMode,
    List<RentalTripModel>? rentalTrips,
    List<RentalTripModel>? bidTrips,
    bool? isLoadingTrips,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
  }) {
    return HomeState(
      isOnline: isOnline ?? this.isOnline,
      serviceMode: serviceMode ?? this.serviceMode,
      rentalTrips: rentalTrips ?? this.rentalTrips,
      bidTrips: bidTrips ?? this.bidTrips,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
    );
  }

  @override
  List<Object?> get props => [isOnline, serviceMode, rentalTrips, bidTrips, isLoadingTrips, markers, polylines];
}

class HomeController extends Cubit<HomeState> {
  final HomeRepository repository;
  Timer? _pollingTimer;
  Timer? _trackingTimer;

  HomeController(this.repository) : super(_getInitialState()) {
    _startPolling();
    _startTracking();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (state.isOnline) {
        fetchRentalTrips(showLoading: false);
        if (state.serviceMode == 'RIDE SHARE' || state.serviceMode == 'BOTH') {
          fetchBidTrips();
        }
      } else {
        if (state.bidTrips.isNotEmpty) {
           emit(state.copyWith(bidTrips: []));
        }
      }
    });
  }

  void _startTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (state.isOnline) {
        _trackLocation();
      }
    });
  }

  Future<void> _trackLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) return;
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      final _geocoder = Geocoding();
      List<Placemark> placemarks = await _geocoder.placemarkFromCoordinates(position.latitude, position.longitude).timeout(const Duration(seconds: 3));
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if (p.street != null && p.street!.isNotEmpty && !p.street!.contains('+')) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
        
        String address = parts.join(', ');
        if (address.isEmpty) address = "${position.latitude}, ${position.longitude}";

        final geoUuid = await repository.searchLocation(address);
        if (geoUuid != null) {
          await repository.trackDriverLocation(geoUuid);
        }
      }
    } catch (e) {
      // print removed
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _trackingTimer?.cancel();
    return super.close();
  }

  static HomeState _getInitialState() {
    String status = UserDataStore.userData?.data?.user?.currentRideStatus ?? 'OFFLINE';
    if (status == 'RIDE_SHARE') status = 'RIDE SHARE';
    if (status == 'RENT_A_CAR') status = 'RENT A CAR';
    if (status == 'BOTH') status = 'BOTH';

    return HomeState(
      isOnline: status != 'OFFLINE',
      serviceMode: status == 'OFFLINE' ? 'RIDE SHARE' : status, // Default to 'RIDE SHARE' for UI if offline, or keep 'OFFLINE'
    );
  }

  void toggleOnlineStatus() async {
    final newMode = state.isOnline ? 'OFFLINE' : 'RIDE SHARE';
    await _updateStatusAndEmit(newMode);
  }

  void setServiceMode(String mode) async {
    await _updateStatusAndEmit(mode);
  }

  Future<void> _updateStatusAndEmit(String mode) async {
    final error = await repository.updateRideStatus(status: mode);
    
    if (error == null) {
      // API success, now update UI state (this changes the color)
      emit(state.copyWith(
        serviceMode: mode,
        isOnline: mode != 'OFFLINE',
      ));

      if (UserDataStore.userData?.data?.user != null) {
        String apiStatus = mode;
        if (mode == 'RENT A CAR') apiStatus = 'RENT_A_CAR';
        if (mode == 'RIDE SHARE') apiStatus = 'RIDE_SHARE';
        if (mode == 'BOTH') apiStatus = 'BOTH';

        UserDataStore.userData!.data!.user!.currentRideStatus = apiStatus;
        UserDataStore.saveUserData(UserDataStore.userData!);
      }
    } else {
      // API failed, state remains unchanged. Error snackbar is handled by ApiService.
    }
  }

  final Set<String> _ignoredRentalTripIds = {};
  final Set<String> _ignoredBidTripIds = {};

  void fetchRentalTrips({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(isLoadingTrips: true));
    }
    final trips = await repository.getRentalTrips();
    
    if (trips != null) {
      final validTrips = trips.where((t) => !_ignoredRentalTripIds.contains(t.uuid)).toList();
      
      final currentMap = { for (var t in state.rentalTrips) t.uuid: t };
      bool stateChanged = false;
      bool hasNewTrips = false;

      final currentIds = currentMap.keys.toSet();
      final newIds = validTrips.map((t) => t.uuid).toSet();
      if (currentIds.length != newIds.length || !currentIds.containsAll(newIds)) {
        stateChanged = true;
      }

      for (var apiTrip in validTrips) {
        if (!currentMap.containsKey(apiTrip.uuid)) {
          currentMap[apiTrip.uuid] = apiTrip;
          stateChanged = true;
          hasNewTrips = true;
        } else {
          final old = currentMap[apiTrip.uuid]!;
          if (old.tripStatus != apiTrip.tripStatus) {
            currentMap[apiTrip.uuid] = apiTrip;
            stateChanged = true;
          }
        }
      }
      
      if (hasNewTrips) {
        try {
          FlutterRingtonePlayer().play(fromAsset: "assets/sounds/ride_request.wav");
        } catch (e) {
          // print removed
        }
      }

      if (stateChanged) {
        final updatedList = validTrips.map((t) => currentMap[t.uuid]!).toList();
        emit(state.copyWith(
          isLoadingTrips: false,
          rentalTrips: updatedList,
        ));
      } else {
        emit(state.copyWith(isLoadingTrips: false));
      }
    } else {
      emit(state.copyWith(isLoadingTrips: false));
    }
  }

  void fetchBidTrips() async {
    final bids = await repository.getBidTripList();
    if (bids != null) {
      final validBids = bids.where((t) => !_ignoredBidTripIds.contains(t.uuid)).toList();
      
      final currentMap = { for (var t in state.bidTrips) t.uuid: t };
      bool stateChanged = false;
      
      final currentIds = currentMap.keys.toSet();
      final newIds = validBids.map((t) => t.uuid).toSet();
      if (currentIds.length != newIds.length || !currentIds.containsAll(newIds)) {
        stateChanged = true;
      }

      for (var apiBid in validBids) {
        if (!currentMap.containsKey(apiBid.uuid)) {
          currentMap[apiBid.uuid] = apiBid;
          stateChanged = true;
        } else {
          final old = currentMap[apiBid.uuid]!;
          if (old.tripStatus != apiBid.tripStatus || old.myBid?.status != apiBid.myBid?.status) {
            currentMap[apiBid.uuid] = apiBid;
            stateChanged = true;
          }
        }
      }

      if (stateChanged) {
        final updatedList = validBids.map((t) => currentMap[t.uuid]!).toList();
        await _generateAndEmitMapData(updatedList);
      }
    }
  }

  Future<void> _generateAndEmitMapData(List<RentalTripModel> bids) async {
    final acceptedTrips = bids.where((t) {
      final status = t.myBid?.status ?? t.tripStatus;
      return status == 'ACCEPTED';
    }).toList();

    if (acceptedTrips.isEmpty) {
      emit(state.copyWith(bidTrips: bids, markers: const <Marker>{}, polylines: const <Polyline>{}));
      return;
    }

    final trip = acceptedTrips.first;
    final generatedMarkers = <Marker>{};
    final points = <PointLatLng>[];

    for (int i = 0; i < trip.pickupLocations.length; i++) {
       final pickup = trip.pickupLocations[i];
       generatedMarkers.add(
         Marker(
           markerId: MarkerId('pickup_$i'),
           position: LatLng(pickup.latitude, pickup.longitude),
           infoWindow: InfoWindow(title: 'Pickup ${i+1}', snippet: pickup.address),
           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
         ),
       );
       points.add(PointLatLng(pickup.latitude, pickup.longitude));
    }

    for (int i = 0; i < trip.dropoffLocations.length; i++) {
       final drop = trip.dropoffLocations[i];
       generatedMarkers.add(
         Marker(
           markerId: MarkerId('dropoff_$i'),
           position: LatLng(drop.latitude, drop.longitude),
           infoWindow: InfoWindow(title: 'Dropoff ${i+1}', snippet: drop.address),
           icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
         ),
       );
       points.add(PointLatLng(drop.latitude, drop.longitude));
    }

    final generatedPolylines = <Polyline>{};

    if (points.length >= 2) {
       PolylinePoints polylinePoints = PolylinePoints();
       List<LatLng> polylineCoordinates = [];

       for (int i = 0; i < points.length - 1; i++) {
          PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: AppUrls.googleApiKey,
            request: PolylineRequest(
               origin: points[i],
               destination: points[i+1],
               mode: TravelMode.driving,
            ),
          );
          if (result.points.isNotEmpty) {
             for (var point in result.points) {
                polylineCoordinates.add(LatLng(point.latitude, point.longitude));
             }
          }
       }

       if (polylineCoordinates.isNotEmpty) {
         generatedPolylines.add(
           Polyline(
             polylineId: const PolylineId('route'),
             color: const Color(0xFF0000FF), // Blue
             width: 5,
             points: polylineCoordinates,
           ),
         );
       }
    }

    emit(state.copyWith(
      bidTrips: bids, 
      markers: generatedMarkers,
      polylines: generatedPolylines,
    ));
  }

  void removeTrip(String uuid) {
    _ignoredRentalTripIds.add(uuid);
    final updatedTrips = state.rentalTrips.where((t) => t.uuid != uuid).toList();
    emit(state.copyWith(rentalTrips: updatedTrips));
  }

  void removeBidTrip(String uuid) {
    _ignoredBidTripIds.add(uuid);
    final updatedTrips = state.bidTrips.where((t) => t.uuid != uuid).toList();
    emit(state.copyWith(bidTrips: updatedTrips));
  }

  Future<String?> submitBid(String tripUuid, double bidAmount) async {
    final error = await repository.submitBid(
      tripUuid: tripUuid,
      bidAmount: bidAmount,
    );
    if (error == null) {
      removeTrip(tripUuid); // Hide the card on success
    }
    return error;
  }
}

