import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import 'translated_text_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cancel_trip_dialog_widget.dart';
import '../helper/accepted_trip_card_helper.dart';
import '../../../../utils/app_urls.dart';
import '../../../../store/user_data_store.dart';
import '../../../../routes/app_routes.dart';
import '../../../../main.dart';

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
          final isAccepted = status == 'ACCEPTED' || status == 'RIDE_STARTED' || status == 'FIRST_COMPLETED' || status == 'IN_PROGRESS' || status == 'COMPLETED' || bidStatus == 'ACCEPTED';
          if (!isAccepted) return false;
          return AcceptedTripCardHelper.shouldShowAcceptedTripCard(t);
        }).toList();

        if (acceptedTrips.isEmpty) return const SizedBox.shrink();

        final trip = acceptedTrips.first; // Show the first accepted trip
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);
        final isBangla = Localizations.localeOf(context).languageCode == 'bn';

        final pickupLoc = AcceptedTripCardHelper.getEffectivePickup(trip);
        final dropoffLoc = AcceptedTripCardHelper.getEffectiveDropoff(trip);
        
        final pickup = pickupLoc?.address ?? 'Unknown';
        final dropoff = dropoffLoc?.address ?? 'Unknown';
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
        final int totalTrips = trip.customer.isNotEmpty ? trip.customer.first.totalTripComplete : trip.totalTripComplete;
        final String rawRating = trip.customer.isNotEmpty ? trip.customer.first.averageRating.toStringAsFixed(1) : "4.5";
        final String customerRating = totalTrips > 0 
            ? "${AcceptedTripCardHelper.translateNumbersAndCommonWords(rawRating, isBangla)} (${AcceptedTripCardHelper.translateNumbersAndCommonWords(totalTrips.toString(), isBangla)})" 
            : AcceptedTripCardHelper.translateNumbersAndCommonWords(rawRating, isBangla);
        final formattedTotalDistance = AcceptedTripCardHelper.translateNumbersAndCommonWords(AcceptedTripCardHelper.calculateTripDistance(trip), isBangla);
        final distanceText = formattedTotalDistance;
        final timeText = AcceptedTripCardHelper.translateNumbersAndCommonWords("${AcceptedTripCardHelper.calculateMinutes(trip.pickupKm)} min", isBangla);
        
        final currentStatus = trip.tripStatus == 'REQUESTED' ? (trip.myBid?.status ?? trip.tripStatus) : trip.tripStatus;

        final statusUpper = trip.tripStatus.toUpperCase();
        final currentStatusUpper = currentStatus.toUpperCase();
        final showActionButtons = 
            statusUpper != 'REQUESTED' && 
            statusUpper != 'CANCELLED' && 
            statusUpper != 'COMPLETED' && 
            statusUpper != 'REJECTED' &&
            currentStatusUpper != 'REQUESTED' && 
            currentStatusUpper != 'CANCELLED' && 
            currentStatusUpper != 'COMPLETED' && 
            currentStatusUpper != 'REJECTED';

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
          final service = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
          if (service == 'RETURN' || service == 'ROUND_TRIP') {
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
                        // Pickup duration (timeText) removed
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
                          "$currency $displayTotalAmount",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (platformFee > 0)
                          Text(
                            "${loc.translate('platform_fee') ?? 'Platform fee'}: $currency $displayPlatformFee",
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        AcceptedTripCardHelper.buildTripDateTimes(context, trip, isBangla, theme),
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
                                location: pickupLoc,
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
                                location: dropoffLoc,
                              ),
                            ),
                          ],
                        ),
                        if (trip.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.edit_note_rounded, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  trip.note,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (showActionButtons) ...[
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
                      onTap: () async {
                        print('testing messaging');
                        final driverUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
                        if (driverUuid == null || driverUuid.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Driver UUID is missing. Please log in again.')),
                            );
                          }
                          return;
                        }

                        final String? customerUuid = trip.customer.isNotEmpty && trip.customer.first.customerUuid.isNotEmpty
                            ? trip.customer.first.customerUuid
                            : null;

                        if (customerUuid == null || customerUuid.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer information is missing for this trip.')),
                            );
                          }
                          return;
                        }

                        final String customerName = trip.customer.isNotEmpty && trip.customer.first.name.isNotEmpty
                            ? trip.customer.first.name
                            : "Customer";

                        if (globalNavigatorKey.currentState != null) {
                          globalNavigatorKey.currentState!.pushNamed(
                            AppRoutes.chat,
                            arguments: {
                              'customerUuid': customerUuid,
                              'customerName': customerName,
                              'driverUuid': driverUuid,
                            },
                          );
                        } else if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: {
                              'customerUuid': customerUuid,
                              'customerName': customerName,
                              'driverUuid': driverUuid,
                            },
                          );
                        }
                      },
                    ),
                    AcceptedTripCardHelper.buildActionButton(
                      icon: Icons.navigation,
                      label: loc.translate('navigate') ?? "Navigate",
                      color: theme.colorScheme.onSurface,
                      onTap: () async {
                        final navTarget = ['IN_PROGRESS', 'RIDE_STARTED', 'FIRST_COMPLETED', 'COMPLETED'].contains(currentStatus) 
                            ? dropoffLoc 
                            : pickupLoc;
                        await AcceptedTripCardHelper.launchNavigation(navTarget);
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
              ],
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
