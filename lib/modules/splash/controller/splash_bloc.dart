import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trippy_customer/store/user_data_store.dart';

import '../../../utils/enums.dart';
import '../repository/splash_repository.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final SplashRepository repository;

  SplashBloc({required this.repository})
    : super(SplashState(status: SplashStatus.initial)) {
    on<SplashAuthCheck>(_checkingAuth);
  }

  void _checkingAuth(SplashAuthCheck event, Emitter<SplashState> emit) async {
    emit(SplashState(status: SplashStatus.loading));

    final error = await repository.receivingUserData(
      plaform: event.platform,
      languageCode: event.languageCode,
      actionWhen: event.actionWhen,
      token: UserDataStore.accessToken!,
    );

    if (error == null) {
      emit(SplashState(status: SplashStatus.success));
    } else {
      emit(SplashState(status: SplashStatus.failure, errorMessage: error));
    }
  }
}
