import 'package:equatable/equatable.dart';

abstract class FaqEvent extends Equatable {
  FaqEvent();

  @override
  List<Object> get props => [];
}

class ToggleFaqEvent extends FaqEvent {
  final int index;

  ToggleFaqEvent(this.index);

  @override
  List<Object> get props => [index];
}
