import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  Timer? _pollingTimer;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<FetchMessages>(_onFetchMessages);
    on<SendMessage>(_onSendMessage);
  }

  void startPolling(String driverUuid, String customerUuid, {String receiverType = 'CUSTOMER'}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(FetchMessages(
        driverUuid: driverUuid,
        customerUuid: customerUuid,
        receiverType: receiverType,
      ));
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _onFetchMessages(FetchMessages event, Emitter<ChatState> emit) async {
    if (state is ChatInitial) {
      emit(ChatLoading());
    }

    try {
      final messages = await repository.fetchConversations(
        driverUuid: event.driverUuid,
        customerUuid: event.customerUuid,
        receiverType: event.receiverType,
      );

      emit(ChatLoaded(messages: messages, isSending: false));
    } catch (e) {
      if (state is! ChatLoaded) {
        emit(const ChatError("Failed to load messages."));
      }
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isSending: true));
    }

    try {
      final success = await repository.sendMessage(
        driverUuid: event.driverUuid,
        customerUuid: event.customerUuid,
        message: event.message,
        receiverType: event.receiverType,
        filePath: event.filePath,
      );

      if (success) {
        final messages = await repository.fetchConversations(
          driverUuid: event.driverUuid,
          customerUuid: event.customerUuid,
          receiverType: event.receiverType,
        );
        emit(ChatLoaded(messages: messages, isSending: false));
      } else {
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(isSending: false));
        }
      }
    } catch (e) {
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(isSending: false));
      }
    }
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
