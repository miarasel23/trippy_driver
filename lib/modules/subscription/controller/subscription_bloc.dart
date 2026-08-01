import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../model/subscription_package_model.dart';
import '../repository/subscription_repository.dart';

// --- Events ---
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class FetchSubscriptionPackages extends SubscriptionEvent {}

// --- States ---
class SubscriptionState extends Equatable {
  final bool isLoading;
  final List<SubscriptionPackageModel> packages;
  final String? errorMessage;

  const SubscriptionState({
    this.isLoading = false,
    this.packages = const [],
    this.errorMessage,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    List<SubscriptionPackageModel>? packages,
    String? errorMessage,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      packages: packages ?? this.packages,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, packages, errorMessage];
}

// --- Bloc ---
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository repository;

  SubscriptionBloc({required this.repository}) : super(const SubscriptionState()) {
    on<FetchSubscriptionPackages>(_onFetchSubscriptionPackages);
  }

  Future<void> _onFetchSubscriptionPackages(
      FetchSubscriptionPackages event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final packages = await repository.getSubscriptionPackages();
      if (packages != null) {
        emit(state.copyWith(isLoading: false, packages: packages));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load packages'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'An error occurred'));
    }
  }
}
