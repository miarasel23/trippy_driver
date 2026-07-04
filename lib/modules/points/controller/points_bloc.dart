import 'package:flutter_bloc/flutter_bloc.dart';

import 'points_event.dart';
import 'points_state.dart';

class PointsBloc extends Bloc<PointsEvent, PointsState> {
  PointsBloc() : super(PointsState(selectedIndex: 0)) {
    on<ChangeScreenEvent>(_changingScreen);
  }

  void _changingScreen(ChangeScreenEvent event, Emitter<PointsState> emit) {
    emit(state.copyWith(selectedIndex: event.index));
  }
}
