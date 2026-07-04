import 'package:equatable/equatable.dart';

abstract class OtpReceiveEvent extends Equatable {
  OtpReceiveEvent();

  @override
  List<Object> get props => [];
}

class OtpReceive extends OtpReceiveEvent {
  final String number;
  final String otp;
  final String languageCode;

  OtpReceive({
    required this.number,
    required this.otp,
    required this.languageCode,
  });

  @override
  List<Object> get props => [number, otp, languageCode];
}
