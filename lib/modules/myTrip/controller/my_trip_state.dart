import 'package:equatable/equatable.dart';
import '../../dashboard/model/create_rental_trip_model.dart';

class MyTripState extends Equatable {
  final int selectedIndex;
  final bool isLoading;
  final List<RentalTrip> requestedTrips;
  final List<RentalTrip> acceptedTrips;
  final List<RentalTrip> historyTrips;
  final String errorMessage;

  MyTripState({
    required this.selectedIndex,
    this.isLoading = false,
    this.requestedTrips = const [],
    this.acceptedTrips = const [],
    this.historyTrips = const [],
    this.errorMessage = '',
  });

  MyTripState copyWith({
    int? selectedIndex,
    bool? isLoading,
    List<RentalTrip>? requestedTrips,
    List<RentalTrip>? acceptedTrips,
    List<RentalTrip>? historyTrips,
    String? errorMessage,
  }) {
    return MyTripState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isLoading: isLoading ?? this.isLoading,
      requestedTrips: requestedTrips ?? this.requestedTrips,
      acceptedTrips: acceptedTrips ?? this.acceptedTrips,
      historyTrips: historyTrips ?? this.historyTrips,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, isLoading, requestedTrips, acceptedTrips, historyTrips, errorMessage];
}
