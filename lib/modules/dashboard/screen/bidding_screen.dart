import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/app_colors.dart';
import '../model/create_rental_trip_model.dart';
import '../repository/create_trip_repository.dart';
import '../../../widgets/radar_animation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../../main.dart';
import '../../../widgets/cancel_trip_dialog.dart';
import '../widget/bidding_searching_state.dart';
import '../widget/bidding_trip_details_card.dart';
import '../widget/bidding_list_widget.dart';
import '../../../utils/app_urls.dart';
import '../../../routes/app_routes.dart';

class BiddingScreen extends StatefulWidget {
  final String customerUuid;
  final String tripUuid;

  const BiddingScreen({super.key, required this.customerUuid, this.tripUuid = ""});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  // BUG FIX: Use nullable Timer to prevent crash in dispose() if init fails
  Timer? _pollingTimer;
  final CreateTripRepository _repo = CreateTripRepository();
  bool _isLoading = true;
  RentalTrip? _currentTrip;
  String? _errorMessage;
  int _previousDriverCount = 0;

  bool _isInit = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _isInit = true;
      _startPolling();
    }
  }

  Future<void> _acceptTrip(BuildContext context, bool isDark, RentalDriverBid bid) async {
    final loc = AppLocalizations.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1E26) : Colors.white,
        title: Text(
          loc.translate("accept_trip_confirm") ?? "Are you sure you want to accept this trip?",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.translate("no") ?? "No", style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: isDark ? Colors.white : Colors.black),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc.translate("yes") ?? "Yes", 
              style: GoogleFonts.poppins(
                color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && _currentTrip != null) {
      final bgColor = isDark ? Colors.white : Colors.black;
      final textColor = isDark ? Colors.black : Colors.white;
      try {

        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text("Accepting trip...", style: TextStyle(color: textColor)), 
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating
          ),
        );
        
        final response = await _repo.acceptTrip(
          customerUuid: widget.customerUuid,
          bidUuid: bid.rentBidUuid ?? "",
          langCode: loc.locale.languageCode,
        );

        globalScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        globalScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Trip accepted successfully", style: TextStyle(color: textColor)),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        _pollingTimer?.cancel(); // null-safe cancel before navigation
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.activeTrip,
            arguments: widget.customerUuid,
          );
        }
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

  Future<void> _cancelTrip(BuildContext context, bool isDark) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => CancelTripDialog(isDark: isDark),
    );

    if (reason != null && reason.isNotEmpty && _currentTrip != null) {
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
        final response = await _repo.cancelTrip(
          tripUuid: _currentTrip!.uuid ?? "",
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
        
        _pollingTimer?.cancel(); // null-safe cancel before navigation
        if (mounted) {
          Navigator.of(context).pop(true);
        }
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

  void _startPolling() {
    _fetchBids(); // Initial fetch
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchBids();
    });
  }

  Future<void> _fetchBids() async {
    try {
      final loc = AppLocalizations.of(context);
      final response = await _repo.fetchBids(
        customerUuid: widget.customerUuid,
        langCode: loc.locale.languageCode,
      );

      if (mounted) {
        setState(() {
          if (response.trips.isNotEmpty) {
            if (widget.tripUuid.isNotEmpty) {
              try {
                _currentTrip = response.trips.firstWhere((t) => t.uuid == widget.tripUuid);
              } catch (_) {
                _currentTrip = response.trips.first;
              }
            } else {
              _currentTrip = response.trips.first;
            }
            
            int currentDriverCount = _currentTrip!.drivers.length;
            if (currentDriverCount > _previousDriverCount) {
              FlutterRingtonePlayer().play(
                fromAsset: "assets/sounds/ride_request.wav",
                looping: true,
                volume: 1.0,
                asAlarm: true,
              );
              // Stop the sound after 10 seconds
              Future.delayed(const Duration(seconds: 10), () {
                FlutterRingtonePlayer().stop();
              });
              
              _previousDriverCount = currentDriverCount;
            }
          }
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final isConnectionError = e.toString().contains('Connection closed') || 
                                   e.toString().contains('ClientException') ||
                                   e.toString().contains('SocketException') ||
                                   e.toString().contains('HttpException');
        setState(() {
          _isLoading = false;
          if (!isConnectionError) {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // BUG FIX: null-safe cancel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine title text
    String titleText = "Finding your ride";
    String subtitleText = _currentTrip?.serviceName?.replaceAll('_', ' ') ?? "TRIPPY RIDE PREMIUM";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13151B) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              titleText,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              subtitleText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              backgroundImage: AppUrls.profileImageUrl != null
                  ? NetworkImage(AppUrls.profileImageUrl!)
                  : null,
              child: AppUrls.profileImageUrl == null
                  ? Icon(Icons.person, size: 20, color: isDark ? Colors.white70 : Colors.black54)
                  : null,
            ),
          )
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _currentTrip == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _currentTrip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Error fetching trip: $_errorMessage",
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_currentTrip == null) {
      return Center(
        child: Text(
          "No trip requested yet.",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    bool hasBids = _currentTrip!.drivers.isNotEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: isDark ? const Color(0xFF13151B) : Colors.white),
        ),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: hasBids 
                  ? BiddingListWidget(
                      isDark: isDark, 
                      currentTrip: _currentTrip!, 
                      onAcceptBid: (bid) => _acceptTrip(context, isDark, bid),
                    ) 
                  : BiddingSearchingState(isDark: isDark),
              ),
              BiddingTripDetailsCard(
                isDark: isDark, 
                currentTrip: _currentTrip!,
                onCancel: () => _cancelTrip(context, isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
