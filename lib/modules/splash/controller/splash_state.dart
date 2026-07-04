import 'package:equatable/equatable.dart';

import '../../../utils/enums.dart';
class SplashState extends Equatable {
  final SplashStatus status;

  final String? platform;
  final String? languageCode;
  final String? actionWhen;

  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.platform,
    this.languageCode,
    this.actionWhen,
    this.errorMessage,
  });

  SplashState copyWith({
    SplashStatus? status,
    String? platform,
    String? languageCode,
    String? actionWhen,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      platform: platform ?? this.platform,
      languageCode: languageCode ?? this.languageCode,
      actionWhen: actionWhen ?? this.actionWhen,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        platform,
        languageCode,
        actionWhen,
        errorMessage
      ];
}