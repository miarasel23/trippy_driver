import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../store/app_globals.dart';
import '../repository/legal_repository.dart';

import 'help_center_screen.dart';

class LegalPolicyScreen extends StatefulWidget {
  final String policyType;

  const LegalPolicyScreen({super.key, required this.policyType});

  @override
  State<LegalPolicyScreen> createState() => _LegalPolicyScreenState();
}

class _LegalPolicyScreenState extends State<LegalPolicyScreen> {
  bool _isLoading = true;
  bool _isEmpty = false;
  bool _hasFetched = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      if (widget.policyType != 'HELP_AND_SUPPORT') {
        final loc = AppLocalizations.of(context);
        _fetchPolicy(loc.locale.languageCode);
      }
    }
  }

  Future<void> _fetchPolicy(String languageCode) async {
    final repo = LegalRepository();
    final countryCode = AppGlobals.countryCodeForLanguage(languageCode);
    final policyModel = await repo.fetchPolicies(
      languageCode: languageCode,
      countryCode: countryCode,
    );

    String htmlContent = '';

    if (policyModel != null && policyModel.data.containsKey(widget.policyType)) {
      final items = policyModel.data[widget.policyType]!;
      if (items.isNotEmpty) {
        htmlContent = items.first.content;
      }
    }

    if (!mounted) return;

    // No content found — show empty state
    if (htmlContent.isEmpty) {
      setState(() {
        _isLoading = false;
        _isEmpty = true;
      });
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? '#E0E0E0' : '#1A1A1A';
    final bgColor = isDark ? '#1E2433' : '#FFFFFF';
    final h2Color = isDark ? '#90CAF9' : '#1565C0';
    final borderColor = isDark ? '#2A3143' : '#E0E0E0';

    final styledHtml = '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      font-size: 15px;
      color: $textColor;
      background-color: $bgColor;
      padding: 20px 16px;
      line-height: 1.7;
      word-wrap: break-word;
    }
    h1 {
      font-size: 20px;
      font-weight: 700;
      color: $textColor;
      margin-bottom: 12px;
      margin-top: 20px;
      padding-bottom: 8px;
      border-bottom: 2px solid $borderColor;
    }
    h2 {
      font-size: 16px;
      font-weight: 600;
      color: $h2Color;
      margin-top: 20px;
      margin-bottom: 8px;
    }
    h3 {
      font-size: 15px;
      font-weight: 600;
      color: $textColor;
      margin-top: 16px;
      margin-bottom: 6px;
    }
    p {
      margin-bottom: 12px;
    }
    ul, ol {
      margin: 10px 0 10px 20px;
    }
    li {
      margin-bottom: 6px;
    }
    strong {
      font-weight: 600;
      color: $textColor;
    }
    section {
      display: block;
    }
    a {
      color: #4285F4;
      text-decoration: none;
    }
  </style>
</head>
<body>
  $htmlContent
</body>
</html>''';

    _controller.loadHtmlString(styledHtml);
  }

  String _getTitle(AppLocalizations loc) {
    switch (widget.policyType) {
      case 'TERMS_CONDITION':
        return loc.translate('terms_conditions');
      case 'PRIVACY_POLICY':
        return loc.translate('privacy_policy');
      case 'TRIP_POLICY':
        return loc.translate('trip_terms_conditions');
      case 'HELP_AND_SUPPORT':
        return loc.translate('help');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.policyType == 'HELP_AND_SUPPORT') {
      return const HelpCenterScreen();
    }
    final loc = AppLocalizations.of(context);
    final title = _getTitle(loc);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainer,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isEmpty
                ? _buildEmptyState(context)
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading)
                        Container(
                          color: isDark ? const Color(0xFF1E2433) : Colors.white,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A3143)
                    : const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.article_outlined,
                size: 40,
                color: isDark
                    ? const Color(0xFF90CAF9)
                    : const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Content Not Available',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This document is not available for your region or language at the moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFF1565C0),
                  ),
                  foregroundColor: isDark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
