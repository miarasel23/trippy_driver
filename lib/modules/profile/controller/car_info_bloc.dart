import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/car_info_repository.dart';

// --- Events ---
abstract class CarInfoEvent extends Equatable {
  const CarInfoEvent();

  @override
  List<Object?> get props => [];
}

class FetchCarDocuments extends CarInfoEvent {}

class UploadCarDocument extends CarInfoEvent {
  final String imagePath;
  final String documentType;
  final String documentNumber;

  const UploadCarDocument({
    required this.imagePath,
    required this.documentType,
    required this.documentNumber,
  });

  @override
  List<Object?> get props => [imagePath, documentType, documentNumber];
}

class UploadAllCarDocuments extends CarInfoEvent {
  final File smartCardFile;
  final String registrationNumber;
  final File taxFrontFile;
  final File taxBackFile;
  final File fitnessFrontFile;
  final File fitnessBackFile;

  const UploadAllCarDocuments({
    required this.smartCardFile,
    required this.registrationNumber,
    required this.taxFrontFile,
    required this.taxBackFile,
    required this.fitnessFrontFile,
    required this.fitnessBackFile,
  });

  @override
  List<Object?> get props => [
        smartCardFile,
        registrationNumber,
        taxFrontFile,
        taxBackFile,
        fitnessFrontFile,
        fitnessBackFile,
      ];
}

// --- State ---
enum CarDocumentUploadStatus { initial, loading, success, failure }

class CarInfoState extends Equatable {
  final bool isLoading;
  final List<dynamic> documents;
  final String? errorMessage;
  final CarDocumentUploadStatus uploadStatus;
  final String? uploadMessage;

  const CarInfoState({
    this.isLoading = false,
    this.documents = const [],
    this.errorMessage,
    this.uploadStatus = CarDocumentUploadStatus.initial,
    this.uploadMessage,
  });

  CarInfoState copyWith({
    bool? isLoading,
    List<dynamic>? documents,
    String? errorMessage,
    CarDocumentUploadStatus? uploadStatus,
    String? uploadMessage,
  }) {
    return CarInfoState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadMessage: uploadMessage ?? this.uploadMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        documents,
        errorMessage,
        uploadStatus,
        uploadMessage,
      ];
}

// --- Bloc ---
class CarInfoBloc extends Bloc<CarInfoEvent, CarInfoState> {
  final CarInfoRepository repository;

  CarInfoBloc({required this.repository}) : super(const CarInfoState()) {
    on<FetchCarDocuments>(_onFetchCarDocuments);
    on<UploadCarDocument>(_onUploadCarDocument);
    on<UploadAllCarDocuments>(_onUploadAllCarDocuments);
  }

  Future<void> _onFetchCarDocuments(
      FetchCarDocuments event, Emitter<CarInfoState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await repository.getCarDocumentList();
      if (response != null) {
        // Keep ONLY vehicle document types
        final allowedTypes = [
          'VEHICLE_REGISTRATION_SMART_CARD_COPY',
          'VEHICLE_TAX_FONT_COPY',
          'VEHICLE_TAX_FRONT_COPY',
          'VEHICLE_TAX_BACK_COPY',
          'VEHICLE_FITNESS_CERTIFICATE_FONT_COPY',
          'VEHICLE_FITNESS_CERTIFICATE_FRONT_COPY',
          'VEHICLE_FITNESS_CERTIFICATE_BACK_COPY',
        ];

        final filteredDocs = response.where((doc) {
          final type = doc['document_type'] ?? '';
          return allowedTypes.contains(type);
        }).toList();

        emit(state.copyWith(
          isLoading: false,
          documents: filteredDocs,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load car documents list from server.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUploadCarDocument(
      UploadCarDocument event, Emitter<CarInfoState> emit) async {
    emit(state.copyWith(uploadStatus: CarDocumentUploadStatus.loading, uploadMessage: null));

    try {
      final file = File(event.imagePath);
      final success = await repository.uploadCarDocument(
        imageFile: file,
        documentType: event.documentType,
        documentNumber: event.documentNumber,
      );

      if (success) {
        emit(state.copyWith(
          uploadStatus: CarDocumentUploadStatus.success,
          uploadMessage: 'Car document uploaded successfully',
        ));
        add(FetchCarDocuments());
      } else {
        emit(state.copyWith(
          uploadStatus: CarDocumentUploadStatus.failure,
          uploadMessage: 'Failed to upload document image to server.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: CarDocumentUploadStatus.failure,
        uploadMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadAllCarDocuments(
      UploadAllCarDocuments event, Emitter<CarInfoState> emit) async {
    emit(state.copyWith(uploadStatus: CarDocumentUploadStatus.loading, uploadMessage: null));

    try {
      final success = await repository.uploadAllCarDocuments(
        smartCardFile: event.smartCardFile,
        registrationNumber: event.registrationNumber,
        taxFrontFile: event.taxFrontFile,
        taxBackFile: event.taxBackFile,
        fitnessFrontFile: event.fitnessFrontFile,
        fitnessBackFile: event.fitnessBackFile,
      );

      if (success) {
        emit(state.copyWith(
          uploadStatus: CarDocumentUploadStatus.success,
          uploadMessage: 'All car documents uploaded successfully',
        ));
        add(FetchCarDocuments());
      } else {
        emit(state.copyWith(
          uploadStatus: CarDocumentUploadStatus.failure,
          uploadMessage: 'Failed to upload all car documents.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: CarDocumentUploadStatus.failure,
        uploadMessage: e.toString(),
      ));
    }
  }
}
