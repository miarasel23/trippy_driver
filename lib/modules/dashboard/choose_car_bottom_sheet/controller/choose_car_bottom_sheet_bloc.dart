import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../utils/enums.dart';

import '../repository/choose_car_bottom_sheet_repository.dart';
import 'choose_car_bottom_sheet_events.dart';
import 'choose_car_bottom_sheet_state.dart';

class ChooseCarBottomSheetBloc
    extends Bloc<ChooseCarBottomSheetEvents, ChooseCarBottomSheetState> {
  final ChooseCarBottomSheetRepository repository;
  ChooseCarBottomSheetBloc({required this.repository})
    : super(ChooseCarBottomSheetState(clicked: false)) {
    on<ChooseCar>(_choosingCar);
    on<LoadServices>(_fetchingRides);
  }

  void _choosingCar(
    ChooseCar event,
    Emitter<ChooseCarBottomSheetState> emit,
  ) async {
    emit(
      state.copyWith(selectedCarIndex: event.selectedCarIndex, clicked: true),
    );
  }

  void _fetchingRides(
    LoadServices event,
    Emitter<ChooseCarBottomSheetState> emit,
  ) async {
    emit(state.copyWith(status: ChooseCarBottomSheetStatus.loading));

    try {
      final response = await repository.receivingCarList(
        languageCode: event.languageCode,
      );

      emit(
        state.copyWith(status: ChooseCarBottomSheetStatus.success, groups: response?.groups),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ChooseCarBottomSheetStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
