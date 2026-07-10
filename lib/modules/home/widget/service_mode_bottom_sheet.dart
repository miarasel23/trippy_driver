import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/home_controller.dart';

class ServiceModeBottomSheet extends StatelessWidget {
  const ServiceModeBottomSheet({super.key});

  static void show(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext _) {
        return BlocProvider.value(
          value: context.read<HomeController>(),
          child: const ServiceModeBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildServiceOption(context, 'OFFLINE', theme, Icons.cloud_off),
            const SizedBox(height: 12),
            _buildServiceOption(context, 'RIDE SHARE', theme, Icons.directions_car_filled_outlined),
            const SizedBox(height: 12),
            _buildServiceOption(context, 'RENT A CAR', theme, Icons.car_rental),
            const SizedBox(height: 12),
            _buildServiceOption(context, 'BOTH', theme, Icons.merge_type),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(BuildContext context, String title, ThemeData theme, IconData icon) {
    return BlocBuilder<HomeController, HomeState>(
      builder: (context, state) {
        final bool isSelected = state.serviceMode == title;
        final Color activeColor = title == 'OFFLINE' ? Colors.red : Colors.green;

        return InkWell(
          onTap: () {
            context.read<HomeController>().setServiceMode(title);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? activeColor : theme.colorScheme.onSurface.withOpacity(0.05),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? activeColor : theme.colorScheme.onSurface),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? activeColor : theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: activeColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
