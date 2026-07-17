import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/rental_trip_model.dart';
import 'translated_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cancel_trip_dialog.dart';

class AcceptedTripCard extends StatelessWidget {
  const AcceptedTripCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        if (!state.isOnline) return const SizedBox.shrink();

        final acceptedTrips = state.bidTrips.where((t) {
          final status = t.tripStatus;
          final bidStatus = t.myBid?.status;
          return status == 'ACCEPTED' || status == 'RIDE_STARTED' || status == 'FIRST_COMPLETED' || status == 'IN_PROGRESS' || bidStatus == 'ACCEPTED';
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
        final amount = trip.myBid?.amount ?? trip.customerOfferAmmount;
        
        final currentStatus = trip.tripStatus == 'REQUESTED' ? (trip.myBid?.status ?? trip.tripStatus) : trip.tripStatus;

        if (currentStatus == 'FIRST_COMPLETED') {
          final temp = pickup;
          pickup = dropoff;
          dropoff = temp;
        }

        String? actionLabel;
        String? nextStatus;
        if (currentStatus == 'ACCEPTED') {
          actionLabel = loc.translate('going_pickup_point') ?? 'Going Pick Up Point';
          nextStatus = 'IN_PROGRESS';
        } else if (currentStatus == 'IN_PROGRESS') {
          actionLabel = loc.translate('start_ride') ?? 'Start Ride';
          nextStatus = 'RIDE_STARTED';
        } else if (currentStatus == 'RIDE_STARTED') {
          if (trip.serviceName == 'RETURN' || trip.serviceName == 'ROUND_TRIP') {
            actionLabel = loc.translate('first_completed') ?? 'First Completed';
            nextStatus = 'FIRST_COMPLETED';
          } else {
            actionLabel = loc.translate('completed') ?? 'Completed';
            nextStatus = 'COMPLETED';
          }
        } else if (currentStatus == 'FIRST_COMPLETED') {
          actionLabel = loc.translate('completed') ?? 'Completed';
          nextStatus = 'COMPLETED';
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
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('trip_accepted') ?? 'Trip Accepted',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    "\৳$amount",
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                children: [
                  Icon(Icons.my_location, size: 16, color: Colors.blue.withOpacity(0.8)),
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
                  Icon(Icons.location_on, size: 16, color: Colors.red.withOpacity(0.8)),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (actionLabel != null && nextStatus != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<HomeController>().updateTripRideStatus(trip.uuid, nextStatus!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  _buildActionButton(
                    icon: Icons.phone,
                    label: loc.translate('call') ?? "Call",
                    color: Colors.green,
                    onTap: () async {
                      if (trip.customer.isNotEmpty) {
                        final phone = trip.customer.first.phone;
                        final url = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.message,
                    label: loc.translate('message') ?? "Message",
                    color: Colors.blue,
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.navigation,
                    label: loc.translate('navigate') ?? "Navigate",
                    color: theme.colorScheme.primary,
                    onTap: () async {
                      if (pickupLoc != null) {
                        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${pickupLoc.latitude},${pickupLoc.longitude}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.cancel,
                    label: loc.translate('cancel') ?? "Cancel",
                    color: Colors.red,
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
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
