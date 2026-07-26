import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../home/screen/home_screen.dart';
import '../../home/controller/home_controller.dart';
import '../../profile/screen/profile_screen.dart';
import 'bids_screen.dart';

class NavbarScreen extends StatefulWidget {
  const NavbarScreen({super.key});

  @override
  State<NavbarScreen> createState() => _NavbarScreenState();
}

class _NavbarScreenState extends State<NavbarScreen> {
  int _selectedIndex = 0;
  int _bidCount = 0;

  /// Incrementing this notifier triggers BidsScreen to reload with loading indicator.
  final ValueNotifier<int> _bidsRefreshTrigger = ValueNotifier<int>(0);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      BidsScreen(
        onNavigateToHome: () => _onItemTapped(0),
        onCountChanged: (count) {
          if (mounted && _bidCount != count) {
            setState(() => _bidCount = count);
          }
        },
        refreshTrigger: _bidsRefreshTrigger,
      ),
      const Center(child: Text('History')), // Placeholder
      const ProfileScreen(),
    ];
    _fetchUserData();
  }

  @override
  void dispose() {
    _bidsRefreshTrigger.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (mounted) {
      context.read<HomeController>().checkAndUpdateRideStatusFromApi();
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    if (index == 1 && _selectedIndex != 1) {
      // Trigger a fresh load with loading indicator every time user taps Bids
      _bidsRefreshTrigger.value++;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme, loc),
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.grid_view_rounded, loc.translate('home'), 0, theme),
              _buildBidsNavItem(Icons.car_rental, loc.translate('nav_bids'), 1, theme),
              _buildNavItem(Icons.history, loc.translate('nav_history'), 2, theme),
              _buildNavItem(Icons.person_outline, loc.translate('nav_profile'), 3, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          final homeCtrl = context.read<HomeController>();
          homeCtrl.selectTripForPreview(null);
          homeCtrl.clearTripToReview();
        }
        _onItemTapped(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.onSurface.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bids nav item with a green notification badge when _bidCount >= 1
  Widget _buildBidsNavItem(
      IconData icon, String label, int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.onSurface.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 30),
                if (_bidCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.lightGreen.shade500,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightGreen.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _bidCount > 99 ? '99+' : '$_bidCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
