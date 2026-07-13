import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../utils/app_urls.dart';
import '../controller/home_controller.dart';

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
              GestureDetector(
                onTap: () {
                  context.read<HomeController>().toggleOnlineStatus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOnline ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loc.translate('online_status'),
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
