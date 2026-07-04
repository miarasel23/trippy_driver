import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/search_location_model.dart';
import '../repository/search_location_repository.dart';

abstract class SearchLocationEvent {}

class SearchQueryChanged extends SearchLocationEvent {
  final String query;
  final String languageCode;
  SearchQueryChanged(this.query, this.languageCode);
}

class SelectLocation extends SearchLocationEvent {
  final SearchLocationData location;
  SelectLocation(this.location);
}

abstract class SearchLocationState {}

class SearchLocationInitial extends SearchLocationState {}

class SearchLocationLoading extends SearchLocationState {}

class SearchLocationSuccess extends SearchLocationState {
  final List<SearchLocationData> locations;
  SearchLocationSuccess(this.locations);
}

class SearchLocationFailure extends SearchLocationState {
  final String error;
  SearchLocationFailure(this.error);
}

class SearchLocationBloc extends Bloc<SearchLocationEvent, SearchLocationState> {
  final SearchLocationRepository repository;
  Timer? _debounce;

  SearchLocationBloc(this.repository) : super(SearchLocationInitial()) {
    on<SearchQueryChanged>((event, emit) async {
      if (event.query.isEmpty) {
        _debounce?.cancel();
        emit(SearchLocationInitial());
        return;
      }

      // Cancel any previous debounce timer so rapid keystrokes don't each fire a request
      _debounce?.cancel();

      // Pause 400ms before actually searching; if the user types again in that time,
      // this timer is cancelled and rescheduled.
      final completer = Completer<void>();
      _debounce = Timer(const Duration(milliseconds: 400), completer.complete);
      await completer.future;

      if (isClosed) return;

      emit(SearchLocationLoading());
      try {
        final response = await repository.searchLocations(event.query, event.languageCode);
        emit(SearchLocationSuccess(response.data ?? []));
      } catch (e) {
        emit(SearchLocationFailure(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
