import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../controller/search_location_bloc.dart';
import '../model/search_location_model.dart';
import '../repository/search_location_repository.dart';

class SearchLocationScreen extends StatelessWidget {
  const SearchLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchLocationBloc(SearchLocationRepository()),
      child: const SearchLocationView(),
    );
  }
}

class SearchLocationView extends StatefulWidget {
  const SearchLocationView({super.key});

  @override
  State<SearchLocationView> createState() => _SearchLocationViewState();
}

class _SearchLocationViewState extends State<SearchLocationView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final loc = AppLocalizations.of(context);
    context.read<SearchLocationBloc>().add(
      SearchQueryChanged(query, loc.locale.languageCode)
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate("pick_up_location")),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: loc.translate("where_are_you_going"),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchLocationBloc, SearchLocationState>(
              builder: (context, state) {
                if (state is SearchLocationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SearchLocationFailure) {
                  return Center(child: Text(state.error));
                } else if (state is SearchLocationSuccess) {
                  if (state.locations.isEmpty) {
                    return const Center(child: Text("No locations found"));
                  }
                  return ListView.separated(
                    itemCount: state.locations.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final location = state.locations[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.blue),
                        title: Text(
                          location.address ?? "Unknown",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        onTap: () {
                          // Return the selected location
                          Navigator.pop(context, location);
                        },
                      );
                    },
                  );
                }
                return Center(
                  child: Text(loc.translate("search_location")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
