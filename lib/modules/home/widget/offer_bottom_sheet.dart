import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import 'translated_text.dart';

class OfferBottomSheet extends StatefulWidget {
  final RentalTripModel trip;
  final bool isRideShare;

  const OfferBottomSheet({super.key, required this.trip, required this.isRideShare});

  static void show(BuildContext context, RentalTripModel trip, bool isRideShare) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // Allow map to be visible
      builder: (ctx) {
        return BlocProvider.value(
          value: context.read<HomeController>(),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: OfferBottomSheet(trip: trip, isRideShare: isRideShare),
          ),
        );
      },
    );
  }

  @override
  State<OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<OfferBottomSheet> {
  late TextEditingController _bidController;
  String? _bidError;
  bool _isSubmitting = false;
  bool _isEditingFare = false;

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(text: widget.trip.customerOfferAmmount.round().toString());
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  void _validateBid(String val) {
    if (val.isEmpty) {
      setState(() => _bidError = null);
      return;
    }
    final amt = double.tryParse(val);
    if (amt == null) {
      setState(() => _bidError = "Invalid amount");
      return;
    }
    final baseAmount = widget.trip.customerOfferAmmount;
    final maxBid = baseAmount * 3;
    final minBid = baseAmount * 0.1;
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final currency = isBangla ? '৳' : 'BDT';
    
    if (amt > maxBid) {
      setState(() => _bidError = "\${loc.translate('max_bid_is') ?? 'Max bid is'} $currency\${maxBid.round()}");
    } else if (amt < minBid) {
      setState(() => _bidError = "\${loc.translate('min_bid_is') ?? 'Min bid is'} $currency\${minBid.round()}");
    } else {
      setState(() => _bidError = null);
    }
  }

  Future<void> _submitBid(double amount) async {
    setState(() => _isSubmitting = true);
    final error = await context.read<HomeController>().submitBid(widget.trip.uuid, amount);
    if (mounted) {
      setState(() => _isSubmitting = false);
      final loc = AppLocalizations.of(context);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('wait_customer_acceptance') ?? 'Waiting for customer acceptance...'), backgroundColor: Colors.green));
        Navigator.pop(context); // Close bottom sheet
      }
    }
  }

  String _toBanglaDigits(String input) {
    const englishToBanglaDigits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };
    return input.split('').map((char) => englishToBanglaDigits[char] ?? char).join();
  }
  
  String _translateNumbersAndCommonWords(String text, bool isBangla) {
    if (!isBangla) return text;
    String result = _toBanglaDigits(text);
    result = result.replaceAll(' km', ' কি.মি.');
    result = result.replaceAll(' away', ' দূরে');
    result = result.replaceAll('~', '~');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final currency = isBangla ? '৳' : 'BDT';
    
    final baseAmount = widget.trip.customerOfferAmmount;
    final formattedAmount = _translateNumbersAndCommonWords("${baseAmount.round()}", isBangla);
    
    final bid10 = (baseAmount * 1.10).round();
    final bid18 = (baseAmount * 1.18).round();

    final pickupAddress = widget.trip.pickupLocations.isNotEmpty ? widget.trip.pickupLocations.first.address : '';
    final dropoffAddress = widget.trip.dropoffLocations.isNotEmpty ? widget.trip.dropoffLocations.first.address : '';
    
    final distanceText = "~${widget.trip.totalDistance} km";
    final customerAvatar = widget.trip.customer.isNotEmpty ? widget.trip.customer.first.profilePicture : '';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header profile and distance
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: customerAvatar.isNotEmpty
                        ? NetworkImage(customerAvatar)
                        : null,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: customerAvatar.isEmpty
                        ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          distanceText,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                        ),
                        Text(
                          "$currency$formattedAmount",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Locations
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
                    alignment: Alignment.center,
                    child: const Text('A', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TranslatedText(
                      pickupAddress,
                      isBangla: isBangla,
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                    alignment: Alignment.center,
                    child: const Text('B', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TranslatedText(
                      dropoffAddress,
                      isBangla: isBangla,
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Accept Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submitBid(baseAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.surface))
                  : Text(
                      "${loc.translate('accept_for') ?? 'Accept for'} $currency$formattedAmount",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
              ),
              
              const SizedBox(height: 24),
              
              if (widget.isRideShare) ...[
                Text(
                  loc.translate('offer_your_fare') ?? 'Offer your fare',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                if (_isEditingFare)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _bidController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            labelText: loc.translate('offer_amount') ?? 'Offer Amount',
                            labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                            errorText: _bidError,
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixText: '$currency ',
                            prefixStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          onChanged: _validateBid,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: _bidError != null ? 76 : 56,
                          child: ElevatedButton(
                            onPressed: (_bidError == null && !_isSubmitting) 
                              ? () {
                                  final amount = double.tryParse(_bidController.text);
                                  if (amount != null) {
                                    _submitBid(amount);
                                  }
                                }
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.onSurface,
                              foregroundColor: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              loc.translate('bid_now') ?? 'Bid',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _submitBid(bid10.toDouble()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "$currency${_translateNumbersAndCommonWords(bid10.toString(), isBangla)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _submitBid(bid18.toDouble()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            "$currency${_translateNumbersAndCommonWords(bid18.toString(), isBangla)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEditingFare = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.edit, size: 20),
                      ),
                    ],
                  ),
              ],
              
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  loc.translate('close') ?? 'Close',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
