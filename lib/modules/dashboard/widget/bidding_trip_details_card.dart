import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/create_rental_trip_model.dart';
import '../../../../utils/app_urls.dart';

class BiddingTripDetailsCard extends StatelessWidget {
  final bool isDark;
  final RentalTrip currentTrip;
  final VoidCallback onCancel;

  const BiddingTripDetailsCard({
    super.key,
    required this.isDark,
    required this.currentTrip,
    required this.onCancel,
  });

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicLocationList(bool isDark) {
    List<Widget> children = [];
    
    final int pickupCount = currentTrip.pickupLocations.length;
    for (int i = 0; i < pickupCount; i++) {
      children.add(
        _buildLocationRow(
          icon: Icons.my_location,
          iconColor: isDark ? Colors.white : Colors.black87,
          label: pickupCount > 1 ? "PICKUP ${i + 1}" : "PICKUP",
          address: currentTrip.pickupLocations[i].address ?? "Unknown Pickup",
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
    
    final int dropoffCount = currentTrip.dropoffLocations.length;
    for (int i = 0; i < dropoffCount; i++) {
      children.add(
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: const Color(0xFF6C63FF),
          label: dropoffCount > 1 ? "DESTINATION ${i + 1}" : "DESTINATION",
          address: currentTrip.dropoffLocations[i].address ?? "Unknown Dropoff",
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

  @override
  Widget build(BuildContext context) {
    final carType = currentTrip.carCategory?.carType ?? "Standard Sedan";
    final price = currentTrip.offerAmount?.toStringAsFixed(2) ?? currentTrip.priceInfo?.minimumBookingPrice?.toStringAsFixed(2) ?? "0.00";
    final hasOffer = currentTrip.offerAmount != null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252833) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: currentTrip.carCategory?.carAvatar != null
                      ? Image.network(
                          "${AppUrls.imageBaseUrl}${currentTrip.carCategory!.carAvatar}",
                          width: 24,
                          height: 24,
                        )
                      : const Icon(Icons.directions_car, color: Color(0xFF6C63FF)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carType,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "Priority Pickup • Comfort+",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (hasOffer ? '' : '${AppLocalizations.of(context).translate("up_to") ?? "Up to"} ') + 
                      (AppLocalizations.of(context).locale.languageCode == 'bn' 
                          ? '৳$price' 
                          : 'BDT $price'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      hasOffer 
                        ? (AppLocalizations.of(context).translate("offer_price") ?? "Offer Price")
                        : "Est. total",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          ..._buildDynamicLocationList(isDark),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF252833) : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: onCancel,
              child: Text(
                "Cancel Request",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Center(
            child: Text(
              "SECURE MATCHING BY TRIPPY RIDE",
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white24 : Colors.black38,
                letterSpacing: 1.5,
              ),
            ),
          )
        ],
      ),
    );
  }
}
