import 'package:equatable/equatable.dart';

abstract class PointsEvent extends Equatable {
  const PointsEvent();
  @override
  List<Object> get props => [];
}

class ChangeScreenEvent extends PointsEvent {
  final int index;

  ChangeScreenEvent(this.index);
}
