import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class FetchMessages extends ChatEvent {
  final String driverUuid;
  final String customerUuid;

  const FetchMessages({required this.driverUuid, required this.customerUuid});

  @override
  List<Object?> get props => [driverUuid, customerUuid];
}

class SendMessage extends ChatEvent {
  final String driverUuid;
  final String customerUuid;
  final String message;
  final String? filePath;

  const SendMessage({
    required this.driverUuid,
    required this.customerUuid,
    required this.message,
    this.filePath,
  });

  @override
  List<Object?> get props => [driverUuid, customerUuid, message, filePath];
}
