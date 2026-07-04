import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../model/choose_car_model.dart';

class ConfirmTripDialog extends StatefulWidget {
  final Car selectedCar;
  final String serviceName;
  final List<String> pickupAddresses;
  final List<String> dropoffAddresses;

  const ConfirmTripDialog({
    super.key,
    required this.selectedCar,
    required this.serviceName,
    required this.pickupAddresses,
    required this.dropoffAddresses,
  });

  @override
  State<ConfirmTripDialog> createState() => _ConfirmTripDialogState();
}

class _ConfirmTripDialogState extends State<ConfirmTripDialog> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _noteController.dispose();
    _offerPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use a very dark charcoal color like the photo if in dark mode
    final bgColor = isDark ? const Color(0xFF2B2B36) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? const Color(0xFF3F3F4E) : Colors.grey[300];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: bgColor,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Center(
              child: Text(
                loc.translate("confirm_trip"),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Pickup & Drop-off Header
            Text(
              loc.translate("pickup_and_dropoff"),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Route Visual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor ?? Colors.grey),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < widget.pickupAddresses.length; i++)
                    _buildSummaryRow(
                      widget.pickupAddresses.length > 1 ? "Pickup ${i + 1}" : "Pickup", 
                      widget.pickupAddresses[i], 
                      Icons.my_location, 
                      isDark,
                      textColor,
                      subTextColor
                    ),
                  
                  const SizedBox(height: 12),
                  
                  for (int i = 0; i < widget.dropoffAddresses.length; i++)
                    _buildSummaryRow(
                      widget.dropoffAddresses.length > 1 ? "Dropoff ${i + 1}" : "Dropoff", 
                      widget.dropoffAddresses[i], 
                      Icons.location_on, 
                      isDark,
                      textColor,
                      subTextColor
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            
            // Trip Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.translate("service"), style: GoogleFonts.poppins(fontSize: 14, color: subTextColor)),
                Text(widget.serviceName.replaceAll('_', ' '), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.translate("vehicle"), style: GoogleFonts.poppins(fontSize: 14, color: subTextColor)),
                Text("${widget.selectedCar.carType} (${widget.selectedCar.setCapacity})", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.translate("payment"), style: GoogleFonts.poppins(fontSize: 14, color: subTextColor)),
                Text("CASH", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Fare
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E26) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor ?? Colors.grey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.translate("estimated_fare"), 
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)
                  ),
                  Text(
                    loc.locale.languageCode == 'bn' 
                        ? '৳${widget.selectedCar.minimumBookingPrice}' 
                        : 'BDT ${widget.selectedCar.minimumBookingPrice}',
                     style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)  
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Offer Price Field (Required)
            TextFormField(
              controller: _offerPriceController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                labelText: loc.translate("offer_price"),
                labelStyle: GoogleFonts.poppins(color: subTextColor, fontSize: 14),
                hintText: loc.translate("enter_offer_price"),
                hintStyle: GoogleFonts.poppins(color: subTextColor?.withOpacity(0.5), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor ?? Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor ?? Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF8C9EFF), width: 2),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E26) : Colors.grey[50],
                // Remove left padding so error text aligns with the text field border
                contentPadding: const EdgeInsets.only(left: 0, right: 16, top: 12, bottom: 12),
                // Use prefixIcon to indent the input and hint text instead
                prefixIcon: const SizedBox(width: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 16, minHeight: 0),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return loc.translate("offer_price_required");
                }
                
                final num? offerPrice = num.tryParse(value);
                final num? estFare = widget.selectedCar.minimumBookingPrice;
                
                if (offerPrice != null && estFare != null) {
                  final num minAllowedOffer = estFare * 0.85;
                  if (offerPrice < minAllowedOffer) {
                    return loc.translate("offer_price_too_low");
                  }
                  if (offerPrice > estFare) {
                    return loc.translate("offer_price_too_high");
                  }
                }
                
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Note Field (Optional)
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.poppins(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText: loc.translate("note"),
                labelStyle: GoogleFonts.poppins(color: subTextColor, fontSize: 14),
                hintText: loc.translate("add_note"),
                hintStyle: GoogleFonts.poppins(color: subTextColor?.withOpacity(0.5), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor ?? Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor ?? Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color(0xFF8C9EFF), width: 2),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E26) : Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                  Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.white : Colors.black),
                      foregroundColor: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(loc.translate("cancel"), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'note': _noteController.text.trim(),
                          'offerAmount': _offerPriceController.text.trim(),
                        });
                      }
                    },
                    child: Text(loc.translate("submit"), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String address, IconData icon, bool isDark, Color textColor, Color? subTextColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: subTextColor, fontWeight: FontWeight.w600)),
              Text(address, style: GoogleFonts.poppins(fontSize: 14, color: textColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
