import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization/app_localization.dart';
import 'package:trippy_rider/widgets/custom_message_widget.dart';

class UiUtils {
  static OverlayEntry? _currentToastEntry;

  /// Displays an API error message in a standardized popup dialog with red warning styling
  static void showApiErrorPopup(BuildContext context, String errorMessage) {
    final cleanMsg = errorMessage.replaceAll('Exception: ', '').replaceAll('Error: ', '');
    final isRateLimit = cleanMsg.toLowerCase().contains('blocked') ||
        cleanMsg.toLowerCase().contains('too many');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        const warningRed = Color(0xFFD32F2F);
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2433) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: warningRed, width: 1.5),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: warningRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRateLimit ? Icons.timer_off_rounded : Icons.warning_amber_rounded,
              color: warningRed,
              size: 36,
            ),
          ),
          title: Text(
            isRateLimit ? "Too Many Requests" : "Warning",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: warningRed,
            ),
          ),
          content: Text(
            cleanMsg,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: warningRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "OK",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a theme-aware custom toast from the top:
  ///  - Dark mode  → black background, white text
  ///  - Light mode → white background, black text
  ///
  /// [type] can be 'error', 'success', or 'info' (default).
  /// Error/success types add a small coloured left-side indicator while
  /// keeping the main background theme-aware (black/white).
  static void showAppSnackBar(
    BuildContext context,
    String message, {
    String type = 'info', // 'info' | 'success' | 'error'
    Duration duration = const Duration(seconds: 5),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    Color indicatorColor;
    switch (type) {
      case 'success':
        indicatorColor = Colors.green;
        break;
      case 'error':
        indicatorColor = Colors.red;
        break;
      default:
        indicatorColor = isDark ? Colors.white54 : Colors.black38;
    }

    final overlay = Overlay.of(context);

    // Safe removal of current toast
    if (_currentToastEntry != null) {
      try {
        _currentToastEntry!.remove();
      } catch (_) {}
      _currentToastEntry = null;
    }

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        type: type,
        bgColor: bgColor,
        textColor: textColor,
        indicatorColor: indicatorColor,
        duration: duration,
        onDismiss: () {
          if (_currentToastEntry == overlayEntry) {
            try {
              overlayEntry.remove();
            } catch (_) {}
            _currentToastEntry = null;
          }
        },
      ),
    );

    _currentToastEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final String type;
  final Color bgColor;
  final Color textColor;
  final Color indicatorColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    Key? key,
    required this.message,
    required this.type,
    required this.bgColor,
    required this.textColor,
    required this.indicatorColor,
    required this.duration,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Positioned(
      top: mediaQuery.padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: CustomMessageWidget(
            message: widget.message,
            type: widget.type,
            bgColor: widget.bgColor,
            textColor: widget.textColor,
            indicatorColor: widget.indicatorColor,
            onClose: _dismiss,
          ),
        ),
      ),
    );
  }
}
