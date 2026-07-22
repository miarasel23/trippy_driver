import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../core/utils/ui_utils.dart';
import '../controller/home_controller.dart';
import '../model/rental_trip_model.dart';
import '../../../utils/app_urls.dart';
import '../helper/accepted_trip_card_helper.dart';

class ReviewBottomSheet extends StatefulWidget {
  final RentalTripModel trip;

  const ReviewBottomSheet({Key? key, required this.trip}) : super(key: key);

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _rating = 0;
  final Set<String> _selectedCompliments = {};
  bool _isSubmitting = false;
  final TextEditingController _customComplimentController = TextEditingController();

  @override
  void dispose() {
    _customComplimentController.dispose();
    super.dispose();
  }

  final List<String> _compliments = [
    'Clean car',
    'Great music',
    'Professional',
    'Smooth ride',
    'Others',
  ];

  void _submitReview() async {
    if (_rating == 0) {
      final loc = AppLocalizations.of(context);
      UiUtils.showAppSnackBar(context, loc.translate('please_select_rating') ?? 'Please select a rating', type: 'error');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final customerUuid = widget.trip.customer.isNotEmpty ? widget.trip.customer.first.customerUuid : '';
    String comments = _selectedCompliments.join(', ');
    if (_selectedCompliments.contains('Others') && _customComplimentController.text.trim().isNotEmpty) {
      comments += ' - ${_customComplimentController.text.trim()}';
    }

    final error = await context.read<HomeController>().submitReview(
      tripUuid: widget.trip.uuid,
      customerUuid: customerUuid,
      rating: _rating,
      comments: comments,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (error == null) {
        final loc = AppLocalizations.of(context);
        UiUtils.showAppSnackBar(context, loc.translate('review_submitted_successfully') ?? 'Review submitted successfully!', type: 'success');
        Navigator.of(context).pop();
      } else {
        UiUtils.showApiErrorPopup(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    
    final customer = widget.trip.customer.isNotEmpty ? widget.trip.customer.first : null;
    final customerName = customer?.name ?? loc.translate('customer') ?? 'Customer';
    final customerAvatar = customer?.profilePicture ?? '';
    final customerRating = customer != null ? customer.averageRating.toStringAsFixed(1) : '4.5';
    final displayRating = AcceptedTripCardHelper.translateNumbersAndCommonWords(customerRating, isBangla);

    final carType = widget.trip.carCategory.carType;
    
    final bidAmount = widget.trip.myBid?.amount ?? widget.trip.customerOfferAmmount;
    final totalAmount = widget.trip.myBid?.totalAmount ?? bidAmount;
    final currency = isBangla ? '৳' : 'BDT';
    final displayTotalAmount = AcceptedTripCardHelper.translateNumbersAndCommonWords(totalAmount.round().toString(), isBangla);
    
    final paymentMethod = widget.trip.paymentMethod ?? 'CASH';

    final pickupLoc = widget.trip.pickupLocations.isNotEmpty ? widget.trip.pickupLocations.first.address : 'Unknown';
    final dropoffLoc = widget.trip.dropoffLocations.isNotEmpty ? widget.trip.dropoffLocations.first.address : 'Unknown';

    DateTime? tripDate;
    try {
      tripDate = DateTime.parse(widget.trip.createdAt);
    } catch (e) {
      tripDate = DateTime.now();
    }
    
    final dateStr = DateFormat('dd MMM, yyyy').format(tripDate);
    final timeStr = DateFormat('hh:mm a').format(tripDate);
    final displayDate = AcceptedTripCardHelper.translateNumbersAndCommonWords(dateStr, isBangla);
    final displayTime = AcceptedTripCardHelper.translateNumbersAndCommonWords(timeStr, isBangla);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Balance for center alignment
                Text(
                  loc.translate('trip_details') ?? 'Trip Details',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.help_outline, color: theme.colorScheme.onSurface),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    loc.translate('trip_completed') ?? 'Trip Completed',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.translate('hope_you_enjoyed') ?? 'Hope you enjoyed the ride!',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Fare Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          loc.translate('final_fare') ?? 'FINAL FARE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currency $displayTotalAmount',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                              const SizedBox(width: 8),
                              Text(
                                '${loc.translate('paid_via') ?? 'Paid via'} $paymentMethod',
                                style: TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Timeline Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface),
                                const SizedBox(width: 8),
                                Text(
                                  displayDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface),
                                const SizedBox(width: 8),
                                Text(
                                  displayTime,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: theme.colorScheme.onSurface.withOpacity(0.2), thickness: 4),
                        const SizedBox(height: 12),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
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
                                    loc.translate('pickup') ?? 'Pickup',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                  Text(
                                    pickupLoc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    loc.translate('destination') ?? 'Destination',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                  Text(
                                    dropoffLoc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: customerAvatar.isNotEmpty
                              ? NetworkImage(customerAvatar.startsWith('http') ? customerAvatar : '${AppUrls.imageBaseUrl}$customerAvatar')
                              : null,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          child: customerAvatar.isEmpty
                              ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 40)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          customerName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$carType • $displayRating★',
                          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: index < _rating ? Colors.black : theme.colorScheme.onSurface.withOpacity(0.3),
                                  size: 40,
                                ),
                              ),
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          loc.translate('give_a_compliment') ?? 'GIVE A COMPLIMENT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _compliments.map((compliment) {
                            final isSelected = _selectedCompliments.contains(compliment);
                            return FilterChip(
                              label: Text(loc.translate(compliment.toLowerCase().replaceAll(' ', '_')) ?? compliment),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCompliments.add(compliment);
                                  } else {
                                    _selectedCompliments.remove(compliment);
                                  }
                                });
                              },
                              backgroundColor: Colors.transparent,
                              selectedColor: theme.colorScheme.onSurface.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : theme.colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        if (_selectedCompliments.contains('Others')) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                            child: TextField(
                              controller: _customComplimentController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: loc.translate('write_your_compliment') ?? 'Write your compliment...',
                                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Submit Button
          Container(
            padding: EdgeInsets.only(
              left: 20, 
              right: 20, 
              top: 16, 
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        loc.translate('submit_rating') ?? 'Submit Rating',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
