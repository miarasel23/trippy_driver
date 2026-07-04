import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../utils/enums.dart';
import '../repository/otp_receive_repository.dart';
import 'otp_receive_event.dart';
import 'otp_receive_state.dart';

class OtpReceiveBloc extends Bloc<OtpReceiveEvent, OtpReceiveState> {
  final OtpReceiveRepository repository;

  OtpReceiveBloc({required this.repository})
    : super(OtpReceiveState(status: OtpReceiveStatus.initial)) {
    on<OtpReceive>(_receivingOtp);
  }

  void _receivingOtp(OtpReceive event, Emitter<OtpReceiveState> emit) async {
    emit(OtpReceiveState.loading());

    final error = await repository.receivingOtp(
      otp: event.otp,
      languageCode: event.languageCode,
      number: event.number,
    );

    if (error == null) {
      emit(OtpReceiveState.success());
    } else {
      emit(OtpReceiveState.failure(error));
    }
  }
}
