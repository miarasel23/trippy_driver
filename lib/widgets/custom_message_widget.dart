import 'package:flutter/material.dart';

class CustomMessageWidget extends StatelessWidget {
  final String message;
  final String type; // 'info' | 'success' | 'error'
  final VoidCallback? onClose;
  final Color? bgColor;
  final Color? textColor;
  final Color? indicatorColor;

  const CustomMessageWidget({
    Key? key,
    required this.message,
    this.type = 'info',
    this.onClose,
    this.bgColor,
    this.textColor,
    this.indicatorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedBgColor = bgColor ?? (isDark ? Colors.black : Colors.white);
    final resolvedTextColor = textColor ?? (isDark ? Colors.white : Colors.black);

    Color resolvedIndicatorColor;
    if (indicatorColor != null) {
      resolvedIndicatorColor = indicatorColor!;
    } else {
      switch (type) {
        case 'success':
          resolvedIndicatorColor = Colors.green;
          break;
        case 'error':
          resolvedIndicatorColor = Colors.red;
          break;
        default:
          resolvedIndicatorColor = isDark ? Colors.white54 : Colors.black38;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: resolvedBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: resolvedIndicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: resolvedTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: resolvedTextColor.withValues(alpha: 0.6), size: 18),
              onPressed: onClose,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
