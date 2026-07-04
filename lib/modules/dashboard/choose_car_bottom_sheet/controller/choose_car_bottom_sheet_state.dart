import 'package:equatable/equatable.dart';

import '../../../../utils/enums.dart';
import '../model/choose_car_model.dart';

class ChooseCarBottomSheetState extends Equatable {
  final String? currentCarIndex;
  final bool? clicked;
  final ChooseCarBottomSheetStatus? status;
  final Map<String, ServiceGroup>? groups;
  final String? error;

  ChooseCarBottomSheetState({
    this.error,
    this.currentCarIndex,
    this.clicked,
    this.status = ChooseCarBottomSheetStatus.initial,
    this.groups,
  });

  ChooseCarBottomSheetState copyWith({
    String? selectedCarIndex,
    bool? clicked,
    ChooseCarBottomSheetStatus? status,
    Map<String, ServiceGroup>? groups,
    final String? error,
  }) {
    return ChooseCarBottomSheetState(
      currentCarIndex: selectedCarIndex ?? currentCarIndex,
      clicked: clicked ?? this.clicked,
      status: status ?? this.status,
      groups: groups ?? this.groups,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [currentCarIndex, clicked, status, groups, error];
}
