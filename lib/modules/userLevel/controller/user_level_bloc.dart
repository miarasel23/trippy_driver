import 'package:flutter_bloc/flutter_bloc.dart';

import 'faq_event.dart';
import 'user_level_state.dart';

class UserLevelBloc extends Bloc<FaqEvent, UserLevelState> {
  UserLevelBloc() : super(UserLevelState(expandedFaqIndex: -1)) {
    on<ToggleFaqEvent>(_togglingFaq);
  }

  void _togglingFaq(ToggleFaqEvent event, Emitter<UserLevelState> emit) {
    final current = state.expandedFaqIndex;
    emit(
      state.copyWith(
        expandedFaqIndex: current == event.index ? -1 : event.index,
      ),
    );
  }
}
