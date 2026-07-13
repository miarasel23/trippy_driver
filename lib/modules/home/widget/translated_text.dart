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
  String _displayText = '';
  bool _isLoading = false;
  final GoogleTranslator _translator = GoogleTranslator();

  // Static shared cache so repeated addresses are not re-fetched
  // Cache key format: "bn:<original_text>"
  static final Map<String, String> _cache = {};

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
    _translate(widget.isBangla);
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.isBangla != widget.isBangla) {
      _displayText = widget.text;
      _translate(widget.isBangla);
    }
  }

  Future<void> _translate(bool toBangla) async {
    if (!toBangla) {
      // Switch back to English immediately
      if (mounted) setState(() => _displayText = widget.text);
      return;
    }

    final cacheKey = 'bn:${widget.text}';

    // Serve from cache immediately — no loading spinner needed
    if (_cache.containsKey(cacheKey)) {
      if (mounted) setState(() => _displayText = _cache[cacheKey]!);
      return;
    }

    // Show spinner while network translation is in progress
    if (mounted) setState(() => _isLoading = true);

    try {
      // 1. Try to get a true localized address via reverse geocoding if location is provided
      if (widget.location != null) {
        final lat = widget.location!.latitude;
        final lng = widget.location!.longitude;
        if (lat != 0.0 && lng != 0.0) {
          try {
            // Note: placemarkFromCoordinates may be slow or throw on some devices
            final _geocoder = Geocoding();
            List<Placemark> placemarks = await _geocoder.placemarkFromCoordinates(
              lat, lng
            ).timeout(const Duration(seconds: 5));
            
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              final components = [place.street, place.subLocality, place.locality, place.country]
                  .where((c) => c != null && c.isNotEmpty)
                  .toList();
              
              if (components.isNotEmpty) {
                final resultText = components.join(', ');
                _cache[cacheKey] = resultText;
                if (mounted) {
                  setState(() {
                    _displayText = resultText;
                    _isLoading = false;
                  });
                }
                return;
              }
            }
          } catch (_) {
            // Silently fallback to Google Translator if geocoding fails
          }
        }
      }

      // 2. Fallback: Google Translator
      final result = await _translator
          .translate(widget.text, from: 'auto', to: 'bn')
          .timeout(const Duration(seconds: 10));

      _cache[cacheKey] = result.text;

      if (mounted) {
        setState(() {
          _displayText = result.text;
          _isLoading = false;
        });
      }
    } catch (_) {
      // On timeout or network error, fall back to original English text
      if (mounted) {
        setState(() {
          _displayText = widget.text;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: widget.style?.color ?? Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return Text(
      _displayText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
