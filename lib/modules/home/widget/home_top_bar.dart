import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../routes/app_routes.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import '../controller/home_controller.dart';
import 'service_mode_bottom_sheet.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = UserDataStore.userData?.data?.user;
    final driverName = user?.fullName ?? 'Driver';

    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        final isOnline = state.isOnline;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.10),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: Avatar | Name | Online Toggle | Notification ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    // Profile avatar with online dot
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isOnline
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: AppUrls.profileImageUrl != null
                                  ? Image.network(
                                      AppUrls.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _defaultAvatar(driverName),
                                    )
                                  : _defaultAvatar(driverName),
                            ),
                          ),
                        ),
                        // Online status dot
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // Driver name + service mode label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Service mode — icon + text only, no background
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _serviceModeIcon(state.serviceMode),
                                size: 12,
                                color: isOnline
                                    ? const Color(0xFF90EE90)
                                    : const Color(0xFFFF3B30),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.serviceMode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: isOnline
                                      ? const Color(0xFF90EE90)
                                      : const Color(0xFFFF3B30),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),



                    // ── Online/Offline pill toggle ──
                    GestureDetector(
                      onTap: () =>
                          ServiceModeBottomSheet.show(context, theme),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 46,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glow dot
                            Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOnline
                                    ? const Color(0xFF90EE90)
                                        .withOpacity(0.15)
                                    : Colors.red.withOpacity(0.15),
                                border: Border.all(
                                  color: isOnline
                                      ? const Color(0xFF90EE90)
                                          .withOpacity(0.5)
                                      : Colors.red.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isOnline
                                        ? const Color(0xFF90EE90)
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            // Label pill
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFF90EE90)
                                    : const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOnline
                                    ? (loc.translate('online') ?? 'Online')
                                    : (loc.translate('offline') ?? 'Offline'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isOnline
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    const SizedBox(width: 8),

                    // Notification bell
                    GestureDetector(
                      onTap: () {}, // hook up notifications later
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──────────────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.grey.shade100,
                indent: 14,
                endIndent: 14,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _serviceModeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'RIDE SHARE':
        return Icons.directions_car_rounded;
      case 'RENT A CAR':
        return Icons.car_rental;
      case 'BOTH':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.power_settings_new_rounded;
    }
  }

  Widget _defaultAvatar(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'D';
    return Container(
      color: const Color(0xFF4CAF50).withOpacity(0.2),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
      ),
    );
  }
}

/// ── Small stat chip used in the bottom row ─────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.12)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.black.withOpacity(0.45),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
