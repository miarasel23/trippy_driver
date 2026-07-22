import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../store/user_data_store.dart';
import '../model/rental_trip_model.dart';
import '../repository/home_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../helper/map_marker_helper.dart';
import '../../../utils/app_urls.dart';

class HomeState extends Equatable {
  final bool isOnline;
  final String serviceMode;
  final List<RentalTripModel> rentalTrips;
  final List<RentalTripModel> bidTrips;
  final bool isLoadingTrips;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String? toastMessageKey;
  final bool clearToast;
  final RentalTripModel? tripToReview;
  final RentalTripModel? previewTrip;

  const HomeState({
    required this.isOnline,
    required this.serviceMode,
    this.rentalTrips = const [],
    this.bidTrips = const [],
    this.isLoadingTrips = false,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.toastMessageKey,
    this.clearToast = false,
    this.tripToReview,
    this.previewTrip,
  });

  HomeState copyWith({
    bool? isOnline,
    String? serviceMode,
    List<RentalTripModel>? rentalTrips,
    List<RentalTripModel>? bidTrips,
    bool? isLoadingTrips,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    String? toastMessageKey,
    bool clearToast = false,
    RentalTripModel? tripToReview,
    bool clearReview = false,
    RentalTripModel? previewTrip,
    bool clearPreview = false,
  }) {
    return HomeState(
      isOnline: isOnline ?? this.isOnline,
      serviceMode: serviceMode ?? this.serviceMode,
      rentalTrips: rentalTrips ?? this.rentalTrips,
      bidTrips: bidTrips ?? this.bidTrips,
      isLoadingTrips: isLoadingTrips ?? this.isLoadingTrips,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      toastMessageKey: clearToast ? null : (toastMessageKey ?? this.toastMessageKey),
      tripToReview: clearReview ? null : (tripToReview ?? this.tripToReview),
      previewTrip: clearPreview ? null : (previewTrip ?? this.previewTrip),
    );
  }

  @override
  List<Object?> get props => [isOnline, serviceMode, rentalTrips, bidTrips, isLoadingTrips, markers, polylines, toastMessageKey, tripToReview, previewTrip];
}

class HomeController extends Cubit<HomeState> {
  final HomeRepository repository;
  Timer? _pollingTimer;
  Timer? _trackingTimer;

  HomeController(this.repository) : super(_getInitialState()) {
    _initIgnoredList();
    _startPolling();
    _startTracking();
  }

  Future<void> _initIgnoredList() async {
    final prefs = await SharedPreferences.getInstance();
    final ignoredBids = prefs.getStringList('ignoredBidTripIds');
    if (ignoredBids != null) {
      _ignoredBidTripIds.addAll(ignoredBids);
    }
    final ignoredRentals = prefs.getStringList('ignoredRentalTripIds');
    if (ignoredRentals != null) {
      _ignoredRentalTripIds.addAll(ignoredRentals);
    }
  }

  bool _isFetchingTrips = false;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (state.isOnline && !_isFetchingTrips) {
        _isFetchingTrips = true;
        try {
          await fetchRentalTrips(showLoading: false);
          await fetchBidTrips();
        } finally {
          _isFetchingTrips = false;
        }
      } else if (!state.isOnline) {
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

  Future<String?> cancelTrip(String tripUuid, String comment) async {
    final driverUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    if (driverUuid == null) return "User not authenticated";
    final error = await repository.cancelTrip(driverUuid: driverUuid, tripUuid: tripUuid, comment: comment);
    if (error == null) {
      // Refresh trips after cancellation
      fetchBidTrips();
      fetchRentalTrips();
    }
    return error;
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

  Future<void> fetchRentalTrips({bool showLoading = true}) async {
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

  Future<void> fetchBidTrips() async {
    final bidsFuture = repository.getBidTripList();
    final activeBidsFuture = repository.getActiveBidTrips();
    
    final results = await Future.wait([bidsFuture, activeBidsFuture]);
    final List<RentalTripModel> allFetchedBids = [];
    if (results[0] != null) allFetchedBids.addAll(results[0]!);
    if (results[1] != null) allFetchedBids.addAll(results[1]!);
    
    

    // Deduplicate by UUID, taking the most recent/relevant if there are duplicates
    final Map<String, RentalTripModel> uniqueBids = {};
    for (var bid in allFetchedBids) {
      // Prioritize bids that have a myBid object or are from the active bids list
      final service = bid.serviceName.isNotEmpty ? bid.serviceName : bid.carService.serviceName;
      if (!uniqueBids.containsKey(bid.uuid) || bid.myBid != null || service == 'RIDE_SHARE') {
        uniqueBids[bid.uuid] = bid;
      }
    }
    
    final bids = uniqueBids.values.toList();

    if (bids.isNotEmpty || results[0] != null || results[1] != null) {
      String? newToastKey;
      RentalTripModel? newTripToReview;
      
      final validBids = bids.where((t) {
        if (_ignoredBidTripIds.contains(t.uuid)) return false;
        final ts = t.tripStatus;
        if (ts == 'CANCELLED' || t.myBid?.status == 'CANCELLED') {
           final old = state.bidTrips.firstWhere((oldBid) => oldBid.uuid == t.uuid, orElse: () => t);
           if (old.tripStatus == 'ACCEPTED' || old.myBid?.status == 'ACCEPTED') {
               newToastKey = 'customer_cancelled_trip_${DateTime.now().millisecondsSinceEpoch}';
           }
           return false;
        }
        
        if (ts == 'COMPLETED') {
           if (t.givenReview == false && state.tripToReview?.uuid != t.uuid) {
               newTripToReview = t;
           }
           return false;
        }
        
        return true;
      }).toList();
      

      bool stateChanged = false;
      
      final currentIds = state.bidTrips.map((t) => t.uuid).toSet();
      final newIds = validBids.map((t) => t.uuid).toSet();
      if (currentIds.length != newIds.length || !currentIds.containsAll(newIds) || !newIds.containsAll(currentIds)) {
        stateChanged = true;
      }

      final newMap = <String, RentalTripModel>{};
      for (var apiBid in validBids) {
        newMap[apiBid.uuid] = apiBid;
        final old = state.bidTrips.firstWhere((t) => t.uuid == apiBid.uuid, orElse: () => apiBid);
        if (old != apiBid && (old.tripStatus != apiBid.tripStatus || old.myBid?.status != apiBid.myBid?.status)) {
          stateChanged = true;
        }
      }


      if (stateChanged || newToastKey != null || newTripToReview != null) {
        final updatedList = newMap.values.toList();
        await _generateAndEmitMapData(updatedList, newToastKey, newTripToReview);
      }
    }
  }

  Future<void> _generateAndEmitMapData(List<RentalTripModel> bids, [String? toastKey, RentalTripModel? newTripToReview]) async {
    final acceptedTrips = bids.where((t) {
      final status = t.tripStatus;
      final bidStatus = t.myBid?.status;
      
      return status == 'ACCEPTED' || status == 'RIDE_STARTED' || status == 'FIRST_COMPLETED' || status == 'IN_PROGRESS' || bidStatus == 'ACCEPTED';
    }).toList();

    RentalTripModel? tripToDisplay = state.previewTrip;
    if (tripToDisplay == null && acceptedTrips.isNotEmpty) {
      tripToDisplay = acceptedTrips.first;
    }

    if (tripToDisplay == null) {
      emit(state.copyWith(
        bidTrips: bids, 
        markers: const <Marker>{}, 
        polylines: const <Polyline>{},
        toastMessageKey: toastKey,
        clearToast: toastKey == null,
        tripToReview: newTripToReview,
      ));
      return;
    }

    final trip = tripToDisplay;
    final generatedMarkers = <Marker>{};
    final generatedPolylines = <Polyline>{};

    final prefs = await SharedPreferences.getInstance();
    final isBangla = (prefs.getString('active_language_code') ?? 'en') == 'bn';
    
    String toBanglaDigits(String input) {
      const e2b = {'0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'};
      return input.split('').map((c) => e2b[c] ?? c).join();
    }

    // Get driver position
    Position? driverPosition;
    try {
      driverPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final carIcon = await MapMarkerHelper.createCarMarkerBitmap();
      generatedMarkers.add(
         Marker(
           markerId: const MarkerId('driver'),
           position: LatLng(driverPosition.latitude, driverPosition.longitude),
           icon: carIcon,
         ),
      );
    } catch (e) {
      print("Could not get driver location: $e");
    }

    final polylinePoints = PolylinePoints();

    // 1. Blue route (Driver -> First Pickup)
    if (driverPosition != null && trip.pickupLocations.isNotEmpty) {
       final pickup = trip.pickupLocations.first;
       PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
         googleApiKey: AppUrls.googleApiKey,
         request: PolylineRequest(
            origin: PointLatLng(driverPosition.latitude, driverPosition.longitude),
            destination: PointLatLng(pickup.latitude, pickup.longitude),
            mode: TravelMode.driving,
         ),
       );
       if (result.points.isNotEmpty) {
          generatedPolylines.add(
            Polyline(
              polylineId: const PolylineId('driver_to_pickup'),
              color: const Color(0xFF4285F4), // Blue
              width: 5,
              points: result.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            ),
          );
       }
    }

    // 2. Green route (Pickups -> Dropoffs)
    final tripPoints = <PointLatLng>[];
    for (var p in trip.pickupLocations) tripPoints.add(PointLatLng(p.latitude, p.longitude));
    for (var p in trip.dropoffLocations) tripPoints.add(PointLatLng(p.latitude, p.longitude));

    if (tripPoints.length >= 2) {
       List<LatLng> polylineCoords = [];
       for (int i = 0; i < tripPoints.length - 1; i++) {
          PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
            googleApiKey: AppUrls.googleApiKey,
            request: PolylineRequest(
               origin: tripPoints[i],
               destination: tripPoints[i+1],
               mode: TravelMode.driving,
            ),
          );
          if (result.points.isNotEmpty) {
             polylineCoords.addAll(result.points.map((p) => LatLng(p.latitude, p.longitude)));
          }
       }
       if (polylineCoords.isNotEmpty) {
          generatedPolylines.add(
            Polyline(
              polylineId: const PolylineId('trip_route'),
              color: const Color(0xFF34A853), // Green
              width: 5,
              points: polylineCoords,
            ),
          );
       }
    }

    // Parse km strings to double
    double parseKm(String text) {
      final s = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(s) ?? 0.0;
    }
    
    final pickupKm = parseKm(trip.pickupKm);
    final totalKm = trip.totalDistance;
    
    final pickupMins = (pickupKm * 3.5).round(); // approx 3.5 mins per km
    final dropoffMins = (totalKm * 3.5).round();

    for (int i = 0; i < trip.pickupLocations.length; i++) {
       final pickup = trip.pickupLocations[i];
       final title = isBangla ? 'পিকআপ ${toBanglaDigits('${i+1}')}' : 'Pickup ${i+1}';
       
       final icon = await MapMarkerHelper.createCustomMarkerBitmap(
         String.fromCharCode('A'.codeUnitAt(0) + i), 
         const Color(0xFF4285F4) // Blue
       );
       generatedMarkers.add(
         Marker(
           markerId: MarkerId('pickup_$i'),
           position: LatLng(pickup.latitude, pickup.longitude),
           infoWindow: InfoWindow(title: title, snippet: pickup.address),
           icon: icon,
         ),
       );
    }

    for (int i = 0; i < trip.dropoffLocations.length; i++) {
       final drop = trip.dropoffLocations[i];
       final title = isBangla ? 'ড্রপ অফ ${toBanglaDigits('${i+1}')}' : 'Dropoff ${i+1}';
       
       final icon = await MapMarkerHelper.createCustomMarkerBitmap(
         String.fromCharCode('B'.codeUnitAt(0) + i), 
         const Color(0xFF34A853) // Green
       );
       generatedMarkers.add(
         Marker(
           markerId: MarkerId('dropoff_$i'),
           position: LatLng(drop.latitude, drop.longitude),
           infoWindow: InfoWindow(title: title, snippet: drop.address),
           icon: icon,
         ),
       );
    }

    emit(state.copyWith(
      bidTrips: bids, 
      markers: generatedMarkers,
      polylines: generatedPolylines,
      toastMessageKey: toastKey,
      clearToast: toastKey == null,
      tripToReview: newTripToReview,
    ));
  }

  void removeTrip(String uuid) async {
    _ignoredRentalTripIds.add(uuid);
    final updatedTrips = state.rentalTrips.where((t) => t.uuid != uuid).toList();
    emit(state.copyWith(rentalTrips: updatedTrips));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ignoredRentalTripIds', _ignoredRentalTripIds.toList());
  }

  void removeBidTrip(String uuid) async {
    _ignoredBidTripIds.add(uuid);
    final updatedTrips = state.bidTrips.where((t) => t.uuid != uuid).toList();
    emit(state.copyWith(bidTrips: updatedTrips));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ignoredBidTripIds', _ignoredBidTripIds.toList());
  }

  Future<String?> submitBid(String tripUuid, double bidAmount) async {
    final error = await repository.submitBid(
      tripUuid: tripUuid,
      bidAmount: bidAmount,
    );
    if (error == null) {
      removeTrip(tripUuid); // Hide the card on success
      fetchBidTrips();      // Refresh bids to show overlay
    }
    return error;
  }

  Future<String?> acceptRideShareTrip(String tripUuid) async {
    final error = await repository.acceptRideShareTrip(
      tripUuid: tripUuid,
    );
    if (error == null) {
      removeTrip(tripUuid);
      fetchBidTrips();
    }
    return error;
  }

  Future<String?> updateTripRideStatus(String tripUuid, String status) async {
    final error = await repository.updateTripRideStatus(
      tripUuid: tripUuid,
      status: status,
    );
    if (error == null) {
      fetchBidTrips();
    }
    return error;
  }

  Future<String?> submitReview({
    required String tripUuid,
    required String customerUuid,
    required int rating,
    String? comments,
  }) async {
    final driverUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    if (driverUuid == null) return "User not authenticated";

    final error = await repository.submitReview(
      customerUuid: customerUuid,
      driverUuid: driverUuid,
      tripUuid: tripUuid,
      rating: rating,
      comments: comments,
    );

    if (error == null) {
      // Clear the review screen
      emit(state.copyWith(clearReview: true));
    }
    return error;
  }
  
  void clearTripToReview() {
    emit(state.copyWith(clearReview: true));
  }

  void selectTripForPreview(RentalTripModel? trip) {
    emit(state.copyWith(previewTrip: trip, clearPreview: trip == null));
    _generateAndEmitMapData(state.bidTrips);
  }
}
