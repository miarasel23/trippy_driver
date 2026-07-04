import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/trip_price_details_repository.dart';
import 'trip_price_details_event.dart';
import 'trip_price_details_state.dart';
import '../choose_car_bottom_sheet/model/choose_car_model.dart';

class TripPriceDetailsBloc extends Bloc<TripPriceDetailsEvent, TripPriceDetailsState> {
  final TripPriceDetailsRepository repository;

  TripPriceDetailsBloc({required this.repository}) : super(TripPriceDetailsInitial()) {
    on<FetchTripPriceDetails>(_onFetchTripPriceDetails);
  }

  Future<void> _onFetchTripPriceDetails(
    FetchTripPriceDetails event,
    Emitter<TripPriceDetailsState> emit,
  ) async {
    emit(TripPriceDetailsLoading());

    try {
      final response = await repository.getTripPriceDetails(event.request);

      if (response.status == true) {
        List<Car> finalCars = event.defaultCars;

        try {
          if (response.data != null && response.data is Map) {
            final Map<String, dynamic> dataMap = response.data;
            if (dataMap.containsKey(event.serviceKey)) {
              final serviceGroup = dataMap[event.serviceKey];
              if (serviceGroup != null && serviceGroup['cars'] is List) {
                final parsedCars = (serviceGroup['cars'] as List)
                    .map((e) => Car.fromJson(e))
                    .toList();
                if (parsedCars.isNotEmpty) {
                  finalCars = parsedCars;
                }
              }
            }
          }
        } catch (_) {
          // Silent parsing errors
        }

        emit(TripPriceDetailsSuccess(
          finalCars: finalCars,
          tripReq: event.request,
          serviceName: event.serviceKey,
          pickupAddresses: event.pickupAddresses,
          dropoffAddresses: event.dropoffAddresses,
          hoursBooked: event.hoursBooked,
        ));
      } else {
        emit(TripPriceDetailsFailure(
          error: response.message ?? 'Failed to get trip price details',
        ));
      }
    } catch (e) {
      emit(TripPriceDetailsFailure(
        error: e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', ''),
      ));
    }
  }
}
