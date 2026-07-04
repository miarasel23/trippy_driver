import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../utils/enums.dart';

class EditProfileUpdateState extends Equatable {
  final EditProfileUpdateStatus status;
  final File? avatar;
  final String? platform;
  final String? languageCode;
  final String? actionWhen;
  final String? uuid;
  final String? errorMessage;

  EditProfileUpdateState({
    this.avatar,
    this.status = EditProfileUpdateStatus.initial,
    this.actionWhen,
    this.languageCode,
    this.platform,
    this.uuid,
    this.errorMessage,
  });

  EditProfileUpdateState copyWith({
    EditProfileUpdateStatus? status,
    String? platform,
    String? languageCode,
    String? actionWhen,
    File? avatar,
    String? uuid,
    String? errorMessage,
  }) {
    return EditProfileUpdateState(
      status: status ?? this.status,
      platform: platform ?? this.platform,
      languageCode: languageCode ?? this.languageCode,
      actionWhen: actionWhen ?? this.actionWhen,
      avatar: avatar ?? this.avatar,
      uuid: uuid ?? this.uuid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    platform,
    languageCode,
    actionWhen,
    avatar,
    uuid,
    errorMessage
  ];
}
