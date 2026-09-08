import '../core/utils/localization/app_localization.dart';

String toTiTleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

String formatSubscriptionType(String type, [AppLocalizations? loc]) {
  if (type.isEmpty) return type;
  final key = type.toLowerCase().trim();
  if (loc != null) {
    final translated = loc.translate(key);
    if (translated != key) {
      return translated;
    }
  }
  final cleaned = type.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return '';
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}
