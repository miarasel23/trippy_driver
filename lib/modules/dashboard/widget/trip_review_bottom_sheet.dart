import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_urls.dart';
import '../../../routes/app_routes.dart';
import '../model/create_rental_trip_model.dart';
import '../repository/create_trip_repository.dart';

class TripReviewBottomSheet extends StatefulWidget {
  final RentalTrip trip;
  final RentalDriverBid? driver;
  final String customerUuid;

  const TripReviewBottomSheet({
    Key? key,
    required this.trip,
    required this.driver,
    required this.customerUuid,
  }) : super(key: key);

  @override
  State<TripReviewBottomSheet> createState() => _TripReviewBottomSheetState();
}

class _TripReviewBottomSheetState extends State<TripReviewBottomSheet> {
  int _selectedRating = 1;
  List<String> _selectedCompliments = [];
  bool _isSubmitting = false;
  final TextEditingController _otherCommentController = TextEditingController();

  final List<String> _availableCompliments = [
    "Clean car",
    "Great music",
    "Professional",
    "Smooth ride",
    "Others"
  ];

  @override
  void dispose() {
    _otherCommentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final loc = AppLocalizations.of(context);

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('please_select_rating') == 'please_select_rating' ? 'Please select a rating' : loc.translate('please_select_rating'))),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = CreateTripRepository();
      
      List<String> finalComments = List.from(_selectedCompliments);
      if (finalComments.contains("Others") && _otherCommentController.text.trim().isNotEmpty) {
        finalComments.remove("Others");
        finalComments.add(_otherCommentController.text.trim());
      }
      final String comments = finalComments.join(', ');

      await repo.giveReview(
        tripUuid: widget.trip.uuid ?? '',
        customerUuid: widget.customerUuid,
        driverUuid: widget.driver?.driverUuid ?? '',
        rating: _selectedRating.toDouble(),
        comments: comments,
        langCode: loc.locale.languageCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('review_submitted') == 'review_submitted' ? 'Review submitted successfully!' : loc.translate('review_submitted'))),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.bottomNav,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = loc.translate('error_submitting_review') == 'error_submitting_review' ? 'Error submitting review:' : loc.translate('error_submitting_review');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMsg ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2D35) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  String _formatTimeTo12Hour(String? datetimeStr) {
    if (datetimeStr == null || datetimeStr.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(datetimeStr);
      final amPm = dt.hour >= 12 ? "PM" : "AM";
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final hourStr = hour12.toString().padLeft(2, '0');
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      return "$hourStr:$minuteStr $amPm";
    } catch (_) {
      if (datetimeStr.contains(' ')) {
        return datetimeStr.split(' ').last.substring(0, 5);
      }
      return datetimeStr;
    }
  }

  String _formatDateToLocal(String? datetimeStr) {
    if (datetimeStr == null || datetimeStr.isEmpty) return 'Today';
    try {
      final dt = DateTime.parse(datetimeStr);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dt.day} ${months[dt.month - 1]}, ${dt.year}";
    } catch (_) {
      return datetimeStr.split(' ').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final driver = widget.driver;
    final trip = widget.trip;
    
    final dateDisplay = _formatDateToLocal(trip.startDatetime);
    String timeDisplay = '--:--';
    if (trip.startDatetime != null) {
      timeDisplay = _formatTimeTo12Hour(trip.startDatetime);
      if (trip.endDatetime != null) {
        timeDisplay += " - ${_formatTimeTo12Hour(trip.endDatetime)}";
      }
    }
    
    final finalFare = driver?.totalAmount?.toStringAsFixed(2) ?? trip.offerAmount?.toStringAsFixed(2) ?? '0.00';
    final paymentMethod = trip.paymentMethod ?? 'CASH';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: PopScope(
        canPop: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E26) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Replaces back button to maintain spacing
                Text(
                  loc.translate('trip_details') == 'trip_details' ? "Trip Details" : loc.translate('trip_details'),
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.help_outline, color: isDark ? Colors.white : Colors.black),
                  onPressed: () {}, // Add help action if needed
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Success Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: isDark ? Colors.black : Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    loc.translate('trip_completed') == 'trip_completed' ? "Trip Completed" : loc.translate('trip_completed'),
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.translate('hope_you_enjoyed') == 'hope_you_enjoyed' ? "Hope you enjoyed the ride!" : loc.translate('hope_you_enjoyed'),
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Final Fare Card
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        Text(
                          loc.translate('final_fare') == 'final_fare' ? "FINAL FARE" : loc.translate('final_fare'),
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$$finalFare",
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card, color: isDark ? Colors.white70 : Colors.black87, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "${loc.translate('paid_via') == 'paid_via' ? 'Paid via' : loc.translate('paid_via')} $paymentMethod",
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time and Route Card
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: isDark ? Colors.white70 : Colors.black87, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  dateDisplay,
                                  style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time, color: isDark ? Colors.white70 : Colors.black87, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  timeDisplay,
                                  style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? const Color(0xFF1C1E26) : Colors.white, width: 2),
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : Colors.black,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? const Color(0xFF1C1E26) : Colors.white, width: 2),
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
                                    loc.translate('pickup') == 'pickup' ? "Pickup" : loc.translate('pickup'),
                                    style: GoogleFonts.poppins(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    trip.pickupLocations.isNotEmpty ? (trip.pickupLocations.first.address ?? (loc.translate('unknown_pickup') == 'unknown_pickup' ? 'Unknown Pickup' : loc.translate('unknown_pickup'))) : (loc.translate('unknown_pickup') == 'unknown_pickup' ? 'Unknown Pickup' : loc.translate('unknown_pickup')),
                                    style: GoogleFonts.poppins(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc.translate('destination') == 'destination' ? "Destination" : loc.translate('destination'),
                                    style: GoogleFonts.poppins(
                                      color: isDark ? Colors.white54 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    trip.dropoffLocations.isNotEmpty ? (trip.dropoffLocations.first.address ?? (loc.translate('unknown_dropoff') == 'unknown_dropoff' ? 'Unknown Dropoff' : loc.translate('unknown_dropoff'))) : (loc.translate('unknown_dropoff') == 'unknown_dropoff' ? 'Unknown Dropoff' : loc.translate('unknown_dropoff')),
                                    style: GoogleFonts.poppins(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Driver and Rating Card
                  _buildCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Driver Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.white : Colors.black, width: 2),
                            image: DecorationImage(
                              image: (driver?.profilePicture != null
                                  ? NetworkImage(AppUrls.getImageUrl(driver!.profilePicture!) ?? '')
                                  : const AssetImage('assets/images/default_avatar.png')) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          driver?.name ?? (loc.translate('unknown_driver') == 'unknown_driver' ? 'Unknown Driver' : loc.translate('unknown_driver')),
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${trip.carCategory?.carType ?? 'Car'} • ${driver?.averageRating?.toStringAsFixed(1) ?? '0.0'}",
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            Icon(Icons.star, color: isDark ? Colors.white70 : Colors.black87, size: 14),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Interactive Star Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < _selectedRating ? Icons.star : Icons.star_border,
                                  color: index < _selectedRating ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26),
                                  size: 36,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          loc.translate('give_a_compliment') == 'give_a_compliment' ? "GIVE A COMPLIMENT" : loc.translate('give_a_compliment'),
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Compliments
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _availableCompliments.map((compliment) {
                            final isSelected = _selectedCompliments.contains(compliment);
                            
                            String displayCompliment = compliment;
                            if (compliment == "Clean car") displayCompliment = loc.translate('clean_car') == 'clean_car' ? "Clean car" : loc.translate('clean_car');
                            else if (compliment == "Great music") displayCompliment = loc.translate('great_music') == 'great_music' ? "Great music" : loc.translate('great_music');
                            else if (compliment == "Professional") displayCompliment = loc.translate('professional') == 'professional' ? "Professional" : loc.translate('professional');
                            else if (compliment == "Smooth ride") displayCompliment = loc.translate('smooth_ride') == 'smooth_ride' ? "Smooth ride" : loc.translate('smooth_ride');
                            else if (compliment == "Others") displayCompliment = loc.translate('others') == 'others' ? "Others" : loc.translate('others');

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCompliments.remove(compliment);
                                  } else {
                                    _selectedCompliments.add(compliment);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? (isDark ? Colors.white24 : Colors.black12) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  displayCompliment,
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white70 : Colors.black87),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedCompliments.contains("Others")) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otherCommentController,
                            style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: loc.translate('write_your_compliment') == 'write_your_compliment' ? "Write your compliment..." : loc.translate('write_your_compliment'),
                              hintStyle: GoogleFonts.poppins(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                              filled: true,
                              fillColor: isDark ? Colors.black12 : Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  // Submit Rating Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.black54 : Colors.white70),
                              ),
                            )
                          : Text(
                              loc.translate('submit_rating') == 'submit_rating' ? "Submit Rating" : loc.translate('submit_rating'),
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
