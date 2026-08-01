import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../model/account_response_model.dart';
import '../model/transaction_model.dart';
import '../repository/account_repository.dart';

// --- Events ---
abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class FetchAccountHistory extends AccountEvent {
  final String filterType;
  const FetchAccountHistory({this.filterType = 'today'});

  @override
  List<Object?> get props => [filterType];
}

class LoadMoreAccountHistory extends AccountEvent {}

// --- State ---
class AccountState extends Equatable {
  final bool isLoading;
  final bool isFetchingMore;
  final AccountResponseModel? accountData;
  final List<TransactionModel> transactions;
  final bool hasReachedMax;
  final String? errorMessage;
  final int currentPage;
  final String filterType;

  const AccountState({
    this.isLoading = false,
    this.isFetchingMore = false,
    this.accountData,
    this.transactions = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.currentPage = 1,
    this.filterType = 'today',
  });

  AccountState copyWith({
    bool? isLoading,
    bool? isFetchingMore,
    AccountResponseModel? accountData,
    List<TransactionModel>? transactions,
    bool? hasReachedMax,
    String? errorMessage,
    int? currentPage,
    String? filterType,
  }) {
    return AccountState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      accountData: accountData ?? this.accountData,
      transactions: transactions ?? this.transactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      filterType: filterType ?? this.filterType,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isFetchingMore,
        accountData,
        transactions,
        hasReachedMax,
        errorMessage,
        currentPage,
        filterType,
      ];
}

// --- Bloc ---
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository repository;

  AccountBloc({required this.repository}) : super(const AccountState()) {
    on<FetchAccountHistory>(_onFetchAccountHistory);
    on<LoadMoreAccountHistory>(_onLoadMoreAccountHistory);
  }

  Future<void> _onFetchAccountHistory(
      FetchAccountHistory event, Emitter<AccountState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null, filterType: event.filterType));

    try {
      final response = await repository.getAccountHistory(
        page: 1, 
        filterType: event.filterType
      );
      if (response != null) {
        emit(state.copyWith(
          isLoading: false,
          accountData: response,
          transactions: response.transactions,
          currentPage: 1,
          hasReachedMax: response.transactions.isEmpty,
        ));
      } else {
        emit(state.copyWith(
            isLoading: false, errorMessage: "Failed to fetch data"));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMoreAccountHistory(
      LoadMoreAccountHistory event, Emitter<AccountState> emit) async {
    if (state.hasReachedMax || state.isFetchingMore || state.isLoading) return;

    emit(state.copyWith(isFetchingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await repository.getAccountHistory(
        page: nextPage,
        filterType: state.filterType,
      );
      
      if (response != null) {
        if (response.transactions.isEmpty) {
          emit(state.copyWith(isFetchingMore: false, hasReachedMax: true));
        } else {
          emit(state.copyWith(
            isFetchingMore: false,
            currentPage: nextPage,
            transactions: List.of(state.transactions)..addAll(response.transactions),
            // Update accountData balance info just in case
            accountData: response, 
          ));
        }
      } else {
        emit(state.copyWith(isFetchingMore: false));
      }
    } catch (e) {
      emit(state.copyWith(isFetchingMore: false));
    }
  }
}
