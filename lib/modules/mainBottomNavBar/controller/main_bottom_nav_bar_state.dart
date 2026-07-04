import 'package:equatable/equatable.dart';

class MainBottomNavBarState extends Equatable{
  final int selectedIndex;

  const MainBottomNavBarState({required this.selectedIndex});

  MainBottomNavBarState copyWith({int? selectedIndex}) {
    return MainBottomNavBarState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
  
  @override
  List<Object?> get props => [selectedIndex];
}
