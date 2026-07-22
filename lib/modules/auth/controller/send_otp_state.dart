import 'package:trippy_rider/utils/enums.dart';

class SendOtpState {
  final OtpStatus status;
  final String? errorMessage;

  SendOtpState({required this.status, this.errorMessage});

  factory SendOtpState.initial() {
    return SendOtpState(status: OtpStatus.initial);
  }

  factory SendOtpState.loading() {
    return SendOtpState(status: OtpStatus.loading);
  }

  factory SendOtpState.success() {
    return SendOtpState(status: OtpStatus.success);
  }

  factory SendOtpState.failure(String message) {
    return SendOtpState(status: OtpStatus.failure, errorMessage: message);
  }
}
