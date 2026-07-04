
import '../../../utils/enums.dart';

class OtpReceiveState {
  final OtpReceiveStatus status;
  final String? errorMessage;

  OtpReceiveState({required this.status, this.errorMessage});

  factory OtpReceiveState.initial() {
    return OtpReceiveState(status: OtpReceiveStatus.initial);
  }
  
  factory OtpReceiveState.loading() {
    return OtpReceiveState(status: OtpReceiveStatus.loading);
  }
  
  factory OtpReceiveState.success() {
    return OtpReceiveState(status: OtpReceiveStatus.success);
  }
  
  factory OtpReceiveState.failure(String message) {
    return OtpReceiveState(status: OtpReceiveStatus.failure, errorMessage: message);
  }
}
