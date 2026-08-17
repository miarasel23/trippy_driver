import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';
import 'translated_text_widget.dart';
import 'cancel_trip_dialog_widget.dart';
import '../helper/accepted_trip_card_helper.dart';
import '../../../../utils/app_urls.dart';
import '../../../../store/user_data_store.dart';
import '../../../../routes/app_routes.dart';
import '../../../../main.dart';

class AcceptedRentalDetails extends StatefulWidget {
  const AcceptedRentalDetails({Key? key}) : super(key: key);

  @override
  State<AcceptedRentalDetails> createState() => _AcceptedRentalDetailsState();
}

class _AcceptedRentalDetailsState extends State<AcceptedRentalDetails> {
  bool _isLoading = false;
  bool _isCalling = false;
  bool _isMessaging = false;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        if (state.previewTrip == null) return const SizedBox.shrink();

        final trip = state.previewTrip!;
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
        final String rawRating = trip.customer.isNotEmpty ? trip.customer.first.averageRating.toStringAsFixed(1) : "5.0";
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

        String? actionLabel;
        String? nextStatus;
        if (currentStatus == 'ACCEPTED') {
          actionLabel = loc.translate('going_pickup_point') ?? 'Going Pick Up Point';
          nextStatus = 'IN_PROGRESS';
        } else if (currentStatus == 'IN_PROGRESS') {
          actionLabel = loc.translate('start_ride') ?? 'Start Ride';
          nextStatus = 'RIDE_STARTED';
        } else if (currentStatus == 'RIDE_STARTED') {
          final service = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
          if (service == 'RETURN' || service == 'ROUND_TRIP') {
            actionLabel = loc.translate('first_completed') ?? 'First Completed';
            nextStatus = 'FIRST_COMPLETED';
          } else {
            actionLabel = loc.translate('complete') ?? 'Complete';
            nextStatus = 'COMPLETED';
          }
        } else if (currentStatus == 'FIRST_COMPLETED') {
          actionLabel = loc.translate('complete') ?? 'Complete';
          nextStatus = 'COMPLETED';
        }

        final rawService = trip.serviceName.isNotEmpty ? trip.serviceName : trip.carService.serviceName;
        final rawServiceUpper = rawService.toUpperCase();
        final isRideShare = rawServiceUpper.contains('RIDE') || rawServiceUpper == 'RIDE_SHARE';

        final canCancel = currentStatusUpper != 'RIDE_STARTED' && 
                          currentStatusUpper != 'FIRST_COMPLETED' && 
                          currentStatusUpper != 'COMPLETED';        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Service Badge & Close ────────────────────────
              Row(
                children: [
                  AcceptedTripCardHelper.buildServiceBadge(rawService, hoursBooked: trip.hoursBooked),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
                    onPressed: () {
                      context.read<HomeController>().selectTripForPreview(null);
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Lime/Green Divider Line
              Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFC0CA33),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // ── Customer Profile & Price Row ─────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: customerAvatar.isNotEmpty
                        ? NetworkImage(customerAvatar.startsWith('http') ? customerAvatar : '${AppUrls.imageBaseUrl}$customerAvatar')
                        : null,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: customerAvatar.isEmpty ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 22) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              customerRating,
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$currency $displayTotalAmount",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distanceText,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Hourly Booked Time Display ──────────────────────────
              if (trip.hoursBooked != null && trip.hoursBooked! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF7B1FA2)),
                    const SizedBox(width: 6),
                    Text(
                      "${isBangla ? 'বুকিং সময়: ' : 'Booked Time: '}${AcceptedTripCardHelper.translateNumbersAndCommonWords('${trip.hoursBooked}', isBangla)} ${isBangla ? 'ঘণ্টা' : 'Hours'}",
                      style: const TextStyle(
                        color: Color(0xFF7B1FA2),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Date & Time Row (Hidden for RIDE_SHARE) ─────────────
              if (!isRideShare) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF1E88E5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AcceptedTripCardHelper.formatStartDatetime(trip.startDatetime, isBangla),
                        style: const TextStyle(
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // ── Route Locations A & B ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcceptedTripCardHelper.buildLocationBadgeA(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      pickup,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      isBangla: isBangla,
                      location: pickupLoc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AcceptedTripCardHelper.buildLocationBadgeB(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TranslatedText(
                      dropoff,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9), fontWeight: FontWeight.w500, fontSize: 13),
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trip.note,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Action Buttons (Call, Message, Navigate, Cancel) ───
              if (showActionButtons) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AcceptedTripCardHelper.buildActionButton(
                      icon: Icons.phone,
                      label: loc.translate('call') ?? "Call",
                      color: theme.colorScheme.onSurface,
                      isLoading: _isCalling,
                      onTap: () async {
                        if (trip.customer.isNotEmpty) {
                          setState(() => _isCalling = true);
                          final phone = trip.customer.first.phone;
                          await AcceptedTripCardHelper.launchPhoneCall(phone);
                          if (mounted) setState(() => _isCalling = false);
                        }
                      },
                    ),
                    AcceptedTripCardHelper.buildActionButton(
                      icon: Icons.message,
                      label: loc.translate('message') ?? "Message",
                      color: theme.colorScheme.onSurface,
                      isLoading: _isMessaging,
                      onTap: () async {
                        setState(() => _isMessaging = true);
                        final driverUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
                        if (driverUuid == null || driverUuid.isEmpty) {
                          if (mounted) {
                            setState(() => _isMessaging = false);
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
                          if (mounted) {
                            setState(() => _isMessaging = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer information is missing for this trip.')),
                            );
                          }
                          return;
                        }

                        final String customerName = trip.customer.isNotEmpty && trip.customer.first.name.isNotEmpty
                            ? trip.customer.first.name
                            : "Customer";

                        if (mounted) setState(() => _isMessaging = false);

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
                      isLoading: _isNavigating,
                      onTap: () async {
                        setState(() => _isNavigating = true);
                        final navTarget = ['IN_PROGRESS', 'RIDE_STARTED', 'FIRST_COMPLETED', 'COMPLETED'].contains(currentStatus) 
                            ? dropoffLoc 
                            : pickupLoc;
                        await AcceptedTripCardHelper.launchNavigation(navTarget);
                        if (mounted) setState(() => _isNavigating = false);
                      },
                    ),
                    if (canCancel)
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

              // ── Main Action Status Button ────────────────────────────
              if (actionLabel != null && nextStatus != null) ...[
                const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.0),
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<HomeController>().selectTripForPreview(null);
                  },
                  icon: const Icon(Icons.close_fullscreen_rounded, size: 16),
                  label: Text(
                    loc.translate('close') ?? 'Close',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
      },
    );
  }
}
