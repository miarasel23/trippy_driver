import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_bottom_nav_bar_event.dart';
import 'main_bottom_nav_bar_state.dart';

class MainBottomNavBarBloc
    extends Bloc<MainBottomNavEvent, MainBottomNavBarState> {
  MainBottomNavBarBloc()
    : super(const MainBottomNavBarState(selectedIndex: 2)) {
    on<ChangeTabEvent>(_changingTab);
  }

  void _changingTab(ChangeTabEvent event, Emitter<MainBottomNavBarState> emit) {
    emit(state.copyWith(selectedIndex: event.index));
  }
}
