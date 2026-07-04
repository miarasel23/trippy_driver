import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/localization/app_localization.dart';
import '../../../../utils/app_urls.dart';
import '../../../../utils/enums.dart';
import '../../model/trip_price_details_model.dart';
import '../controller/choose_car_bottom_sheet_bloc.dart';
import '../controller/choose_car_bottom_sheet_events.dart';
import '../controller/choose_car_bottom_sheet_state.dart';
import '../model/choose_car_model.dart';
import '../../../../store/user_data_store.dart';
import '../../model/create_rental_trip_model.dart';
import '../../repository/create_trip_repository.dart';
import '../../../../routes/app_routes.dart';
import '../widget/confirm_trip_dialog.dart';

class CarOption {
  final String name;
  final int seats;
  final String imagePath;

  CarOption({required this.name, required this.seats, required this.imagePath});
}

class ChooseCarBottomSheet extends StatefulWidget {
  const ChooseCarBottomSheet({
    super.key,
    required this.cars,
    required this.serviceName,
    required this.pickupAddresses,
    required this.dropoffAddresses,
    required this.tripReq,
    this.hoursBooked,
  });

  final List<Car> cars;
  final String serviceName;
  final List<String> pickupAddresses;
  final List<String> dropoffAddresses;
  final TripPriceDetailsRequest tripReq;
  final String? hoursBooked;
  @override
  State<ChooseCarBottomSheet> createState() => _ChooseCarBottomSheetState();
}

class _ChooseCarBottomSheetState extends State<ChooseCarBottomSheet> {
  bool _isCreatingTrip = false;

  Future<void> _handleCreateTrip(Car selectedCar) async {
    final loc = AppLocalizations.of(context);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => ConfirmTripDialog(
        selectedCar: selectedCar,
        serviceName: widget.serviceName,
        pickupAddresses: widget.pickupAddresses,
        dropoffAddresses: widget.dropoffAddresses,
      ),
    );

    if (result == null) return;

    setState(() {
      _isCreatingTrip = true;
    });

    try {
      String startDatetime = widget.tripReq.startDatetime;
      String? endDatetime = widget.tripReq.endDatetime;

      final req = CreateRentalTripRequest(
        serviceType: widget.serviceName,
        hoursBooked: widget.hoursBooked,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        paymentMethod: "CASH",
        customerUuid: await UserDataStore.getUuid() ?? "",
        countryCode: "BD",
        actionWhen: "create_rental_trip",
        languageCode: loc.locale.languageCode,
        pickupLocationUuid: widget.tripReq.pickupLocationUuid,
        dropoffLocationUuid: widget.tripReq.dropoffLocationUuid,
        priceSetUuid: selectedCar.priceSetUuid ?? selectedCar.uuid,
        note: result['note'],
        offerAmount: result['offerAmount'],
      );

      final repo = CreateTripRepository();
      await repo.createRentalTrip(req);

      if (mounted) {
        // Dismiss bottom sheet
        Navigator.pop(context);
        
        // Navigate to Bidding Screen
        Navigator.pushNamed(
          context,
          AppRoutes.biddingScreen,
          arguments: UserDataStore.uuid ?? "",
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            final loc = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(loc.translate("message")),
              content: Text(e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTrip = false;
        });
      }
    }
  }

  List<Widget> _buildDynamicLocationList(bool isDark) {
    List<Widget> children = [];
    
    final int pickupCount = widget.pickupAddresses.length;
    for (int i = 0; i < pickupCount; i++) {
      children.add(
        _buildLocationRow(
          icon: Icons.my_location,
          iconColor: isDark ? Colors.white : Colors.black87,
          label: pickupCount > 1 ? "PICKUP ${i + 1}" : "PICKUP",
          address: widget.pickupAddresses[i],
          isDark: isDark,
        ),
      );
      
      children.add(
        Padding(
          padding: const EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
          child: Container(
            width: 2,
            height: 20,
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
      );
    }
    
    final int dropoffCount = widget.dropoffAddresses.length;
    for (int i = 0; i < dropoffCount; i++) {
      children.add(
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: const Color(0xFF6C63FF),
          label: dropoffCount > 1 ? "DESTINATION ${i + 1}" : "DESTINATION",
          address: widget.dropoffAddresses[i],
          isDark: isDark,
        ),
      );
      
      if (i < dropoffCount - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 11.0, top: 4, bottom: 4),
            child: Container(
              width: 2,
              height: 20,
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
        );
      }
    }
    
    return children;
  }

  Widget _buildLocationRow({required IconData icon, required Color iconColor, required String label, required String address, required bool isDark}) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(address, style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: BlocBuilder<ChooseCarBottomSheetBloc, ChooseCarBottomSheetState>(
          builder: (context, state) {
            if (state.status == ChooseCarBottomSheetStatus.success) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Trip Details Map/Location Box
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252833) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._buildDynamicLocationList(isDark),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                  Flexible(
                    child: ListView.separated(
                      physics: ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: widget.cars.length,
                      itemBuilder: (context, index) {
                        final car = widget.cars[index];
                        final isSelected = state.currentCarIndex == index.toString();
                        return GestureDetector(
                          onTap: () {
                            context.read<ChooseCarBottomSheetBloc>().add(
                              ChooseCar(selectedCarIndex: index.toString()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFF2B2B36) 
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF8C9EFF) 
                                    : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Car Image
                                Container(
                                  width: 80,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Builder(
                                    builder: (context) {
                                      final avatar = car.carAvatar;
                                      final imageUrl = AppUrls.getImageUrl(avatar);
                                      if (imageUrl == null || imageUrl.isEmpty) {
                                        return const Icon(Icons.directions_car, color: Colors.grey);
                                      }

                                      return Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Details (Middle)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        car.carType,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${car.setCapacity} Seats',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Price & Distance (Right)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (car.minimumBookingPrice != null)
                                      Text(
                                        '${loc.translate("up_to")} ' + 
                                        (loc.locale.languageCode == 'bn' 
                                            ? '৳${car.minimumBookingPrice}' 
                                            : 'BDT ${car.minimumBookingPrice}'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    if (car.distance != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${car.distance} km',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 12);
                      },
                    ),
                  ),

                  if (state.clicked == true && state.currentCarIndex != null && int.tryParse(state.currentCarIndex!) != null)
                    Builder(builder: (context) {
                      final idx = int.parse(state.currentCarIndex!);
                      if (idx < 0 || idx >= widget.cars.length) return SizedBox();
                      final selectedCar = widget.cars[idx];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 21),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              elevation: 0,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isCreatingTrip ? null : () => _handleCreateTrip(selectedCar),
                            child: _isCreatingTrip 
                              ? SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, strokeWidth: 2)
                                )
                              : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Builder(builder: (context) {
                                        final isDark = Theme.of(context).brightness == Brightness.dark;
                                        final iconColor = isDark ? Colors.black : Colors.white;
                                        final avatar = selectedCar.carAvatar;
                                        final imageUrl = AppUrls.getImageUrl(avatar);
                                        if (imageUrl == null || imageUrl.isEmpty) {
                                          return Icon(Icons.directions_car, color: iconColor);
                                        }
                                        return Image.network(
                                          imageUrl, 
                                          fit: BoxFit.contain,
                                          errorBuilder: (_,__,___) => Icon(Icons.directions_car, color: iconColor),
                                        );
                                      }),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "TRIPPY ${selectedCar.carType}",
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(Icons.arrow_forward, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  SizedBox(height: 10),
                ],
              );
            }
            if (state.status == ChooseCarBottomSheetStatus.loading) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }
            if (state.status == ChooseCarBottomSheetStatus.failure) {
              return Center(
                child: Text("Failed and ${state.error.toString()}"),
              );
            }
            return Icon(Icons.directions_car);
          },
        ),
      ),
    );
  }
}
