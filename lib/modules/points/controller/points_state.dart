import 'package:equatable/equatable.dart';

class PointsState extends Equatable {
  final int selectedIndex;

  PointsState({required this.selectedIndex});

  PointsState copyWith({int? selectedIndex}) {
    return PointsState(selectedIndex: selectedIndex ?? this.selectedIndex);
  }

  @override
  List<Object?> get props => [selectedIndex];
}
