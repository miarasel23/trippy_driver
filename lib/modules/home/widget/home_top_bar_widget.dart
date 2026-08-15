import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../routes/app_routes.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import '../controller/home_controller.dart';
import 'service_mode_bottom_sheet_widget.dart';

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({super.key});

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
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
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
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
                          onTap: () async {
                            await Navigator.pushNamed(context, AppRoutes.profile);
                            if (!mounted) return;
                            setState(() {});
                            if (context.mounted) {
                              context.read<HomeController>().checkAndUpdateRideStatusFromApi();
                            }
                          },
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
                                      key: ValueKey(AppUrls.profileImageUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, e) =>
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

                    // ── Online/Offline pill toggle (with active animation) ──
                    _OnlineToggleWidget(
                      isOnline: isOnline,
                      theme: theme,
                      loc: loc,
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
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    ? Colors.white.withValues(alpha: 0.07)
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
      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
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


/// ── Online / Offline Pill Toggle with Animated Radar & Breathing Glow Icon ──
class _OnlineToggleWidget extends StatefulWidget {
  final bool isOnline;
  final ThemeData theme;
  final AppLocalizations loc;

  const _OnlineToggleWidget({
    required this.isOnline,
    required this.theme,
    required this.loc,
  });

  @override
  State<_OnlineToggleWidget> createState() => _OnlineToggleWidgetState();
}

class _OnlineToggleWidgetState extends State<_OnlineToggleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isOnline) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _OnlineToggleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.isOnline;
    final loc = widget.loc;
    final theme = widget.theme;

    return GestureDetector(
      onTap: () => ServiceModeBottomSheet.show(context, theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated left icon / glow dot
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double value = _controller.value;
                // Sine wave pulse for smooth breathing effect (0.0 -> 1.0 -> 0.0)
                final double pulse = math.sin(value * math.pi);

                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding radar / sonar ripple ring when online
                      if (isOnline)
                        Transform.scale(
                          scale: 1.0 + (0.35 * value),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF90EE90)
                                    .withValues(alpha: 0.6 * (1.0 - value)),
                                width: 1.5,
                              ),
                              color: const Color(0xFF90EE90)
                                  .withValues(alpha: 0.2 * (1.0 - value)),
                            ),
                          ),
                        ),
                      // Main breathing circle container
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline
                              ? const Color(0xFF90EE90)
                                  .withValues(alpha: 0.15 + (0.2 * pulse))
                              : Colors.red.withValues(alpha: 0.15),
                          border: Border.all(
                            color: isOnline
                                ? const Color(0xFF90EE90)
                                    .withValues(alpha: 0.5 + (0.5 * pulse))
                                : Colors.red.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isOnline ? (10.0 + (2.5 * pulse)) : 10.0,
                            height: isOnline ? (10.0 + (2.5 * pulse)) : 10.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline
                                  ? const Color(0xFF90EE90)
                                  : Colors.red,
                              boxShadow: isOnline
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF90EE90)
                                            .withValues(alpha: 0.6 * pulse),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Label pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF90EE90)
                    : const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOnline
                    ? loc.translate('online')
                    : loc.translate('offline'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isOnline ? const Color(0xFF1A1A1A) : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
