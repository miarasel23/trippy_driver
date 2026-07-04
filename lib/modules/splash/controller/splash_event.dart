import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {
  SplashEvent();

  @override
  List<Object> get props => [];
}

class SplashAuthCheck extends SplashEvent {
  final String platform;
  final String languageCode;
  final String actionWhen;

  SplashAuthCheck({
    required this.platform,
    required this.languageCode,
    required this.actionWhen
  });

  @override
  List<Object> get props => [
    platform,
    languageCode,
    actionWhen
  ];
}
