import 'package:equatable/equatable.dart';

abstract class MyTripEvent extends Equatable {
  const MyTripEvent();
  @override
  List<Object> get props => [];
}

class ChangePackageEvent extends MyTripEvent {
  final int index;

  ChangePackageEvent({required this.index});
}

class FetchTripsEvent extends MyTripEvent {
  final String tripStatus;
  final String languageCode;
  final bool isSilent;

  FetchTripsEvent({required this.tripStatus, required this.languageCode, this.isSilent = false});
}
