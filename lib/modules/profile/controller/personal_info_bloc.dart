import 'dart:io';
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

class UploadDriverDocument extends PersonalInfoEvent {
  final String imagePath;
  final String documentType;
  final String documentNumber;

  const UploadDriverDocument({
    required this.imagePath,
    required this.documentType,
    required this.documentNumber,
  });

  @override
  List<Object?> get props => [imagePath, documentType, documentNumber];
}

// --- State ---
enum ProfileUpdateStatus { initial, loading, success, failure }
enum DocumentUploadStatus { initial, loading, success, failure }

class PersonalInfoState extends Equatable {
  final bool isLoading;
  final List<dynamic> documents;
  final String? errorMessage;
  final ProfileUpdateStatus updateStatus;
  final String? updateMessage;
  final DocumentUploadStatus uploadStatus;
  final String? uploadMessage;

  const PersonalInfoState({
    this.isLoading = false,
    this.documents = const [],
    this.errorMessage,
    this.updateStatus = ProfileUpdateStatus.initial,
    this.updateMessage,
    this.uploadStatus = DocumentUploadStatus.initial,
    this.uploadMessage,
  });

  PersonalInfoState copyWith({
    bool? isLoading,
    List<dynamic>? documents,
    String? errorMessage,
    ProfileUpdateStatus? updateStatus,
    String? updateMessage,
    DocumentUploadStatus? uploadStatus,
    String? uploadMessage,
  }) {
    return PersonalInfoState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      errorMessage: errorMessage ?? this.errorMessage,
      updateStatus: updateStatus ?? this.updateStatus,
      updateMessage: updateMessage ?? this.updateMessage,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadMessage: uploadMessage ?? this.uploadMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        documents,
        errorMessage,
        updateStatus,
        updateMessage,
        uploadStatus,
        uploadMessage,
      ];
}

// --- Bloc ---
class PersonalInfoBloc extends Bloc<PersonalInfoEvent, PersonalInfoState> {
  final PersonalInfoRepository repository;

  PersonalInfoBloc({required this.repository}) : super(const PersonalInfoState()) {
    on<FetchPersonalInfoDocuments>(_onFetchPersonalInfoDocuments);
    on<UpdateProfileName>(_onUpdateProfileName);
    on<UploadDriverDocument>(_onUploadDriverDocument);
  }

  Future<void> _onFetchPersonalInfoDocuments(
      FetchPersonalInfoDocuments event, Emitter<PersonalInfoState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await repository.getDriverDocumentList();
      if (response != null) {
        final filteredDocs = response.where((doc) {
          final type = doc['document_type'];
          final number = doc['document_number'];
          final isNumberNotNull = number != null &&
              number.toString().trim().isNotEmpty &&
              number.toString().toLowerCase() != 'null';
          
          final typeStr = type?.toString().toUpperCase() ?? '';
          final isVehicleSmartCard = typeStr.contains('VEHICLE_REGISTRATION_SMART_CARD_COPY') || 
                                     typeStr.contains('SMART_CARD');

          return isNumberNotNull && !isVehicleSmartCard;
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

  Future<void> _onUploadDriverDocument(
      UploadDriverDocument event, Emitter<PersonalInfoState> emit) async {
    emit(state.copyWith(uploadStatus: DocumentUploadStatus.loading, uploadMessage: null));

    try {
      final file = File(event.imagePath);
      final success = await repository.uploadDriverDocument(
        imageFile: file,
        documentType: event.documentType,
        documentNumber: event.documentNumber,
      );

      if (success) {
        emit(state.copyWith(
          uploadStatus: DocumentUploadStatus.success,
          uploadMessage: 'Document uploaded successfully',
        ));
        add(FetchPersonalInfoDocuments());
      } else {
        emit(state.copyWith(
          uploadStatus: DocumentUploadStatus.failure,
          uploadMessage: 'Failed to upload document image to server.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: DocumentUploadStatus.failure,
        uploadMessage: e.toString(),
      ));
    }
  }
}
