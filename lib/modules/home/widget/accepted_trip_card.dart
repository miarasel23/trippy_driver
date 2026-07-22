import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import 'translated_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cancel_trip_dialog.dart';
import '../helper/accepted_trip_card_helper.dart';
import '../../../../utils/app_urls.dart';

class AcceptedTripCard extends StatefulWidget {
  const AcceptedTripCard({Key? key}) : super(key: key);

  @override
  State<AcceptedTripCard> createState() => _AcceptedTripCardState();
}

class _AcceptedTripCardState extends State<AcceptedTripCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        if (!state.isOnline) return const SizedBox.shrink();

        final acceptedTrips = state.bidTrips.where((t) {
          final status = t.tripStatus;
          final bidStatus = t.myBid?.status;
          return status == 'ACCEPTED' || status == 'RIDE_STARTED' || status == 'FIRST_COMPLETED' || status == 'IN_PROGRESS' || status == 'COMPLETED' || bidStatus == 'ACCEPTED';
        }).toList();

        if (acceptedTrips.isEmpty) return const SizedBox.shrink();

        final trip = acceptedTrips.first; // Show the first accepted trip
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);
        final isBangla = Localizations.localeOf(context).languageCode == 'bn';

        final pickupLoc = trip.pickupLocations.isNotEmpty ? trip.pickupLocations.first : null;
        final dropoffLoc = trip.dropoffLocations.isNotEmpty ? trip.dropoffLocations.first : null;
        
        var pickup = pickupLoc?.address ?? 'Unknown';
        var dropoff = dropoffLoc?.address ?? 'Unknown';
        final bidAmount = trip.myBid?.amount ?? trip.customerOfferAmmount;
        final totalAmount = trip.myBid?.totalAmount ?? bidAmount;
        final platformFee = totalAmount - bidAmount;
        final currency = isBangla ? '৳' : 'BDT';
        final displayTotalAmount = AcceptedTripCardHelper.translateNumbersAndCommonWords(totalAmount.round().toString(), isBangla);
        final displayPlatformFee = AcceptedTripCardHelper.translateNumbersAndCommonWords(platformFee.round().toString(), isBangla);

        final customerName = trip.customer.isNotEmpty && trip.customer.first.name.isNotEmpty 
            ? trip.customer.first.name 
            : loc.translate('customer') ?? "Customer";
        final customerAvatar = trip.customer.isNotEmpty ? trip.customer.first.profilePicture : '';
        final customerRating = trip.customer.isNotEmpty ? AcceptedTripCardHelper.translateNumbersAndCommonWords(trip.customer.first.averageRating.toStringAsFixed(1), isBangla) : AcceptedTripCardHelper.translateNumbersAndCommonWords("4.5", isBangla);
        final formattedTotalDistance = AcceptedTripCardHelper.translateNumbersAndCommonWords("${trip.totalDistance} km", isBangla);
        final distanceText = "~$formattedTotalDistance";
        final timeText = AcceptedTripCardHelper.translateNumbersAndCommonWords("${AcceptedTripCardHelper.calculateMinutes(trip.pickupKm)} min", isBangla);
        
        final currentStatus = trip.tripStatus == 'REQUESTED' ? (trip.myBid?.status ?? trip.tripStatus) : trip.tripStatus;

        if (currentStatus == 'FIRST_COMPLETED') {
          final temp = pickup;
          pickup = dropoff;
          dropoff = temp;
        }

        String headerTitle = loc.translate('trip_accepted') ?? 'Trip Accepted';
        String? actionLabel;
        String? nextStatus;
        if (currentStatus == 'ACCEPTED') {
          actionLabel = loc.translate('going_pickup_point') ?? 'Going Pick Up Point';
          nextStatus = 'IN_PROGRESS';
        } else if (currentStatus == 'IN_PROGRESS') {
          headerTitle = loc.translate('rider_is_gooing_pickup_point') ?? 'Rider is going to pickup point';
          actionLabel = loc.translate('start_ride') ?? 'Start Ride';
          nextStatus = 'RIDE_STARTED';
        } else if (currentStatus == 'RIDE_STARTED') {
          headerTitle = loc.translate('ride_started') ?? 'Ride started';
          if (trip.serviceName == 'RETURN' || trip.serviceName == 'ROUND_TRIP') {
            actionLabel = loc.translate('first_completed') ?? 'First Completed';
            nextStatus = 'FIRST_COMPLETED';
          } else {
            actionLabel = loc.translate('completed') ?? 'Completed';
            nextStatus = 'COMPLETED';
          }
        } else if (currentStatus == 'FIRST_COMPLETED') {
          headerTitle = loc.translate('first_completed') ?? 'First Completed';
          actionLabel = loc.translate('completed') ?? 'Completed';
          nextStatus = 'COMPLETED';
        } else if (currentStatus == 'COMPLETED') {
          headerTitle = loc.translate('ride_completed_show_details') ?? 'Ride completed - Show details';
          actionLabel = null;
          nextStatus = null;
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Avatar, Name, Rating, Time
                  SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: customerAvatar.isNotEmpty ? NetworkImage(customerAvatar.startsWith('http') ? customerAvatar : '${AppUrls.imageBaseUrl}$customerAvatar') : null,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          child: customerAvatar.isEmpty ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 28) : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              customerRating,
                              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeText,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Middle Column: Distance, Price, Locations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          distanceText,
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$currency$displayTotalAmount",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (platformFee > 0)
                          Text(
                            "${loc.translate('platform_fee') ?? 'Platform fee'}: $currency$displayPlatformFee",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.my_location, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TranslatedText(
                                pickup,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                isBangla: isBangla,
                                location: currentStatus == 'FIRST_COMPLETED' ? dropoffLoc : pickupLoc,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TranslatedText(
                                dropoff,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 14),
                                isBangla: isBangla,
                                location: currentStatus == 'FIRST_COMPLETED' ? pickupLoc : dropoffLoc,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AcceptedTripCardHelper.buildActionButton(
                    icon: Icons.phone,
                    label: loc.translate('call') ?? "Call",
                    color: theme.colorScheme.onSurface,
                    onTap: () async {
                      if (trip.customer.isNotEmpty) {
                        final phone = trip.customer.first.phone;
                        await AcceptedTripCardHelper.launchPhoneCall(phone);
                      }
                    },
                  ),
                  AcceptedTripCardHelper.buildActionButton(
                    icon: Icons.message,
                    label: loc.translate('message') ?? "Message",
                    color: theme.colorScheme.onSurface,
                    onTap: () {},
                  ),
                  AcceptedTripCardHelper.buildActionButton(
                    icon: Icons.navigation,
                    label: loc.translate('navigate') ?? "Navigate",
                    color: theme.colorScheme.onSurface,
                    onTap: () async {
                      await AcceptedTripCardHelper.launchNavigation(pickupLoc);
                    },
                  ),
                  AcceptedTripCardHelper.buildActionButton(
                    icon: Icons.cancel,
                    label: loc.translate('cancel') ?? "Cancel",
                    color: theme.colorScheme.onSurface,
                    onTap: () {
                      final homeController = context.read<HomeController>();
                      showDialog(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: homeController,
                          child: CancelTripDialog(tripUuid: trip.uuid),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (actionLabel != null && nextStatus != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                        });
                      }
                      
                      await context.read<HomeController>().updateTripRideStatus(trip.uuid, nextStatus!);
                      
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                        ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
