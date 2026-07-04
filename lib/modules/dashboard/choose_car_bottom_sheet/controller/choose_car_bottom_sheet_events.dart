import 'package:equatable/equatable.dart';

abstract class ChooseCarBottomSheetEvents extends Equatable {
  ChooseCarBottomSheetEvents();

  @override
  List<Object?> get props => [];
}

class ChooseCar extends ChooseCarBottomSheetEvents {
  final String selectedCarIndex;

  ChooseCar({required this.selectedCarIndex});

  @override
  List<Object?> get props => [selectedCarIndex];
}

class LoadServices extends ChooseCarBottomSheetEvents {
  final String languageCode;
  LoadServices({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}
