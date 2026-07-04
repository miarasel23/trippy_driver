import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../searchLocation/model/search_location_model.dart';
import '../../searchLocation/repository/search_location_repository.dart';
import '../../../store/user_data_store.dart';

class SavedLocationsRowWidget extends StatefulWidget {
  final AppLocalizations loc;
  final Function(SearchLocationData) onLocationSelected;

  const SavedLocationsRowWidget({
    super.key,
    required this.loc,
    required this.onLocationSelected,
  });

  @override
  State<SavedLocationsRowWidget> createState() => _SavedLocationsRowWidgetState();
}

class _SavedLocationsRowWidgetState extends State<SavedLocationsRowWidget> {
  Map<String, dynamic>? _homeLocation;
  Map<String, dynamic>? _workLocation;
  double? _homeDistance;
  double? _workDistance;
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedLocations();
  }

  Future<void> _fetchSavedLocations() async {
    try {
      final customerUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
      if (customerUuid == null || customerUuid.isEmpty) return;
      
      setState(() {
        _isLoadingLocations = true;
      });

      final languageCode = widget.loc.locale.languageCode;
      
      final repo = SearchLocationRepository();
      final data = await repo.getCustomerLocations(customerUuid, languageCode);
      
      if (data['status'] == true && data['data'] != null) {
        final List locations = data['data'];
        for (var loc in locations) {
          if (loc['location_type'] == 'home') {
            _homeLocation = loc;
          } else if (loc['location_type'] == 'work') {
            _workLocation = loc;
          }
        }
        _calculateDistances();
      }
    } catch (e) {
      debugPrint("Failed to fetch saved locations: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
  }

  Future<void> _calculateDistances() async {
    try {
      final position = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
      
      if (_homeLocation != null && _homeLocation!['geo_location'] != null) {
        final lat = double.tryParse(_homeLocation!['geo_location']['latitude'].toString());
        final lng = double.tryParse(_homeLocation!['geo_location']['longitude'].toString());
        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
          _homeDistance = distance / 1000;
        }
      }

      if (_workLocation != null && _workLocation!['geo_location'] != null) {
        final lat = double.tryParse(_workLocation!['geo_location']['latitude'].toString());
        final lng = double.tryParse(_workLocation!['geo_location']['longitude'].toString());
        if (lat != null && lng != null) {
          final distance = Geolocator.distanceBetween(position.latitude, position.longitude, lat, lng);
          _workDistance = distance / 1000;
        }
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Failed to calculate distances: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildSavedLocItem(
            context, 
            Icons.home, 
            widget.loc.translate("home") ?? "Home", 
            _isLoadingLocations 
              ? "Loading..." 
              : (_homeLocation != null && _homeLocation!['geo_location'] != null 
                  ? (_homeLocation!['geo_location']['address'] as String) 
                  : "Not set"), 
            () {
              if (_homeLocation != null && _homeLocation!['geo_location'] != null) {
                final lat = double.tryParse(_homeLocation!['geo_location']['latitude'].toString());
                final lng = double.tryParse(_homeLocation!['geo_location']['longitude'].toString());
                if (lat != null && lng != null) {
                  final locData = SearchLocationData(
                    uuid: _homeLocation!['geo_location']['uuid'] ?? _homeLocation!['geo_locat_uuid'],
                    placeId: _homeLocation!['geo_location']['place_id'],
                    address: _homeLocation!['geo_location']['address'],
                    latitude: lat,
                    longitude: lng,
                  );
                  widget.onLocationSelected(locData);
                  return;
                }
              }
              Navigator.pushNamed(context, AppRoutes.savedLoc, arguments: "home");
            },
            isSet: _homeLocation != null,
            onEdit: () => Navigator.pushNamed(context, AppRoutes.savedLoc, arguments: "home").then((_) => _fetchSavedLocations()),
          ),
        ),
        Container(width: 1, height: 30, color: Theme.of(context).colorScheme.outlineVariant),
        Expanded(
          child: _buildSavedLocItem(
            context, 
            Icons.work, 
            widget.loc.translate("work") ?? "Work", 
            _isLoadingLocations 
              ? "Loading..." 
              : (_workLocation != null && _workLocation!['geo_location'] != null 
                  ? (_workLocation!['geo_location']['address'] as String) 
                  : "Not set"), 
            () {
              if (_workLocation != null && _workLocation!['geo_location'] != null) {
                final lat = double.tryParse(_workLocation!['geo_location']['latitude'].toString());
                final lng = double.tryParse(_workLocation!['geo_location']['longitude'].toString());
                if (lat != null && lng != null) {
                  final locData = SearchLocationData(
                    uuid: _workLocation!['geo_location']['uuid'] ?? _workLocation!['geo_locat_uuid'],
                    placeId: _workLocation!['geo_location']['place_id'],
                    address: _workLocation!['geo_location']['address'],
                    latitude: lat,
                    longitude: lng,
                  );
                  widget.onLocationSelected(locData);
                  return;
                }
              }
              Navigator.pushNamed(context, AppRoutes.savedLoc, arguments: "work");
            },
            isSet: _workLocation != null,
            onEdit: () => Navigator.pushNamed(context, AppRoutes.savedLoc, arguments: "work").then((_) => _fetchSavedLocations()),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedLocItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isSet = false,
    VoidCallback? onEdit,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isSet && onEdit != null)
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.edit, size: 14, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}
