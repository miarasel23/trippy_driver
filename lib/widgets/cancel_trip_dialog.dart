import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/localization/app_localization.dart';
import '../utils/app_colors.dart';

class CancelTripDialog extends StatefulWidget {
  final bool isDark;

  const CancelTripDialog({super.key, required this.isDark});

  @override
  State<CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<CancelTripDialog> {
  String _selectedReason = "Waiting for a long time";
  final TextEditingController _otherReasonController = TextEditingController();

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final List<String> reasons = [
      loc.translate("waiting_long_time"),
      loc.translate("driver_asked_cancel"),
      loc.translate("changed_mind"),
      loc.translate("others")
    ];
    // Compute once to avoid repeated lookups and mismatch between frames
    final String othersStr = reasons.last;

    // BUG FIX: Do NOT mutate state directly inside build(). Instead, check
    // after build and let WidgetsBinding schedule if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!reasons.contains(_selectedReason)) {
        setState(() {
          _selectedReason = reasons.first;
        });
      }
    });

    return Dialog(
      backgroundColor: widget.isDark ? const Color(0xFF1C1E26) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate("why_cancel"),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) {
              return Theme(
                data: ThemeData(
                  unselectedWidgetColor: widget.isDark ? Colors.white54 : Colors.black54,
                ),
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    reason,
                    style: GoogleFonts.poppins(
                      color: widget.isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: const Color(0xFF6C63FF),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                ),
              );
            }).toList(),
            if (_selectedReason == othersStr) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherReasonController,
                maxLines: 3,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: loc.translate("write_reason"),
                  hintStyle: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black38),
                  filled: true,
                  fillColor: widget.isDark ? AppColors.darkCardDeep : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: widget.isDark ? Colors.white24 : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      loc.translate("dismiss"),
                      style: GoogleFonts.poppins(
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // BUG FIX: Use pre-computed othersStr for consistent comparison
                      final String finalReason = (_selectedReason == othersStr)
                          ? _otherReasonController.text.trim()
                          : _selectedReason;
                      if (_selectedReason == othersStr && finalReason.isEmpty) return;
                      Navigator.of(context).pop(finalReason);
                    },
                    child: Text(
                      loc.translate("submit"),
                      style: GoogleFonts.poppins(
                        color: widget.isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
