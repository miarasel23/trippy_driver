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
    if (oldWidget.text != widget.text || oldWidget.isBangla != widget.isBangla) {
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

    try {
      final res = await _translator.translate(widget.text, from: 'auto', to: 'bn').timeout(const Duration(seconds: 10));
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
