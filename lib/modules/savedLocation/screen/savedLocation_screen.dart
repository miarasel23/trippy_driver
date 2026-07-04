import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../store/user_data_store.dart';
import '../../searchLocation/repository/search_location_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/colors_code.dart';
import '../../../widgets/customAdd_button.dart';
import '../../searchLocation/controller/search_location_bloc.dart';
import '../../searchLocation/model/search_location_model.dart';

class SavedlocationScreen extends StatefulWidget {
  final String? autoOpenLocationType;
  const SavedlocationScreen({super.key, this.autoOpenLocationType});

  @override
  State<SavedlocationScreen> createState() => _SavedlocationScreenState();
}

class _SavedlocationScreenState extends State<SavedlocationScreen> {
  bool _isLoading = false;
  bool _hasFetched = false;
  String? _homeAddress;
  String? _workAddress;
  String? _homeUuid;
  String? _workUuid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      _fetchSavedLocations().then((_) {
        // Auto-open bottom sheet if locationType was passed
        if (widget.autoOpenLocationType != null && mounted) {
          _showSearchBottomSheet(widget.autoOpenLocationType!);
        }
      });
    }
  }

  Future<void> _fetchSavedLocations() async {
    try {
      final customerUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
      if (customerUuid == null || customerUuid.isEmpty) return;
      
      setState(() {
        _isLoading = true;
      });

      final languageCode = AppLocalizations.of(context).locale.languageCode;
      
      final repo = SearchLocationRepository();
      final data = await repo.getCustomerLocations(customerUuid, languageCode);
      
      if (data['status'] == true && data['data'] != null) {
        final List locations = data['data'];
        _homeAddress = null;
        _workAddress = null;
        _homeUuid = null;
        _workUuid = null;
        for (var loc in locations) {
          if (loc['location_type'] == 'home' && loc['geo_location'] != null) {
            _homeAddress = loc['geo_location']['address'];
            _homeUuid = loc['uuid'];
          } else if (loc['location_type'] == 'work' && loc['geo_location'] != null) {
            _workAddress = loc['geo_location']['address'];
            _workUuid = loc['uuid'];
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch saved locations: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSearchBottomSheet(String locationType) {
    String? oldUuid = locationType == 'home' ? _homeUuid : _workUuid;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocProvider(
          create: (_) => SearchLocationBloc(SearchLocationRepository()),
          child: _SearchLocationBottomSheet(
            locationType: locationType,
            oldLocationUuid: oldUuid,
            onLocationSaved: (locData) {
              Navigator.pop(context);
              _fetchSavedLocations(); // Refresh list after saving
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("saved_locations"),
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            savedLocationCredentials(
              context,
              loc,
              Icon(
                Icons.home_filled,
                color: Theme.of(context).colorScheme.onSurface,
                size: 30,
              ),
              "home",
              _isLoading ? "Loading..." : _homeAddress,
              () => _showSearchBottomSheet("home"),
            ),
            SizedBox(height: 8),
            savedLocationCredentials(
              context,
              loc,
              Icon(
                Icons.work,
                color: Theme.of(context).colorScheme.onSurface,
                size: 30,
              ),
              "work",
              _isLoading ? "Loading..." : _workAddress,
              () => _showSearchBottomSheet("work"),
            ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget savedLocationCredentials(
    BuildContext context,
    AppLocalizations loc,
    Widget icon,
    String label,
    String? addressText,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                icon,
                SizedBox(width: 15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate(label),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.55,
                      child: Text(
                        addressText ?? loc.translate("set_address"),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 20,
              color: AppColors.savedLocationsScreenSavedLocationArrow,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchLocationBottomSheet extends StatefulWidget {
  final String locationType;
  final String? oldLocationUuid;
  final Function(SearchLocationData) onLocationSaved;

  const _SearchLocationBottomSheet({
    required this.locationType,
    this.oldLocationUuid,
    required this.onLocationSaved,
  });

  @override
  State<_SearchLocationBottomSheet> createState() => _SearchLocationBottomSheetState();
}

class _SearchLocationBottomSheetState extends State<_SearchLocationBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation(SearchLocationData loc) async {
    debugPrint(">>> _saveLocation called: uuid=${loc.uuid}, address=${loc.address}");
    
    // Load from SharedPreferences since static variable may not be set yet
    final customerUuid = UserDataStore.uuid ?? await UserDataStore.getUuid();
    debugPrint(">>> customerUuid=$customerUuid");
    
    if (customerUuid == null || customerUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
      return;
    }

    if (loc.uuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Missing location UUID')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = SearchLocationRepository();
      final languageCode = AppLocalizations.of(context).locale.languageCode;
      
      if (widget.oldLocationUuid != null) {
        debugPrint(">>> Deleting old location: ${widget.oldLocationUuid}");
        try {
          await repo.deleteCustomerLocation(
            customerUuid: customerUuid,
            locationUuid: widget.oldLocationUuid!,
            languageCode: languageCode,
          );
        } catch (e) {
          debugPrint(">>> Failed to delete old location: $e");
          // Proceed with save anyway
        }
      }

      debugPrint(">>> Calling saveCustomerLocation: geoLocatUuid=${loc.uuid}, locationType=${widget.locationType}");
      
      final response = await repo.saveCustomerLocation(
        customerUuid: customerUuid,
        geoLocatUuid: loc.uuid!,
        locationType: widget.locationType,
        languageCode: languageCode,
      );

      debugPrint(">>> Save response: $response");

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              response['message'] ?? 'Location saved successfully',
              style: TextStyle(color: Theme.of(context).colorScheme.surface),
            ),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            behavior: SnackBarBehavior.floating,
          ));
        }
        widget.onLocationSaved(loc);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to save')));
      }
    } catch (e) {
      debugPrint(">>> Error saving: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: 20, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.translate("search_location") ?? "Search Location",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: loc.translate("search_your_location") ?? "Search...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (val) {
                final languageCode = loc.locale.languageCode;
                context.read<SearchLocationBloc>().add(SearchQueryChanged(val, languageCode));
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_isSaving)
            LinearProgressIndicator(
              color: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          SizedBox(
            height: 250,
            child: BlocBuilder<SearchLocationBloc, SearchLocationState>(
              builder: (context, state) {
                if (state is SearchLocationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SearchLocationSuccess) {
                  if (state.locations.isEmpty) {
                    return Center(child: Text(loc.translate("no_results") ?? "No results"));
                  }
                  return ListView.builder(
                    itemCount: state.locations.length,
                    itemBuilder: (context, index) {
                      final locData = state.locations[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.grey),
                        title: Text(locData.address ?? ""),
                        onTap: () {
                          if (!_isSaving) {
                            _saveLocation(locData);
                          }
                        },
                      );
                    },
                  );
                } else if (state is SearchLocationFailure) {
                  return Center(child: Text(state.error));
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
