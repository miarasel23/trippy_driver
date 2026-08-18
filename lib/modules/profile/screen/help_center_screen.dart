import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../../store/user_data_store.dart';

import '../../../store/app_globals.dart';
import '../repository/legal_repository.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  bool _isLoading = true;
  List<String> _phoneNumbers = [];
  List<String> _emailAddresses = [];
  static const String _emergencyPhone = '999';
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      final loc = AppLocalizations.of(context);
      _fetchSupportData(loc.locale.languageCode);
    }
  }

  Future<void> _fetchSupportData(String languageCode) async {
    final countryCode = AppGlobals.countryCodeForLanguage(languageCode);
    final repo = LegalRepository();
    final policyModel = await repo.fetchPolicies(
      languageCode: languageCode,
      countryCode: countryCode,
    );

    final phones = <String>[];
    final emails = <String>[];

    if (policyModel != null && policyModel.data.containsKey('HELP_AND_SUPPORT')) {
      final helpItems = policyModel.data['HELP_AND_SUPPORT']!;
      for (final item in helpItems) {
        final rawContent = item.content;
        final parts = rawContent.split(RegExp(r'[\n,]'));
        for (var part in parts) {
          part = part.trim();
          if (part.isEmpty) continue;

          if (part.contains('@')) {
            final emailMatch = RegExp(r'[\w\.-]+@[\w\.-]+\.\w+').firstMatch(part);
            final email = emailMatch != null ? emailMatch.group(0)! : part;
            if (!emails.contains(email)) {
              emails.add(email);
            }
          } else {
            final phoneMatch = RegExp(r'[\+0-9\s\-]{6,}').firstMatch(part);
            if (phoneMatch != null) {
              final phone = phoneMatch.group(0)!.trim();
              if (!phones.contains(phone)) {
                phones.add(phone);
              }
            }
          }
        }
      }
    }

    if (phones.isEmpty) {
      phones.add('+8809611080143');
    }
    if (emails.isEmpty) {
      emails.add('help@tripyservice.com');
    }

    if (mounted) {
      setState(() {
        _phoneNumbers = phones;
        _emailAddresses = emails;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $urlString'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── APP BAR ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: primaryTextColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    loc.translate('help_center'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE CONTENT ───────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── HERO BANNER CARD ──────────────────────────────────
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                                    : [const Color(0xFF0D6EFD), const Color(0xFF0040A8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D6EFD).withValues(alpha: isDark ? 0.2 : 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -20,
                                  top: -20,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 40,
                                  bottom: -30,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.05),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              loc.translate('how_can_we_help'),
                                              style: GoogleFonts.poppins(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '24/7 Driver Support',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.headset_mic_rounded,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── SUPPORT OPTIONS LIST ─────────────────────────────
                          _HelpOptionCard(
                            icon: Icons.chat_bubble_rounded,
                            iconBgColor: const Color(0xFF0D6EFD),
                            title: loc.translate('message_customer_care'),
                            subtitle: loc.translate('message_customer_care_sub'),
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            onTap: () {
                              final driverUuid = UserDataStore.uuid ?? UserDataStore.userData?.data?.user?.uuid ?? '';
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: {
                                  'driverUuid': driverUuid,
                                  'customerUuid': '',
                                  'customerName': loc.translate('message_customer_care'),
                                  'receiverType': 'ADMIN',
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          ..._phoneNumbers.map((phone) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _HelpOptionCard(
                                icon: Icons.phone_in_talk_rounded,
                                iconBgColor: const Color(0xFF0284C7),
                                title: phone,
                                subtitle: loc.translate('talk_to_customer_care_sub'),
                                cardBgColor: cardBgColor,
                                borderColor: borderColor,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                onTap: () => _launchUrl(context, 'tel:$phone'),
                              ),
                            );
                          }),

                          ..._emailAddresses.map((email) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _HelpOptionCard(
                                icon: Icons.mark_email_unread_rounded,
                                iconBgColor: const Color(0xFF3B82F6),
                                title: email,
                                subtitle: loc.translate('email_support_sub'),
                                cardBgColor: cardBgColor,
                                borderColor: borderColor,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                onTap: () => _launchUrl(context, 'mailto:$email'),
                              ),
                            );
                          }),

                          _HelpOptionCard(
                            iconWidget: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'জাতীয়',
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 7,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '৯৯৯',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: loc.translate('emergency_service_999'),
                            subtitle: loc.translate('emergency_service_sub'),
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            isEmergency: true,
                            onTap: () => _launchUrl(context, 'tel:$_emergencyPhone'),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpOptionCard extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconBgColor;
  final String title;
  final String subtitle;
  final Color cardBgColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isEmergency;
  final VoidCallback onTap;

  const _HelpOptionCard({
    this.icon,
    this.iconWidget,
    this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.cardBgColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.isEmergency = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? const Color(0xFFFCA5A5) : borderColor,
          width: isEmergency ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Leading Icon Box
                if (iconWidget != null)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: iconWidget,
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor ?? const Color(0xFF0D6EFD),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (iconBgColor ?? const Color(0xFF0D6EFD))
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                const SizedBox(width: 16),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing Arrow
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isEmergency
                        ? const Color(0xFFFEE2E2)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isEmergency
                        ? const Color(0xFFDC2626)
                        : secondaryTextColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
