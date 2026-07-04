import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../searchLocation/model/search_location_model.dart';
import '../../searchLocation/controller/search_location_bloc.dart';
import '../../searchLocation/repository/search_location_repository.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';
import 'saved_locations_row_widget.dart';
class SearchAndSavedCardWidget extends StatefulWidget {
  final AppLocalizations loc;
  final Function(List<SearchLocationData>) onPickupsUpdated;
  final Function(SearchLocationData)? onDestinationSelected;
  final Function(bool isDropFocused)? onFocusChanged;
  final VoidCallback? onMyLocationTapped;

  const SearchAndSavedCardWidget({
    super.key,
    required this.loc,
    required this.onPickupsUpdated,
    this.onDestinationSelected,
    this.onFocusChanged,
    this.onMyLocationTapped,
  });

  @override
  SearchAndSavedCardWidgetState createState() => SearchAndSavedCardWidgetState();
}

class SearchAndSavedCardWidgetState extends State<SearchAndSavedCardWidget> {
  final List<TextEditingController> _pickupControllers = [TextEditingController()];
  final List<FocusNode> _pickupFocusNodes = [FocusNode()];
  final List<SearchLocationData?> _selectedPickups = [null];
  final TextEditingController _destController = TextEditingController();
  final FocusNode _destFocusNode = FocusNode();
  late SearchLocationBloc _bloc;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropActive = false;
  String? _lastSelectedDestAddress;

  Future<void> _resolveDropoffAddress() async {
    final query = _destController.text.trim();
    if (query.isEmpty) return;
    if (query == _lastSelectedDestAddress) return;

    try {
      final repo = SearchLocationRepository();
      final response = await repo.searchLocations(query, widget.loc.locale.languageCode);
      if (response.data != null && response.data!.isNotEmpty) {
        final loc = response.data!.first;
        _destController.text = loc.address ?? "";
        _lastSelectedDestAddress = loc.address;
        
        if (widget.onDestinationSelected != null) {
          widget.onDestinationSelected!(loc);
        }
      }
    } catch (e) {
      debugPrint("Failed to resolve dropoff address: $e");
    }
  }

  void _setupFocusListener(FocusNode node) {
    node.addListener(() {
      if (_destFocusNode.hasFocus) {
        _isDropActive = true;
      } else if (_pickupFocusNodes.any((n) => n.hasFocus)) {
        _isDropActive = false;
      }

      bool anyFocused = _pickupFocusNodes.any((n) => n.hasFocus) || _destFocusNode.hasFocus;
      if (anyFocused) {
        _showOverlay();
      } else {
        _removeOverlay();
      }

      // Automatically search/resolve drop-off address if the node lost focus
      if (node == _destFocusNode && !_destFocusNode.hasFocus) {
        _resolveDropoffAddress();
      }

      widget.onFocusChanged?.call(_isDropActive);
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _bloc = SearchLocationBloc(SearchLocationRepository());
    _setupFocusListener(_pickupFocusNodes[0]);
    _setupFocusListener(_destFocusNode);

    _bloc.stream.listen((state) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40, // Full width of the card
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -4), // Floats just 4px above the top of the card
          child: BlocProvider.value(
            value: _bloc,
            child: BlocBuilder<SearchLocationBloc, SearchLocationState>(
              builder: (context, state) {
                if (state is SearchLocationLoading) {
                  return Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else if (state is SearchLocationSuccess && state.locations.isNotEmpty) {
                  return Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                for (var n in _pickupFocusNodes) n.unfocus();
                                _destFocusNode.unfocus();
                              },
                            ),
                          ),
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.locations.length,
                              separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3)),
                        itemBuilder: (context, index) {
                          final loc = state.locations[index];
                          final parts = (loc.address ?? "").split(',');
                          final title = parts.first;
                          final subtitle = parts.length > 1 ? parts.skip(1).join(',').trim() : "";

                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.blue),
                            title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                            subtitle: subtitle.isNotEmpty
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2), // 2px line break height
                                      Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                    ],
                                  )
                                : null,
                            onTap: () {
                              int pickupIndex = _pickupFocusNodes.indexWhere((n) => n.hasFocus);
                              if (pickupIndex != -1) {
                                _pickupControllers[pickupIndex].text = loc.address ?? "";
                                _selectedPickups[pickupIndex] = loc;
                                _pickupFocusNodes[pickupIndex].unfocus();
                                
                                final List<SearchLocationData> validPickups = _selectedPickups.whereType<SearchLocationData>().toList();
                                widget.onPickupsUpdated(validPickups);
                              } else if (_destFocusNode.hasFocus) {
                                _destController.text = loc.address ?? "";
                                _lastSelectedDestAddress = loc.address;
                                _destFocusNode.unfocus();
                                if (widget.onDestinationSelected != null) {
                                  widget.onDestinationSelected!(loc);
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
            }
                return const SizedBox.shrink(); // Hide overlay if nothing is found or empty
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    for (var c in _pickupControllers) { c.dispose(); }
    for (var n in _pickupFocusNodes) { n.dispose(); }
    _destController.dispose();
    _destFocusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  bool get isDropFocused => _isDropActive;

  bool _isFetchingLocation = false;

  void setFetchingLocation(bool isFetching) {
    if (mounted) {
      setState(() {
        _isFetchingLocation = isFetching;
      });
    }
  }

  /// Called externally (e.g., from map drag) to update the active field
  void updateActiveFieldText(String address) {
    setState(() {
      if (_isDropActive) {
        _destController.text = address;
      } else {
        int idx = getActivePickupIndex();
        if (idx >= 0 && idx < _pickupControllers.length) {
          _pickupControllers[idx].text = address;
        }
      }
    });
  }

  int getActivePickupIndex() {
    for (int i = 0; i < _pickupFocusNodes.length; i++) {
      if (_pickupFocusNodes[i].hasFocus) return i;
    }
    return 0; // Default to first
  }

  void setLocationFromMapDrag(SearchLocationData location) {
    setState(() {
      if (_isDropActive) {
        _destController.text = location.address ?? "";
        _lastSelectedDestAddress = location.address;
      } else {
        int idx = getActivePickupIndex();
        if (idx >= 0 && idx < _pickupControllers.length) {
           _pickupControllers[idx].text = location.address ?? "";
           _selectedPickups[idx] = location;
        }
      }
    });
  }

  void _onHomeWorkTapped(SearchLocationData locData) {
    setState(() {
      if (_isDropActive) {
        _destController.text = locData.address ?? "";
        _lastSelectedDestAddress = locData.address;
        if (widget.onDestinationSelected != null) {
          widget.onDestinationSelected!(locData);
        }
      } else if (_pickupFocusNodes.any((n) => n.hasFocus)) {
        int idx = getActivePickupIndex();
        if (idx >= 0 && idx < _pickupControllers.length) {
          _pickupControllers[idx].text = locData.address ?? "";
          _selectedPickups[idx] = locData;
          widget.onPickupsUpdated(getValidPickups());
        }
      } else {
        // Nothing is explicitly focused, default to destination
        _destController.text = locData.address ?? "";
        _lastSelectedDestAddress = locData.address;
        if (widget.onDestinationSelected != null) {
          widget.onDestinationSelected!(locData);
        }
      }
    });
  }

  List<SearchLocationData> getValidPickups() {
    return _selectedPickups.whereType<SearchLocationData>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    // timeline dots
                    Column(
                      children: [
                        const SizedBox(height: 24), // Approx center of first field
                        for (int i = 0; i < _pickupControllers.length; i++) ...[
                          if (i > 0) Expanded(child: Container(width: 2, color: Colors.grey.withOpacity(0.3))),
                          const Icon(Icons.circle, size: 8, color: Colors.grey),
                        ],
                        Expanded(child: Container(width: 2, color: Colors.grey.withOpacity(0.3))),
                        Icon(Icons.square, size: 8, color: Colors.blue[200]),
                        const SizedBox(height: 24), // Approx center of last field
                      ],
                    ),
                    const SizedBox(width: 8),
                    // text fields
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < _pickupControllers.length; i++) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _pickupControllers[i],
                                            focusNode: _pickupFocusNodes[i],
                                            onChanged: (val) {
                                              _bloc.add(SearchQueryChanged(val, widget.loc.locale.languageCode));
                                            },
                                            decoration: InputDecoration(
                                              hintText: i == 0 ? (widget.loc.translate("pick_up_location") ?? "Pick up location") : "Add stop",
                                              border: InputBorder.none,
                                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                            ),
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                          ),
                                        ),
                                        if (i > 0)
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                _pickupControllers[i].dispose();
                                                _pickupFocusNodes[i].dispose();
                                                _pickupControllers.removeAt(i);
                                                _pickupFocusNodes.removeAt(i);
                                                _selectedPickups.removeAt(i);
                                                
                                                final List<SearchLocationData> validPickups = _selectedPickups.whereType<SearchLocationData>().toList();
                                                widget.onPickupsUpdated(validPickups);
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (i == 0) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: widget.onMyLocationTapped,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        shape: BoxShape.circle,
                                      ),
                                      child: _isFetchingLocation
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Icon(Icons.my_location, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 18),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(width: 30), // Placeholder to keep field widths consistent
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    controller: _destController,
                                    focusNode: _destFocusNode,
                                    onChanged: (val) {
                                      _bloc.add(SearchQueryChanged(val, widget.loc.locale.languageCode));
                                    },
                                    onSubmitted: (_) => _resolveDropoffAddress(),
                                    decoration: InputDecoration(
                                      hintText: widget.loc.translate("where_are_you_going") ?? "Where to?",
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    final newController = TextEditingController();
                                    final newNode = FocusNode();
                                    _setupFocusListener(newNode);
                                    _pickupControllers.add(newController);
                                    _pickupFocusNodes.add(newNode);
                                    _selectedPickups.add(null);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.surface, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 4, thickness: 1),
              const SizedBox(height: 8),
              SavedLocationsRowWidget(
                loc: widget.loc,
                onLocationSelected: _onHomeWorkTapped,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
