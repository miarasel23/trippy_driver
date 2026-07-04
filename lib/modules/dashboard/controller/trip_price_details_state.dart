import 'package:equatable/equatable.dart';
import '../choose_car_bottom_sheet/model/choose_car_model.dart';
import '../model/trip_price_details_model.dart';

abstract class TripPriceDetailsState extends Equatable {
  const TripPriceDetailsState();

  @override
  List<Object?> get props => [];
}

class TripPriceDetailsInitial extends TripPriceDetailsState {}

class TripPriceDetailsLoading extends TripPriceDetailsState {}

class TripPriceDetailsSuccess extends TripPriceDetailsState {
  final List<Car> finalCars;
  final TripPriceDetailsRequest tripReq;
  final String serviceName;
  final List<String> pickupAddresses;
  final List<String> dropoffAddresses;
  final String? hoursBooked;

  const TripPriceDetailsSuccess({
    required this.finalCars,
    required this.tripReq,
    required this.serviceName,
    required this.pickupAddresses,
    required this.dropoffAddresses,
    this.hoursBooked,
  });

  @override
  List<Object?> get props => [finalCars, tripReq, serviceName, pickupAddresses, dropoffAddresses, hoursBooked];
}

class TripPriceDetailsFailure extends TripPriceDetailsState {
  final String error;

  const TripPriceDetailsFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
