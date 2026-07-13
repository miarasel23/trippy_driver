import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:geocoding/geocoding.dart';
import '../model/rental_trip_model.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final bool isBangla;
  final LocationModel? location;

  const TranslatedText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.isBangla = false,
    this.location,
  }) : super(key: key);

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = "";
  final GoogleTranslator _translator = GoogleTranslator();
  static final Map<String, String> _cache = {};
  String _lastLang = 'en';

  @override
  void initState() {
    super.initState();
    _translatedText = widget.text;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_translatedText == widget.text) {
      _translate();
    }
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _translatedText = widget.text;
      _translate();
    }
  }

  Future<void> _translate() async {
    if (!widget.isBangla) {
      if (mounted) setState(() => _translatedText = widget.text);
      return;
    }

    if (_cache.containsKey(widget.text)) {
      if (mounted) setState(() => _translatedText = _cache[widget.text]!);
      return;
    }

    // Attempt geocoding first if location is provided
    if (widget.location != null) {
      try {
        final _geocoder = Geocoding(locale: const Locale('bn', 'BD'));
        final placemarks = await _geocoder.placemarkFromCoordinates(
          widget.location!.latitude,
          widget.location!.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.street != null && p.street!.isNotEmpty && !p.street!.contains('+')) parts.add(p.street!);
          if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
          if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
          if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
          if (parts.isNotEmpty) {
            final translated = parts.join(', ');
            _cache[widget.text] = translated;
            if (mounted) setState(() => _translatedText = translated);
            return;
          }
        }
      } catch (e) {
        // Fallback to text translation
      }
    }

    try {
      final res = await _translator.translate(widget.text, from: 'auto', to: 'bn').timeout(const Duration(seconds: 3));
      _cache[widget.text] = res.text;
      if (mounted) {
        setState(() => _translatedText = res.text);
      }
    } catch (e) {
      // Ignore translation errors and fallback to original
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
