import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../utils/app_urls.dart';
import '../controller/home_controller.dart';
import 'service_mode_bottom_sheet.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        final isOnline = state.isOnline;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.menu, color: theme.colorScheme.onSurface, size: 28),
              const SizedBox(width: 16),
              Text(
                state.serviceMode,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  ServiceModeBottomSheet.show(context, theme);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  minimumSize: const Size(110, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isOnline ? Colors.lightGreen : Colors.red,
                    width: 1,
                  ),
                  backgroundColor: isOnline ? Colors.lightGreen : Colors.red,
                  foregroundColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? "Online" : "Offline",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundImage: AppUrls.profileImageUrl != null 
                    ? NetworkImage(AppUrls.profileImageUrl!) 
                    : const AssetImage('assets/images/placeholder_profile.png') as ImageProvider,
                backgroundColor: Colors.grey.shade300,
              ),
            ],
          ),
        );
      },
    );
  }
}
