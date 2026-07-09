import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool _isOnline = true;
  String _serviceMode = 'RIDE SHARE';

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco as placeholder
    zoom: 14.4746,
  );
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = Localizations.localeOf(context).languageCode == 'bn' ? '৳' : 'BDT';

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Google Map Background
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              // Set dark mode style if needed based on the theme
              // if (isDark) {
              //   controller.setMapStyle(darkMapStyle);
              // }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Add a subtle gradient overlay to make cards stand out better
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.scaffoldBackgroundColor.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                  theme.scaffoldBackgroundColor.withOpacity(0.9),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Top App Bar
                _buildTopBar(theme, loc, isDark),
                
                // 3. Current Session Card
                _buildCurrentSessionCard(theme, loc, currency),
                
                const Spacer(),

                // 4. New Rental Request Card
                _buildNewRequestCard(theme, loc, currency),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceModePopup(context, theme),
        backgroundColor: theme.colorScheme.onSurface,
        child: Icon(Icons.layers, color: theme.colorScheme.surface),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, AppLocalizations loc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.menu, color: theme.colorScheme.onSurface, size: 28),
          const SizedBox(width: 16),
          Text(
            loc.translate('app_name').toUpperCase(),
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
              setState(() {
                _isOnline = !_isOnline;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isOnline ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    loc.translate('online_status'), // Consider adding an 'offline_status' translation later
                    style: TextStyle(
                      color: _isOnline ? Colors.green : Colors.red,
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
            backgroundImage: const AssetImage('assets/images/placeholder_profile.png'), // placeholder
            backgroundColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSessionCard(ThemeData theme, AppLocalizations loc, String currency) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20), // Soft rounded edges for a small, modern look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat(
            theme,
            title: loc.translate('today_earn'),
            value: "142.50 $currency",
            icon: Icons.account_balance_wallet_rounded,
          ),
          Container(
            width: 1,
            height: 36,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          _buildCompactStat(
            theme,
            title: loc.translate('trippy_due'),
            value: "20.00 $currency",
            icon: Icons.receipt_long_rounded,
            valueColor: Colors.red, // Red because 20.00 > 0
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(ThemeData theme, {required String title, required String value, required IconData icon, Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewRequestCard(ThemeData theme, AppLocalizations loc, String currency) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 16),
              const SizedBox(width: 8),
              Text(
                loc.translate('new_rental_request'),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Premium Van", // Vehicle Type
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "42.00 $currency",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    loc.translate('est_fare'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.access_time,
                  title: loc.translate('pickup'),
                  value: "3 mins\n${loc.translate('pickup_away')}",
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  title: loc.translate('distance'),
                  value: "\n1.2 miles",
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.gavel, color: theme.colorScheme.surface),
              label: Text(
                loc.translate('bid_now'),
                style: TextStyle(
                  color: theme.colorScheme.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String value, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest, // Slightly darker surface
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showServiceModePopup(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
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
                _buildServiceOption('OFFLINE', theme, Icons.cloud_off),
                const SizedBox(height: 12),
                _buildServiceOption('RIDE SHARE', theme, Icons.directions_car_filled_outlined),
                const SizedBox(height: 12),
                _buildServiceOption('RENT A CAR', theme, Icons.car_rental),
                const SizedBox(height: 12),
                _buildServiceOption('BOTH', theme, Icons.merge_type),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceOption(String title, ThemeData theme, IconData icon) {
    final bool isSelected = _serviceMode == title;
    return InkWell(
      onTap: () {
        setState(() {
          _serviceMode = title;
          _isOnline = title != 'OFFLINE';
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.onSurface.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.05),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}
