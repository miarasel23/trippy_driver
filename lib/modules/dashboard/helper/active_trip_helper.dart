import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTripHelper {
  static Future<void> launchCallOrUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Action Unavailable"),
            content: Text("Cannot launch $url."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  static IconData getVehicleIcon(String? carType) {
    if (carType == null) return Icons.directions_car;
    final lower = carType.toLowerCase();
    if (lower.contains('bike') || lower.contains('motor')) {
      return Icons.motorcycle;
    } else if (lower.contains('cng') || lower.contains('auto')) {
      return Icons.electric_rickshaw;
    } else if (lower.contains('micro') || lower.contains('van') || lower.contains('bus')) {
      return Icons.airport_shuttle;
    }
    return Icons.directions_car;
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(dateStr);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final amPm = dt.hour >= 12 ? "PM" : "AM";
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      return "${dt.day} ${months[dt.month - 1]}, ${dt.year} - $hour12:$minute $amPm";
    } catch (e) {
      return dateStr;
    }
  }

  static String formatServiceName(String? rawName) {
    if (rawName == null || rawName.isEmpty) return "";
    final temp = rawName.replaceAll('_', ' ').trim();
    if (temp.toLowerCase().contains("inter city renter")) {
      return "Inter city renter";
    }
    final lower = temp.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
