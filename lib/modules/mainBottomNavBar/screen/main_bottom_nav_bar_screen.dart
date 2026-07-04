import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../dashboard/screen/dashboard_screen.dart';
import '../../myTrip/screen/myTrip_screen.dart';
import '../../profile/screen/profile_screen.dart';


import '../controller/main_bottom_nav_bar_bloc.dart';
import '../controller/main_bottom_nav_bar_event.dart';
import '../controller/main_bottom_nav_bar_state.dart';

class MainBottomNavBarScreen extends StatefulWidget {
  const MainBottomNavBarScreen({super.key});

  @override
  State<MainBottomNavBarScreen> createState() => _MainBottomNavBarScreenState();
}

class _MainBottomNavBarScreenState extends State<MainBottomNavBarScreen> {
  List<Widget> get _screens => const [
    ProfileScreen(),
    MytripScreen(),
    DashboardScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<MainBottomNavBarBloc, MainBottomNavBarState>(
        builder: (context, state) {
          return _screens[state.selectedIndex];
        },
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.grey,
        ),
        child: BlocBuilder<MainBottomNavBarBloc, MainBottomNavBarState>(
          builder: (context, state) {
            return BottomNavigationBar(
              selectedFontSize: 14,
              unselectedFontSize: 14,
              elevation: 0,
              currentIndex: state.selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.onSurface,
              unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onTap: (index) {
                context.read<MainBottomNavBarBloc>().add(ChangeTabEvent(index));
              },
              items: [
                BottomNavigationBarItem(
                  icon: IconTheme(
                    data: IconThemeData(
                      color: state.selectedIndex == 0
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: Icon(Icons.person),
                  ),
                  label: loc.translate("profile"),
                ),
                BottomNavigationBarItem(
                  icon: IconTheme(
                    data: IconThemeData(
                      color: state.selectedIndex == 1
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: Icon(Icons.train_sharp),
                  ),
                  label: loc.translate("my_trip"),
                ),
                BottomNavigationBarItem(
                  icon: IconTheme(
                    data: IconThemeData(
                      color: state.selectedIndex == 2
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    child: Icon(Icons.home_outlined),
                  ),
                  label: loc.translate("home"),
                ),
              ],
            );
          },
        ),
      ),

    );
  }
}
