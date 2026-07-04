import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../controller/active_trip_bloc.dart';
import '../controller/active_trip_event.dart';
import '../controller/active_trip_state.dart';
import '../helper/active_trip_helper.dart';
import '../model/create_rental_trip_model.dart';
import '../model/trip_status.dart';
import '../helper/map_helper.dart';
import '../widget/trip_review_bottom_sheet.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_urls.dart';
import '../../../widgets/cancel_trip_dialog.dart';

class ActiveTripScreen extends StatefulWidget {
  final String customerUuid;

  const ActiveTripScreen({super.key, required this.customerUuid});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  RentalTrip? _activeTrip;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];

  bool _isRouteExpanded = false;
  bool _isReviewSheetShown = false;
  Marker? _driverMarker;
  double _driverRotation = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context);
      context.read<ActiveTripBloc>().add(
        StartActiveTripPolling(
          customerUuid: widget.customerUuid,
          languageCode: loc.locale.languageCode,
        ),
      );
    });
  }

  @override
  void dispose() {
    context.read<ActiveTripBloc>().add(StopActiveTripPolling());
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchRoutePolylinesForTrip(RentalTrip trip) async {
    List<LatLng> newRoutePoints = [];
    Set<Marker> newMarkers = {};

    List<LocationModel> allLocations = [];
    if (trip.tripStatus == TripStatus.firstCompleted) {
      allLocations.addAll(trip.dropoffLocations);
      allLocations.addAll(trip.pickupLocations);
    } else {
      allLocations.addAll(trip.pickupLocations);
      allLocations.addAll(trip.dropoffLocations);
    }

    for (int i = 0; i < allLocations.length; i++) {
      final loc = allLocations[i];
      final lat = double.tryParse(loc.latitude ?? '') ?? 23.8103;
      final lng = double.tryParse(loc.longitude ?? '') ?? 90.4125;
      final point = LatLng(lat, lng);
      newRoutePoints.add(point);

      double hue;
      if (i == 0) {
        hue = BitmapDescriptor.hueGreen;
      } else if (i == allLocations.length - 1) {
        hue = BitmapDescriptor.hueRed;
      } else {
        hue = BitmapDescriptor.hueYellow;
      }
      newMarkers.add(
        Marker(
          markerId: MarkerId('loc_$i'),
          position: point,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    }

    if (newRoutePoints.length > 1) {
      final polylines = await MapHelper.getRouteBetweenMultipleCoordinates(
        newRoutePoints,
        color: Colors.green,
      );
      if (!mounted) return;
      setState(() {
        _routePoints = newRoutePoints;
        _markers = newMarkers;
        _polylines = polylines;
      });
      _fitMapToBounds(newRoutePoints);
    } else {
      if (!mounted) return;
      setState(() {
        _routePoints = newRoutePoints;
        _markers = newMarkers;
        _polylines = {};
      });
    }
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    
    if (points.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: points.first, zoom: 15.0),
          ));
        }
      });
      return;
    }

    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
      }
    });
  }

  Future<void> _showReviewBottomSheet(RentalTrip trip) async {
    RentalDriverBid? driver;
    if (trip.drivers.isNotEmpty) {
      driver = trip.drivers.firstWhere(
        (d) => d.bidStatus == 'ACCEPTED' || d.bidStatus == 'COMPLETED',
        orElse: () => trip.drivers.first,
      );
    }

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => TripReviewBottomSheet(
        trip: trip,
        driver: driver,
        customerUuid: widget.customerUuid,
      ),
    );

    if (result == true && mounted) {
      final updatedTrip = trip.copyWith(givenReview: true);
      context.read<ActiveTripBloc>().add(UpdateActiveTripLocalReview(updatedTrip));
    }
  }

  Future<void> _cancelTrip(BuildContext context, RentalTrip trip, bool isDark) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelTripDialog(isDark: isDark),
    );

    if (reason != null && reason.isNotEmpty && mounted) {
      final loc = AppLocalizations.of(context);
      context.read<ActiveTripBloc>().add(
        CancelActiveTrip(
          tripUuid: trip.uuid ?? "",
          comment: reason,
          languageCode: loc.locale.languageCode,
        ),
      );
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * (math.pi / 180.0);
    final double lng1 = start.longitude * (math.pi / 180.0);
    final double lat2 = end.latitude * (math.pi / 180.0);
    final double lng2 = end.longitude * (math.pi / 180.0);

    final double dLng = lng2 - lng1;

    final double y = math.sin(dLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final double bearing = math.atan2(y, x) * (180.0 / math.pi);
    return (bearing + 360.0) % 360.0;
  }

  Future<void> _updateDriverMarker(RentalTrip trip, double? lat, double? lng) async {
    if (lat == null || lng == null) {
      if (_driverMarker != null) {
        setState(() {
          _markers.remove(_driverMarker);
          _driverMarker = null;
        });
      }
      return;
    }

    final bool isFirstLoad = _driverMarker == null;
    final position = LatLng(lat, lng);
    final carType = trip.carCategory?.carType;

    if (_driverMarker != null) {
      final prevPos = _driverMarker!.position;
      if (prevPos.latitude != position.latitude || prevPos.longitude != position.longitude) {
        _driverRotation = _calculateBearing(prevPos, position);
      }
    }

    final lower = carType?.toLowerCase() ?? '';
    final bool isBike = lower.contains('bike') || lower.contains('motor');
    final Color vehicleColor = isBike ? const Color(0xFFF44336) : const Color(0xFF4CAF50);

    final BitmapDescriptor icon = await _getMarkerIconFromIconData(
      carType,
      vehicleColor,
      80.0,
    );

    final newMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: position,
      icon: icon,
      rotation: _driverRotation,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: trip.drivers.isNotEmpty ? trip.drivers.first.name : "Driver"),
    );

    if (mounted) {
      setState(() {
        if (_driverMarker != null) {
          _markers.removeWhere((m) => m.markerId == const MarkerId('driver_location'));
        }
        _driverMarker = newMarker;
        _markers.add(newMarker);
      });

      if (isFirstLoad && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 16.5,
            tilt: 35.0,
          ),
        ));
      }
    }
  }

  Future<BitmapDescriptor> _getMarkerIconFromIconData(String? carType, Color color, double size) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final sizeObj = Size(size, size);

    final lower = carType?.toLowerCase() ?? '';
    final bool isBike = lower.contains('bike') || lower.contains('motor');

    if (isBike) {
      _paintTopDownBike(canvas, sizeObj, color);
    } else {
      _paintTopDownCar(canvas, sizeObj, color);
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _paintTopDownCar(Canvas canvas, Size size, Color color) {
    final double w = size.width;
    final double h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;
    
    final double cx = w / 2;
    final double cy = h / 2;

    // 1. Draw dynamic soft drop shadow around the whole vehicle
    paint.color = Colors.black.withAlpha(40);
    final shadowPath = Path()
      ..moveTo(cx - w * 0.22, cy - h * 0.38)
      ..quadraticBezierTo(cx, cy - h * 0.44, cx + w * 0.22, cy - h * 0.38)
      ..lineTo(cx + w * 0.24, cy + h * 0.38)
      ..quadraticBezierTo(cx, cy + h * 0.44, cx - w * 0.24, cy + h * 0.38)
      ..close();
    canvas.drawPath(shadowPath, paint);

    // 2. Draw 4 wheels (tires)
    paint.color = const Color(0xFF1A1A1A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.28, cy - h * 0.28, w * 0.08, h * 0.16), Radius.circular(w * 0.02)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.20, cy - h * 0.28, w * 0.08, h * 0.16), Radius.circular(w * 0.02)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.28, cy + h * 0.14, w * 0.08, h * 0.18), Radius.circular(w * 0.02)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.20, cy + h * 0.14, w * 0.08, h * 0.18), Radius.circular(w * 0.02)), paint);

    // 3. Draw main body chassis (Light Green)
    paint.color = const Color(0xFF4CAF50);
    final bodyPath = Path()
      ..moveTo(cx - w * 0.20, cy - h * 0.35)
      ..quadraticBezierTo(cx - w * 0.18, cy - h * 0.40, cx, cy - h * 0.42)
      ..quadraticBezierTo(cx + w * 0.18, cy - h * 0.40, cx + w * 0.20, cy - h * 0.35)
      ..lineTo(cx + w * 0.22, cy - h * 0.10)
      ..quadraticBezierTo(cx + w * 0.24, cy, cx + w * 0.22, cy + h * 0.20)
      ..lineTo(cx + w * 0.20, cy + h * 0.38)
      ..quadraticBezierTo(cx, cy + h * 0.41, cx - w * 0.20, cy + h * 0.38)
      ..lineTo(cx - w * 0.22, cy + h * 0.20)
      ..quadraticBezierTo(cx - w * 0.24, cy, cx - w * 0.22, cy - h * 0.10)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // 4. Draw top/front hood cover (Red)
    paint.color = const Color(0xFFF44336);
    final hoodPath = Path()
      ..moveTo(cx - w * 0.20, cy - h * 0.35)
      ..quadraticBezierTo(cx - w * 0.18, cy - h * 0.40, cx, cy - h * 0.42)
      ..quadraticBezierTo(cx + w * 0.18, cy - h * 0.40, cx + w * 0.20, cy - h * 0.35)
      ..lineTo(cx + w * 0.21, cy - h * 0.15)
      ..quadraticBezierTo(cx, cy - h * 0.10, cx - w * 0.21, cy - h * 0.15)
      ..close();
    canvas.drawPath(hoodPath, paint);

    // 5. Side mirrors (Red)
    paint.color = const Color(0xFFF44336);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.27, cy - h * 0.20, w * 0.06, h * 0.06), Radius.circular(w * 0.01)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + w * 0.21, cy - h * 0.20, w * 0.06, h * 0.06), Radius.circular(w * 0.01)), paint);

    // 6. Draw front windshield, side windows, rear windshield (Cabin area)
    paint.color = const Color(0xFF1E2124);
    
    final windshieldPath = Path()
      ..moveTo(cx - w * 0.15, cy - h * 0.16)
      ..lineTo(cx + w * 0.15, cy - h * 0.16)
      ..quadraticBezierTo(cx + w * 0.12, cy - h * 0.26, cx, cy - h * 0.27)
      ..quadraticBezierTo(cx - w * 0.12, cy - h * 0.26, cx - w * 0.15, cy - h * 0.16)
      ..close();
    canvas.drawPath(windshieldPath, paint);

    paint.color = const Color(0xFFE0E0E0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.15, cy - h * 0.16, w * 0.30, h * 0.32),
        Radius.circular(w * 0.02),
      ),
      paint,
    );

    paint.color = const Color(0xFF1E2124);
    final rearWindowPath = Path()
      ..moveTo(cx - w * 0.14, cy + h * 0.16)
      ..lineTo(cx + w * 0.14, cy + h * 0.16)
      ..quadraticBezierTo(cx + w * 0.11, cy + h * 0.24, cx, cy + h * 0.25)
      ..quadraticBezierTo(cx - w * 0.11, cy + h * 0.24, cx - w * 0.14, cy + h * 0.16)
      ..close();
    canvas.drawPath(rearWindowPath, paint);

    // 7. Draw headlights
    paint.color = const Color(0xFFFFEB3B);
    canvas.drawArc(Rect.fromLTWH(cx - w * 0.18, cy - h * 0.43, w * 0.07, h * 0.04), 3.14, 3.14, true, paint);
    canvas.drawArc(Rect.fromLTWH(cx + w * 0.11, cy - h * 0.43, w * 0.07, h * 0.04), 3.14, 3.14, true, paint);

    // 8. Draw red rear taillights
    paint.color = const Color(0xFFF44336);
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.17, cy + h * 0.37, w * 0.06, h * 0.02), paint);
    canvas.drawRect(Rect.fromLTWH(cx + w * 0.11, cy + h * 0.37, w * 0.06, h * 0.02), paint);
  }

  void _paintTopDownBike(Canvas canvas, Size size, Color color) {
    final double w = size.width;
    final double h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;
    
    final double cx = w / 2;
    final double cy = h / 2;

    // 1. Shadow backing
    paint.color = Colors.black.withAlpha(35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.16, cy - h * 0.40, w * 0.32, h * 0.82),
        Radius.circular(w * 0.08),
      ),
      paint,
    );

    // 2. Main framework
    paint.color = const Color(0xFF222222);
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.04, cy - h * 0.30, w * 0.08, h * 0.60), paint);

    // 3. Thick front tire
    paint.color = Colors.black;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.03, cy - h * 0.42, w * 0.06, h * 0.20),
        Radius.circular(w * 0.015),
      ),
      paint,
    );

    // 4. Rear tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.04, cy + h * 0.22, w * 0.08, h * 0.24),
        Radius.circular(w * 0.02),
      ),
      paint,
    );

    // 5. Handlebars (Red top side)
    paint.color = const Color(0xFFF44336);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * 0.22, cy - h * 0.26, w * 0.44, h * 0.035), Radius.circular(w * 0.01)), paint);
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.24, cy - h * 0.26, w * 0.04, h * 0.035), paint);
    canvas.drawRect(Rect.fromLTWH(cx + w * 0.20, cy - h * 0.26, w * 0.04, h * 0.035), paint);

    // 6. Gas tank & body shell (Light Green)
    paint.color = const Color(0xFF4CAF50);
    final bodyPath = Path()
      ..moveTo(cx - w * 0.06, cy - h * 0.20)
      ..lineTo(cx + w * 0.06, cy - h * 0.20)
      ..quadraticBezierTo(cx + w * 0.12, cy - h * 0.05, cx + w * 0.08, cy + h * 0.10)
      ..lineTo(cx - w * 0.08, cy + h * 0.10)
      ..quadraticBezierTo(cx - w * 0.12, cy - h * 0.05, cx - w * 0.06, cy - h * 0.20)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Seat detail
    paint.color = const Color(0xFF1A1A1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.05, cy + h * 0.02, w * 0.10, h * 0.18),
        Radius.circular(w * 0.02),
      ),
      paint,
    );

    // Headlight front beam
    paint.color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(cx, cy - h * 0.44), w * 0.025, paint);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
      body: BlocListener<ActiveTripBloc, ActiveTripState>(
        listener: (context, state) {
          if (state is ActiveTripSuccess) {
            final trip = state.activeTrip;
            final oldTrip = _activeTrip;
            _activeTrip = trip;

            if (oldTrip?.uuid != trip.uuid) {
              _fetchRoutePolylinesForTrip(trip);
            }

            _updateDriverMarker(trip, state.driverLatitude, state.driverLongitude);

            if (trip.tripStatus == TripStatus.completed && trip.givenReview != true) {
              if (!_isReviewSheetShown) {
                _isReviewSheetShown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showReviewBottomSheet(trip);
                });
              }
            }
          } else if (state is ActiveTripCancelledSuccess) {
            UiUtils.showAppSnackBar(context, state.message, type: 'success');
            Navigator.of(context).pop();
          } else if (state is ActiveTripFailure) {
            UiUtils.showAppSnackBar(context, state.error, type: 'error');
          }
        },
        child: BlocBuilder<ActiveTripBloc, ActiveTripState>(
          builder: (context, state) {
            if (state is ActiveTripLoading && _activeTrip == null) {
              return Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black));
            }

            if (state is ActiveTripFailure && _activeTrip == null) {
              return _buildErrorScreen(state.error);
            }

            if (state is NoActiveTrip && _activeTrip == null) {
              return _buildErrorScreen(state.message);
            }

            if (_activeTrip == null) {
              return Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black));
            }

            final trip = _activeTrip!;
            final driver = trip.drivers.isNotEmpty
                ? trip.drivers.firstWhere(
                    (d) => d.bidStatus == 'ACCEPTED' || d.bidStatus == 'COMPLETED',
                    orElse: () => trip.drivers.first)
                : null;

            final LatLng initialCameraPosition = _routePoints.isNotEmpty ? _routePoints.first : const LatLng(23.8103, 90.4125);

            return Stack(
              children: [
                // Map View
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialCameraPosition,
                      zoom: 14.0,
                    ),
                    zoomControlsEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_routePoints.isNotEmpty) {
                        _fitMapToBounds(_routePoints);
                      }
                    },
                    polylines: _polylines,
                    markers: _markers,
                  ),
                ),

                // Back Button
                Positioned(
                  top: 50,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),

                // Bottom Panel Details
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomSheet(isDark, trip, driver, loc),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Go Back"),
          )
        ],
      ),
    );
  }

  Widget _buildBottomSheet(bool isDark, RentalTrip trip, RentalDriverBid? driver, AppLocalizations loc) {
    double? driverLat;
    double? driverLng;
    final state = context.read<ActiveTripBloc>().state;
    if (state is ActiveTripSuccess) {
      driverLat = state.driverLatitude;
      driverLng = state.driverLongitude;
    }

    int? etaMinutes;
    String? etaLabel;

    if (driverLat != null && driverLng != null) {
      if (trip.tripStatus == TripStatus.rideStarted || trip.tripStatus == TripStatus.inProgress) {
        if (trip.dropoffLocations.isNotEmpty) {
          final destLat = double.tryParse(trip.dropoffLocations.first.latitude ?? '');
          final destLng = double.tryParse(trip.dropoffLocations.first.longitude ?? '');
          if (destLat != null && destLng != null) {
            final double distanceInMeters = Geolocator.distanceBetween(driverLat, driverLng, destLat, destLng);
            etaMinutes = (distanceInMeters / 300.0).ceil().clamp(1, 120);
            etaLabel = "Arriving at destination in $etaMinutes ${etaMinutes == 1 ? 'minute' : 'minutes'}";
          }
        }
      } else if (trip.tripStatus == TripStatus.arrivedPickupLocation) {
        etaLabel = "Driver has arrived at pickup location";
      } else {
        if (trip.pickupLocations.isNotEmpty) {
          final pickLat = double.tryParse(trip.pickupLocations.first.latitude ?? '');
          final pickLng = double.tryParse(trip.pickupLocations.first.longitude ?? '');
          if (pickLat != null && pickLng != null) {
            final double distanceInMeters = Geolocator.distanceBetween(driverLat, driverLng, pickLat, pickLng);
            etaMinutes = (distanceInMeters / 300.0).ceil().clamp(1, 120);
            etaLabel = "Driver arrives in $etaMinutes ${etaMinutes == 1 ? 'minute' : 'minutes'}";
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRouteProgress(isDark, trip, loc),
          ),
          const SizedBox(height: 12),

          if (etaLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.black12 : Colors.white10,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 10 : 15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled,
                    color: isDark ? Colors.black : Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    etaLabel,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Driver Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252833) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: (driver?.profilePicture != null && AppUrls.getImageUrl(driver!.profilePicture) != null)
                            ? NetworkImage(AppUrls.getImageUrl(driver!.profilePicture)!)
                            : null,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        child: (driver?.profilePicture == null || AppUrls.getImageUrl(driver!.profilePicture) == null)
                            ? Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black54)
                            : null,
                      ),
                      Positioned(
                        bottom: -8,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                driver?.averageRating?.toStringAsFixed(1) ?? "0.0",
                                style: GoogleFonts.poppins(color: isDark ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.star, color: isDark ? Colors.black : Colors.white, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver?.name ?? (loc.translate('n_a') == 'n_a' ? "N/A" : loc.translate('n_a')),
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            driver?.carRegNumber ?? (loc.translate('n_a') == 'n_a' ? "N/A" : loc.translate('n_a')),
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${loc.translate('trips') == 'trips' ? 'trips' : loc.translate('trips')} (${driver?.totalCompletedTrips ?? 0})",
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trip.carCategory?.carType ?? "",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (driver?.phone != null && driver!.phone!.isNotEmpty && driver.phone != 'N/A')
                        GestureDetector(
                          onTap: () => ActiveTripHelper.launchCallOrUrl(context, "tel:${driver.phone}"),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call, color: isDark ? Colors.white : Colors.black, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                loc.translate('call') == 'call' ? "Call" : loc.translate('call'),
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Button Area
          if (trip.tripStatus == TripStatus.completed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: trip.givenReview == true
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade400, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Trip Completed — Thank you for your review!",
                            style: GoogleFonts.poppins(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _showReviewBottomSheet(trip),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.star_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              "Give Review",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            )
          else if (trip.tripStatus == TripStatus.rideStarted || trip.tripStatus == TripStatus.inProgress || trip.tripStatus == TripStatus.firstCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 56,
                      color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                    ),
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double progress = 0.1;
                          if (trip.tripStatus == TripStatus.arrivedPickupLocation) progress = 0.2;
                          if (trip.tripStatus == TripStatus.rideStarted) progress = 0.4;
                          if (trip.tripStatus == TripStatus.inProgress) progress = 0.6;
                          if (trip.tripStatus == TripStatus.firstCompleted) progress = 0.75;
                          
                          return AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOut,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * progress,
                              color: isDark ? Colors.white.withAlpha(60) : Colors.black.withAlpha(50),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 56,
                      alignment: Alignment.center,
                      child: Text(
                        loc.translate('in_progress') == 'in_progress' ? "In Progress..." : loc.translate('in_progress'),
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (trip.tripStatus != TripStatus.completed &&
              trip.tripStatus != TripStatus.cancelled &&
              trip.tripStatus != TripStatus.rideStarted &&
              trip.tripStatus != TripStatus.inProgress &&
              trip.tripStatus != TripStatus.firstCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _cancelTrip(context, trip, isDark),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.translate('cancel_trip') == 'cancel_trip' ? "Cancel Trip" : loc.translate('cancel_trip'),
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRouteProgress(bool isDark, RentalTrip trip, AppLocalizations loc) {
    List<LocationModel> allLocations = [];
    if (trip.tripStatus == TripStatus.firstCompleted) {
      allLocations.addAll(trip.dropoffLocations);
      allLocations.addAll(trip.pickupLocations);
    } else {
      allLocations.addAll(trip.pickupLocations);
      allLocations.addAll(trip.dropoffLocations);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isRouteExpanded = !_isRouteExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('route_progress') == 'route_progress' ? "Route Progress" : loc.translate('route_progress'),
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${ActiveTripHelper.formatServiceName(trip.serviceName)} • ${allLocations.length} locations",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isRouteExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (trip.startDatetime != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.tripStatus == TripStatus.firstCompleted ? "End Time" : "Start Time",
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ActiveTripHelper.formatDate(trip.tripStatus == TripStatus.firstCompleted ? trip.endDatetime : trip.startDatetime),
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
                          ActiveTripHelper.formatDate(trip.endDatetime),
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
                color: Colors.grey.withOpacity(0.3),
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
              alignment: trip.tripStatus == TripStatus.accepted ? const Alignment(-1.0, 0) : const Alignment(-0.5, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(ActiveTripHelper.getVehicleIcon(trip.carCategory?.carType), color: isDark ? Colors.black : Colors.white, size: 16),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isRouteExpanded
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
                                      color: Colors.grey.withOpacity(0.3),
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
    );
  }
}
