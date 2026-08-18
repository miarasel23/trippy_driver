import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchMessages extends ChatEvent {
  final String driverUuid;
  final String customerUuid;
  final String receiverType;

  const FetchMessages({
    required this.driverUuid,
    required this.customerUuid,
    this.receiverType = 'CUSTOMER',
  });

  @override
  List<Object?> get props => [driverUuid, customerUuid, receiverType];
}

class SendMessage extends ChatEvent {
  final String driverUuid;
  final String customerUuid;
  final String message;
  final String receiverType;
  final String? filePath;

  const SendMessage({
    required this.driverUuid,
    required this.customerUuid,
    required this.message,
    this.receiverType = 'CUSTOMER',
    this.filePath,
  });

  @override
  List<Object?> get props => [driverUuid, customerUuid, message, receiverType, filePath];
}
