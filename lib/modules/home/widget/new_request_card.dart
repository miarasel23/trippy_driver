import 'package:flutter/material.dart';
import '../../../../core/utils/localization/app_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/rental_trip_model.dart';
import '../controller/home_controller.dart';
import '../helper/new_request_card_helper.dart';
import 'translated_text.dart';

class NewRequestCard extends StatefulWidget {
  final RentalTripModel trip;

  const NewRequestCard({super.key, required this.trip});

  @override
  State<NewRequestCard> createState() => _NewRequestCardState();
}

class _NewRequestCardState extends State<NewRequestCard> {
  bool _isSubmitting = false;
  bool _hasBidded = false;

  late final TextEditingController _bidController;
  String? _bidError;

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

  String _translateNumbersAndCommonWords(String text, bool isBangla) {
    if (!isBangla) return text;
    const englishToBangla = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };
    String result = text.split('').map((e) => englishToBangla[e] ?? e).join('');
    result = result.replaceAll('km', 'কি.মি.');
    result = result.replaceAll(' m', ' মি.');
    result = result.replaceAll('away', 'দূরে');
    result = result.replaceAll('min', 'মিনিট');
    return result;
  }

  String _formatEnum(String text, AppLocalizations loc) {
    final key = text.toLowerCase();
    final translated = loc.translate(key);
    if (translated != null && translated != key) return translated;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _calculateMinutes(String pickupKmStr) {
    double distanceKm = 0.0;
    final lower = pickupKmStr.toLowerCase();
    if (lower.contains('km')) {
      distanceKm = double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (lower.contains('m')) {
      distanceKm = (double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0) / 1000.0;
    }
    final minutes = (distanceKm * 2.4).ceil();
    return minutes == 0 ? "1 min" : "$minutes min";
  }

  DateTime _parseCreatedAt(String createdAtStr) {
    DateTime parsed = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    if (parsed.difference(DateTime.now()).inHours >= 5) {
      return parsed.subtract(const Duration(hours: 7));
    }
    return parsed;
  }

  void _validateBid(String val) {
    final amount = double.tryParse(val);
    if (amount == null) {
      setState(() => _bidError = "Invalid");
      return;
    }
    
    final baseAmount = widget.trip.customerOfferAmmount;
    final maxAllowed = (baseAmount * 1.5).round();
    final minAllowed = (baseAmount * 0.85).round();

    if (amount > maxAllowed) {
      setState(() => _bidError = "Max $maxAllowed");
    } else if (amount < minAllowed) {
      setState(() => _bidError = "Min $minAllowed");
    } else {
      setState(() => _bidError = null);
    }
  }

  Future<void> _submitBid() async {
    final amount = double.tryParse(_bidController.text);
    if (amount == null || _bidError != null) return;

    setState(() => _isSubmitting = true);

    final error = await context.read<HomeController>().submitBid(widget.trip.uuid, amount);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        setState(() => _hasBidded = true);
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('wait_customer_acceptance') ?? 'Waiting for customer acceptance...'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = Localizations.localeOf(context).languageCode == 'bn';
    final createdAt = _parseCreatedAt(widget.trip.createdAt);
    final rawService = widget.trip.serviceName.isNotEmpty
        ? widget.trip.serviceName
        : widget.trip.carService.serviceName;
    final isRideShare = rawService.toUpperCase().contains('RIDE') ||
        rawService.toUpperCase() == 'RIDE_SHARE';
    final totalDuration = isRideShare ? const Duration(minutes: 1) : const Duration(hours: 1);
    final expireTime = createdAt.add(totalDuration);
    final remaining = expireTime.difference(DateTime.now());

    if (remaining.isNegative) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HomeController>().removeTrip(widget.trip.uuid);
      });
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: remaining.inSeconds.toDouble(), end: 0),
      duration: remaining,
      onEnd: () {
        context.read<HomeController>().removeTrip(widget.trip.uuid);
      },
      builder: (context, value, child) {
        return _buildCardContent(context, value, totalDuration.inSeconds.toDouble(), isRideShare, isBangla);
      },
    );
  }

  Widget _buildCardContent(BuildContext context, double remainingSeconds, double totalSeconds, bool isRideShare, bool isBangla) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final currency = isBangla ? '৳' : 'BDT';

    final formattedCarType = _formatEnum(widget.trip.carCategory.carType, loc);
    final formattedService = _formatEnum(
      widget.trip.serviceName.isNotEmpty
          ? widget.trip.serviceName
          : widget.trip.carService.serviceName,
      loc,
    );
    final formattedAmount = _translateNumbersAndCommonWords("${widget.trip.customerOfferAmmount.round()}", isBangla);
    final formattedTotalDistance = _translateNumbersAndCommonWords("${widget.trip.totalDistance} km", isBangla);
    final formattedPickupDistance = _translateNumbersAndCommonWords(
        "${widget.trip.pickupKm} away\n(~${_calculateMinutes(widget.trip.pickupKm)})", isBangla);
    final progress = remainingSeconds / totalSeconds;
    final isLow = progress < 0.2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + service badge + countdown timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.stars, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _hasBidded
                          ? (loc.translate('wait_customer_acceptance') ?? 'Waiting...')
                          : (loc.translate('new_request') ?? 'New Request'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Service name badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRideShare
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRideShare
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.orange.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: TranslatedText(
                        formattedService,
                        isBangla: isBangla,
                        style: TextStyle(
                          color: isRideShare ? Colors.blue : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: isLow ? Colors.red : theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${(remainingSeconds / 60).floor().toString().padLeft(2, '0')}:${(remainingSeconds % 60).floor().toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isLow ? Colors.red : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(isLow ? Colors.red : theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          // Car type + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    TranslatedText(
                      formattedCarType,
                      isBangla: isBangla,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      " • ",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TranslatedText(
                      formattedService,
                      isBangla: isBangla,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$formattedAmount $currency",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    loc.translate('est_fare') ?? 'Est. Fare',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pickup locations
          ...widget.trip.pickupLocations.map((locModel) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: buildInfoTile(
              icon: Icons.my_location,
              title: loc.translate('pickup') ?? 'Pickup',
              customValueWidget: TranslatedText(
                locModel.address,
                isBangla: isBangla,
                location: locModel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              theme: theme,
            ),
          )),
          // Dropoff locations
          ...widget.trip.dropoffLocations.map((locModel) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: buildInfoTile(
              icon: Icons.location_on,
              title: loc.translate('dropoff') ?? 'Dropoff',
              customValueWidget: TranslatedText(
                locModel.address,
                isBangla: isBangla,
                location: locModel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              theme: theme,
            ),
          )),
          // Distance tiles
          Row(
            children: [
              Expanded(
                child: buildInfoTile(
                  icon: Icons.route,
                  title: loc.translate('total_distance') ?? 'Total Distance',
                  value: formattedTotalDistance,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildInfoTile(
                  icon: Icons.social_distance,
                  title: loc.translate('pickup_distance') ?? 'Pickup Distance',
                  value: formattedPickupDistance,
                  theme: theme,
                ),
              ),
            ],
          ),
          if (widget.trip.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: buildInfoTile(
                icon: Icons.notes,
                title: loc.translate('note') ?? 'Note',
                customValueWidget: TranslatedText(
                  widget.trip.note,
                  isBangla: isBangla,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                theme: theme,
              ),
            ),
          const SizedBox(height: 20),
          // Bid button
          if (isRideShare)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.translate('offer_amount') ?? 'Offer Amount',
                      labelStyle: TextStyle(fontSize: 12),
                      errorText: _bidError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      prefixText: currency + ' ',
                    ),
                    onChanged: (val) {
                      _validateBid(val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: _bidError != null ? 76 : 56, // Match height of textfield considering error text
                    child: ElevatedButton(
                      onPressed: (_bidError == null && !_isSubmitting) ? _submitBid : null,
                      child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            loc.translate('bid_now') ?? 'Bid Now',
                            style: TextStyle(
                              color: _bidError == null ? theme.colorScheme.surface : theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.onSurface,
                        disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  setState(() => _isSubmitting = true);
                  final amount = widget.trip.customerOfferAmmount;
                  final error = await context.read<HomeController>().submitBid(widget.trip.uuid, amount);
                  if (mounted) {
                    setState(() => _isSubmitting = false);
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                    } else {
                      setState(() => _hasBidded = true);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('wait_customer_acceptance') ?? 'Waiting for customer acceptance...'), backgroundColor: Colors.green));
                    }
                  }
                },
                child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      loc.translate('bid_now') ?? 'Bid Now',
                      style: TextStyle(
                        color: theme.colorScheme.surface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
