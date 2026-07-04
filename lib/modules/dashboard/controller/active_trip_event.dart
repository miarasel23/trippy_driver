import '../model/create_rental_trip_model.dart';

abstract class ActiveTripEvent {}

class FetchActiveTrip extends ActiveTripEvent {
  final String customerUuid;
  final String languageCode;
  FetchActiveTrip({required this.customerUuid, required this.languageCode});
}

class StartActiveTripPolling extends ActiveTripEvent {
  final String customerUuid;
  final String languageCode;
  StartActiveTripPolling({required this.customerUuid, required this.languageCode});
}

class StopActiveTripPolling extends ActiveTripEvent {}

class UpdateActiveTripLocalReview extends ActiveTripEvent {
  final RentalTrip updatedTrip;
  UpdateActiveTripLocalReview(this.updatedTrip);
}

class CancelActiveTrip extends ActiveTripEvent {
  final String tripUuid;
  final String comment;
  final String languageCode;
  CancelActiveTrip({required this.tripUuid, required this.comment, required this.languageCode});
}
