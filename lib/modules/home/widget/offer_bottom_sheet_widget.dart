import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import '../helper/accepted_trip_card_helper.dart';
import 'offer_bottom_sheet_helper.dart';

class OfferBottomSheet extends StatefulWidget {
  final RentalTripModel trip;
  final bool isRideShare;

  const OfferBottomSheet(
      {super.key, required this.trip, required this.isRideShare});

  static void show(
      BuildContext context, RentalTripModel trip, bool isRideShare) {
    final homeController = context.read<HomeController>();
    final scaffold = Scaffold.of(context);

    scaffold
        .showBottomSheet(
          backgroundColor: Colors.transparent,
          (ctx) {
            return BlocProvider.value(
              value: homeController,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: OfferBottomSheet(trip: trip, isRideShare: isRideShare),
              ),
            );
          },
        )
        .closed
        .then((_) {
          homeController.selectTripForPreview(null);
        });
  }

  @override
  State<OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<OfferBottomSheet> {
  late TextEditingController _bidController;
  String? _bidError;
  bool _isSubmitting = false;
  bool _isEditingFare = false;
  Timer? _timer;
  double _remainingSeconds = 60.0;
  double _totalSeconds = 60.0;

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(
        text: widget.trip.customerOfferAmmount.round().toString());

    final totalDuration = widget.isRideShare
        ? const Duration(minutes: 2)
        : const Duration(hours: 1);
    _totalSeconds = totalDuration.inSeconds.toDouble();

    final createdAtStr =
        widget.trip.myBid?.createdAt ?? widget.trip.createdAt;
    final createdAt = AcceptedTripCardHelper.parseCreatedAt(createdAtStr);
    final expireTime = createdAt.add(totalDuration);
    final remaining =
        expireTime.difference(AcceptedTripCardHelper.getNow());
    _remainingSeconds =
        remaining.isNegative ? 0.0 : remaining.inSeconds.toDouble();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remainingSeconds -= 1);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (mounted) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      setState(() => _bidError = 'Invalid amount');
      return;
    }
    final baseAmount = widget.trip.customerOfferAmmount;
    final maxBid = baseAmount * 3;
    final minBid = baseAmount * 0.1;
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final currency = isBangla ? '৳' : 'BDT';

    if (amt > maxBid) {
      final v = isBangla
          ? offerToBanglaDigits(maxBid.round().toString())
          : maxBid.round().toString();
      final String maxText = loc.translate('max_bid_is') ?? 'Max bid is';
      setState(() => _bidError = '$maxText $currency $v');
    } else if (amt < minBid) {
      final v = isBangla
          ? offerToBanglaDigits(minBid.round().toString())
          : minBid.round().toString();
      final String minText = loc.translate('min_bid_is') ?? 'Min bid is';
      setState(() => _bidError = '$minText $currency $v');
    } else {
      setState(() => _bidError = null);
    }
  }

  Future<void> _submitBid(double amount) async {
    setState(() => _isSubmitting = true);
    final error = await context
        .read<HomeController>()
        .submitBid(widget.trip.uuid, amount);
    if (mounted) {
      setState(() => _isSubmitting = false);
      final loc = AppLocalizations.of(context);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.translate('wait_customer_acceptance') ??
                'Waiting for customer acceptance...'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final currency = isBangla ? '৳' : 'BDT';

    final baseAmount = widget.trip.customerOfferAmmount;
    final formattedAmount =
        offerTranslate('${baseAmount.round()}', isBangla);
    final bid10 = (baseAmount * 1.10).round();
    final bid18 = (baseAmount * 1.18).round();

    final pickupLoc =
        AcceptedTripCardHelper.getEffectivePickup(widget.trip);
    final dropoffLoc =
        AcceptedTripCardHelper.getEffectiveDropoff(widget.trip);
    final pickupAddress = pickupLoc?.address ?? '';
    final dropoffAddress = dropoffLoc?.address ?? '';
    final distanceText =
        AcceptedTripCardHelper.calculateTripDistance(widget.trip);

    // The pickupKm-based time estimate is passed to OfferTimerHeader
    // via the trip model; no separate local variable needed here.

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer + service label + progress bar
              OfferTimerHeader(
                trip: widget.trip,
                isRideShare: widget.isRideShare,
                remainingSeconds: _remainingSeconds,
                totalSeconds: _totalSeconds,
                isBangla: isBangla,
              ),

              // Customer info row
              OfferCustomerRow(
                trip: widget.trip,
                isBangla: isBangla,
                currency: currency,
                formattedAmount: formattedAmount,
                distanceText: distanceText,
              ),
              const SizedBox(height: 10),

              // Date/times
              AcceptedTripCardHelper.buildTripDateTimes(
                  context, widget.trip, isBangla, theme),

              // Pickup location
              OfferLocationRow(
                label: 'A',
                dotColor: Colors.blueAccent,
                address: pickupAddress,
                isBangla: isBangla,
                location: pickupLoc,
              ),
              const SizedBox(height: 12),

              // Dropoff location
              OfferLocationRow(
                label: 'B',
                dotColor: Colors.green,
                address: dropoffAddress,
                isBangla: isBangla,
                location: dropoffLoc,
              ),
              const SizedBox(height: 8),

              // Accept at base price button
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _submitBid(baseAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.surface),
                      )
                    : Text(
                        '${loc.translate('accept_for') ?? 'Accept for'} $currency $formattedAmount',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900),
                      ),
              ),
              const SizedBox(height: 8),

              // Bid section (quick bids / custom entry)
              OfferBidSection(
                isEditingFare: _isEditingFare,
                isSubmitting: _isSubmitting,
                bidController: _bidController,
                bidError: _bidError,
                isBangla: isBangla,
                currency: currency,
                bid10: bid10,
                bid18: bid18,
                onToggleEdit: () => setState(() => _isEditingFare = true),
                onBidChanged: _validateBid,
                onBidSubmitFromField: () {
                  final amount = double.tryParse(_bidController.text);
                  if (amount != null) _submitBid(amount);
                },
                onQuickBid: _submitBid,
              ),
              const SizedBox(height: 8),

              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  loc.translate('close') ?? 'Close',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
