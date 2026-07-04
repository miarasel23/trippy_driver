import 'package:equatable/equatable.dart';

class UserLevelState extends Equatable {
  final int expandedFaqIndex;

  UserLevelState({this.expandedFaqIndex = -1});

  UserLevelState copyWith({int? expandedFaqIndex}) {
    return UserLevelState(
      expandedFaqIndex: expandedFaqIndex ?? this.expandedFaqIndex,
    );
  }

  @override
  List<Object?> get props => [expandedFaqIndex];
}
