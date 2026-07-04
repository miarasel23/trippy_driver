import 'package:flutter/material.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../core/utils/ui_utils.dart';

class DateTimeSelectionDialogs {
  static Future<DateTime?> pickDateAndTime(BuildContext context, {DateTime? initialDate, DateTime? minDateTime, String? dateHelpText, String? timeHelpText}) async {
    final DateTime now = DateTime.now();
    final DateTime effectiveMinRaw = minDateTime ?? now;
    final DateTime effectiveMinDateTime = DateTime(effectiveMinRaw.year, effectiveMinRaw.month, effectiveMinRaw.day, effectiveMinRaw.hour, effectiveMinRaw.minute);
    final DateTime firstDate = DateTime(effectiveMinDateTime.year, effectiveMinDateTime.month, effectiveMinDateTime.day);

    // Unfocus immediately before date picker to clear primary focus
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final DateTime? date = await showDatePicker(
      context: context,
      helpText: dateHelpText,
      initialDate: initialDate != null && initialDate.isAfter(firstDate) ? initialDate : effectiveMinDateTime,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    // Unfocus immediately after date picker is dismissed or completed
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    if (date != null) {
      TimeOfDay initialTime = TimeOfDay.fromDateTime(effectiveMinDateTime);
      while (true) {
        // Unfocus immediately before time picker
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();

        final TimeOfDay? time = await showTimePicker(
          context: context,
          helpText: timeHelpText,
          initialTime: initialTime,
          initialEntryMode: TimePickerEntryMode.dialOnly,
        );

        // Unfocus immediately after time picker is dismissed or completed
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();

        if (time != null) {
          final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (selectedDateTime.isBefore(effectiveMinDateTime)) {
            if (context.mounted) {
              final loc = AppLocalizations.of(context);
              final String timePrefix = loc.translate('please_select_time_after') ?? 'Please select a time after';
              final int hr = effectiveMinDateTime.hour > 12 ? effectiveMinDateTime.hour - 12 : (effectiveMinDateTime.hour == 0 ? 12 : effectiveMinDateTime.hour);
              final String min = effectiveMinDateTime.minute.toString().padLeft(2, '0');
              final String amPm = effectiveMinDateTime.hour >= 12 ? "PM" : "AM";

              UiUtils.showAppSnackBar(
                context,
                '$timePrefix $hr:$min $amPm',
                type: 'error',
              );
            }
          } else {
            return selectedDateTime;
          }
        } else {
          return null;
        }
      }
    }
    return null;
  }

  /// Prompts the user to select hours from 1 to 24 using a professional dropdown dialog.
  static Future<int?> pickHours(BuildContext context) async {
    // Unfocus before dialog
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final int? result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return const _HourSelectionDialog();
      },
    );

    // Unfocus after dialog
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    return result;
  }
}

class _HourSelectionDialog extends StatefulWidget {
  const _HourSelectionDialog({Key? key}) : super(key: key);

  @override
  State<_HourSelectionDialog> createState() => _HourSelectionDialogState();
}

class _HourSelectionDialogState extends State<_HourSelectionDialog> {
  int _selectedHour = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Select Duration",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "How long do you need the vehicle?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: _selectedHour,
              dropdownColor: Theme.of(context).colorScheme.surface,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blue),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[50] : Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              items: List.generate(24, (index) {
                final int hour = index + 1;
                return DropdownMenuItem(
                  value: hour,
                  child: Text(
                    "$hour ${hour == 1 ? 'Hour' : 'Hours'}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedHour = val);
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(_selectedHour);
                },
                child: Text(
                  "Confirm Selection",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
