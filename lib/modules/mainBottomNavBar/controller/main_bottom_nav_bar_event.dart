import 'package:equatable/equatable.dart';

abstract class MainBottomNavEvent extends Equatable {
  const MainBottomNavEvent();
  @override
  List<Object> get props => [];
}

class ChangeTabEvent extends MainBottomNavEvent {
  final int index;

  ChangeTabEvent(this.index);
}
