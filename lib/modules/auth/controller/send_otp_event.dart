import 'package:equatable/equatable.dart';

abstract class SendOtpEvent extends Equatable {
  SendOtpEvent();

  @override
  List<Object> get props => [];
}

class SendOtp extends SendOtpEvent {
  final String number;
  final String languageCode;

  SendOtp(this.number,this.languageCode);

  @override
  List<Object> get props => [number, languageCode];
}
