import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../store/user_data_store.dart';
import '../controller/home_controller.dart';
import '../../../../core/utils/localization/app_localization.dart';

class CancelTripDialog extends StatefulWidget {
  final String tripUuid;
  const CancelTripDialog({Key? key, required this.tripUuid}) : super(key: key);

  @override
  State<CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<CancelTripDialog> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedReasonKey;

  final List<Map<String, String>> _cancelReasons = [
    {'key': 'waiting_for_long_time', 'fallback': 'Waiting for a long time'},
    {'key': 'passenger_asked_to_cancel', 'fallback': 'Passenger asked to cancel'},
    {'key': 'changed_my_mind', 'fallback': 'Changed my mind'},
    {'key': 'other', 'fallback': 'Others'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    String comment = "";
    if (_selectedReasonKey == 'other') {
      comment = _commentController.text.trim();
      if (comment.isEmpty) comment = loc.translate('other') ?? 'Others';
    } else if (_selectedReasonKey != null) {
      comment = loc.translate(_selectedReasonKey!) ?? _cancelReasons.firstWhere((r) => r['key'] == _selectedReasonKey)['fallback']!;
    }

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('please_select_reason') ?? 'Please select a reason')));
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final controller = context.read<HomeController>();
      final error = await controller.cancelTrip(widget.tripUuid, comment);
      
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      if (error == null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.translate('why_are_you_cancelling') ?? 'Why are you cancelling?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ..._cancelReasons.map((reason) {
              final isSelected = _selectedReasonKey == reason['key'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedReasonKey = reason['key'];
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.deepPurpleAccent : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          loc.translate(reason['key']!) ?? reason['fallback']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (_selectedReasonKey == 'other') ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: loc.translate('please_write_your_reason') ?? 'Please write your reason...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      loc.translate('dismiss') ?? 'Dismiss',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            loc.translate('submit') ?? 'Submit',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
