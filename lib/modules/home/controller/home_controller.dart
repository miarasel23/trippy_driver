import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../store/user_data_store.dart';
import '../repository/home_repository.dart';

class HomeState extends Equatable {
  final bool isOnline;
  final String serviceMode;

  const HomeState({
    required this.isOnline,
    required this.serviceMode,
  });

  HomeState copyWith({
    bool? isOnline,
    String? serviceMode,
  }) {
    return HomeState(
      isOnline: isOnline ?? this.isOnline,
      serviceMode: serviceMode ?? this.serviceMode,
    );
  }

  @override
  List<Object?> get props => [isOnline, serviceMode];
}

class HomeController extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeController(this.repository) : super(_getInitialState());

  static HomeState _getInitialState() {
    String status = UserDataStore.userData?.data?.user?.currentRideStatus ?? 'OFFLINE';
    if (status == 'RIDE_SHARE') status = 'RIDE SHARE';
    if (status == 'RENT_A_CAR') status = 'RENT A CAR';
    if (status == 'BOTH') status = 'BOTH';

    return HomeState(
      isOnline: status != 'OFFLINE',
      serviceMode: status == 'OFFLINE' ? 'RIDE SHARE' : status, // Default to 'RIDE SHARE' for UI if offline, or keep 'OFFLINE'
    );
  }

  void toggleOnlineStatus() async {
    final newMode = state.isOnline ? 'OFFLINE' : 'RIDE SHARE';
    await _updateStatusAndEmit(newMode);
  }

  void setServiceMode(String mode) async {
    await _updateStatusAndEmit(mode);
  }

  Future<void> _updateStatusAndEmit(String mode) async {
    final error = await repository.updateRideStatus(status: mode);
    
    if (error == null) {
      // API success, now update UI state (this changes the color)
      emit(state.copyWith(
        serviceMode: mode,
        isOnline: mode != 'OFFLINE',
      ));

      if (UserDataStore.userData?.data?.user != null) {
        String apiStatus = mode;
        if (mode == 'RENT A CAR') apiStatus = 'RENT_A_CAR';
        if (mode == 'RIDE SHARE') apiStatus = 'RIDE_SHARE';
        if (mode == 'BOTH') apiStatus = 'BOTH';

        UserDataStore.userData!.data!.user!.currentRideStatus = apiStatus;
        UserDataStore.saveUserData(UserDataStore.userData!);
      }
    } else {
      // API failed, state remains unchanged. Error snackbar is handled by ApiService.
    }
  }
}

