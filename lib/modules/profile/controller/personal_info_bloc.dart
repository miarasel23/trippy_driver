import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/personal_info_repository.dart';

// --- Events ---
abstract class PersonalInfoEvent extends Equatable {
  const PersonalInfoEvent();

  @override
  List<Object?> get props => [];
}

class FetchPersonalInfoDocuments extends PersonalInfoEvent {}

class UpdateProfileName extends PersonalInfoEvent {
  final String fullName;
  const UpdateProfileName(this.fullName);

  @override
  List<Object?> get props => [fullName];
}

// --- State ---
enum ProfileUpdateStatus { initial, loading, success, failure }

class PersonalInfoState extends Equatable {
  final bool isLoading;
  final List<dynamic> documents;
  final String? errorMessage;
  final ProfileUpdateStatus updateStatus;
  final String? updateMessage;

  const PersonalInfoState({
    this.isLoading = false,
    this.documents = const [],
    this.errorMessage,
    this.updateStatus = ProfileUpdateStatus.initial,
    this.updateMessage,
  });

  PersonalInfoState copyWith({
    bool? isLoading,
    List<dynamic>? documents,
    String? errorMessage,
    ProfileUpdateStatus? updateStatus,
    String? updateMessage,
  }) {
    return PersonalInfoState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      errorMessage: errorMessage ?? this.errorMessage,
      updateStatus: updateStatus ?? this.updateStatus,
      updateMessage: updateMessage ?? this.updateMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, documents, errorMessage, updateStatus, updateMessage];
}

// --- Bloc ---
class PersonalInfoBloc extends Bloc<PersonalInfoEvent, PersonalInfoState> {
  final PersonalInfoRepository repository;

  PersonalInfoBloc({required this.repository}) : super(const PersonalInfoState()) {
    on<FetchPersonalInfoDocuments>(_onFetchPersonalInfoDocuments);
    on<UpdateProfileName>(_onUpdateProfileName);
  }

  Future<void> _onFetchPersonalInfoDocuments(
      FetchPersonalInfoDocuments event, Emitter<PersonalInfoState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await repository.getDriverDocumentList();
      if (response != null) {
        final filteredDocs = response.where((doc) {
          final number = doc['document_number'];
          final isNumberNotNull = number != null &&
              number.toString().trim().isNotEmpty &&
              number.toString().toLowerCase() != 'null';
          return isNumberNotNull;
        }).toList();

        emit(state.copyWith(
          isLoading: false,
          documents: filteredDocs,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load documents list from server.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateProfileName(
      UpdateProfileName event, Emitter<PersonalInfoState> emit) async {
    emit(state.copyWith(updateStatus: ProfileUpdateStatus.loading, updateMessage: null));

    try {
      final success = await repository.updateProfileName(fullName: event.fullName);
      if (success) {
        emit(state.copyWith(
          updateStatus: ProfileUpdateStatus.success,
          updateMessage: 'Profile updated successfully',
        ));
      } else {
        emit(state.copyWith(
          updateStatus: ProfileUpdateStatus.failure,
          updateMessage: 'Failed to update profile name.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        updateStatus: ProfileUpdateStatus.failure,
        updateMessage: e.toString(),
      ));
    }
  }
}
