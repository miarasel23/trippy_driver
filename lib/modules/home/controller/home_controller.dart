import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:equatable/equatable.dart';

import '../../../store/user_data_store.dart';
import '../model/rental_trip_model.dart';
import '../repository/home_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeState extends Equatable {
  final bool isOnline;
  final String serviceMode;
  final List<RentalTripModel> rentalTrips;
  final List<RentalTripModel> bidTrips;
  final bool isLoadingTrips;

  const HomeState({
    required this.isOnline,
    required this.serviceMode,
    this.rentalTrips = const [],
    this.bidTrips = const [],
    this.isLoadingTrips = false,
  });

  HomeState copyWith({
    bool? isOnline,
    String? serviceMode,
    List<RentalTripModel>? rentalTrips,
    List<RentalTripModel>? bidTrips,
    bool? isLoadingTrips,
  }) {
    return HomeState(
      isOnline: isOnline ?? this.isOnline,
      serviceMode: serviceMode ?? this.serviceMode,
      rentalTrips: rentalTrips ?? this.rentalTrips,
      bidTrips: bidTrips ?? this.bidTrips,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
    );
  }

  @override
  List<Object?> get props => [isOnline, serviceMode, rentalTrips, bidTrips, isLoadingTrips];
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
      debugPrint("Tracking error: $e");
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

  void fetchRentalTrips({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(isLoadingTrips: true));
    }
    final trips = await repository.getRentalTrips();
    
    if (trips != null) {
      final currentTripIds = state.rentalTrips.map((t) => t.uuid).toSet();
      final newTripIds = trips.map((t) => t.uuid).toSet();
      
      final hasNewTrips = newTripIds.difference(currentTripIds).isNotEmpty;
      
      if (hasNewTrips) {
        try {
          FlutterRingtonePlayer().play(fromAsset: "assets/sounds/ride_request.wav");
        } catch (e) {
          debugPrint("Could not play sound: $e");
        }
      }
    }

    emit(state.copyWith(
      isLoadingTrips: false,
      rentalTrips: trips ?? [],
    ));
  }

  void fetchBidTrips() async {
    final bids = await repository.getBidTripList();
    if (bids != null) {
      emit(state.copyWith(bidTrips: bids));
    }
  }

  void removeTrip(String uuid) {
    final updatedTrips = state.rentalTrips.where((t) => t.uuid != uuid).toList();
    emit(state.copyWith(rentalTrips: updatedTrips));
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

