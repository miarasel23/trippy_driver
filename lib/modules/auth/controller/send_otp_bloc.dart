import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../utils/enums.dart';
import '../repository/send_otp_repository.dart';
import 'send_otp_event.dart';
import 'send_otp_state.dart';

class SendOtpBloc extends Bloc<SendOtpEvent, SendOtpState> {
  final SendOtpRepository repository;
  SendOtpBloc({required this.repository})
    : super(SendOtpState(status: OtpStatus.initial)) {
    on<SendOtp>(_sendingOtp);
  }

  void _sendingOtp(SendOtp event, Emitter<SendOtpState> emit) async {
    emit(SendOtpState.loading());

    final error = await repository.sendingOtp(
      number: event.number,
      languageCode: event.languageCode,
    );

    if (error == null) {
      emit(SendOtpState.success());
    } else {
      emit(SendOtpState.failure(error));
    }
  }
}
