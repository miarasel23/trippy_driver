import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/car_photo_repository.dart';

// --- Events ---
abstract class CarPhotoEvent extends Equatable {
  const CarPhotoEvent();

  @override
  List<Object?> get props => [];
}

class FetchCarPhotos extends CarPhotoEvent {}

class FetchCarCategories extends CarPhotoEvent {}

class UploadCarPhotoSingle extends CarPhotoEvent {
  final String imagePath;
  final String documentType;
  final String carCategoriesUuid;

  const UploadCarPhotoSingle({
    required this.imagePath,
    required this.documentType,
    required this.carCategoriesUuid,
  });

  @override
  List<Object?> get props => [imagePath, documentType, carCategoriesUuid];
}

class UploadAllCarPhotos extends CarPhotoEvent {
  final File frontFile;
  final File backFile;
  final File leftFile;
  final File rightFile;
  final File carSetFile;
  final String carCategoriesUuid;

  const UploadAllCarPhotos({
    required this.frontFile,
    required this.backFile,
    required this.leftFile,
    required this.rightFile,
    required this.carSetFile,
    required this.carCategoriesUuid,
  });

  @override
  List<Object?> get props => [
        frontFile,
        backFile,
        leftFile,
        rightFile,
        carSetFile,
        carCategoriesUuid,
      ];
}

// --- State ---
enum CarPhotoUploadStatus { initial, loading, success, failure }

class CarPhotoState extends Equatable {
  final bool isLoading;
  final bool isCategoriesLoading;
  final Map<String, dynamic>? carCategoryInfo;
  final List<dynamic> photos;
  final List<dynamic> categories;
  final String? errorMessage;
  final CarPhotoUploadStatus uploadStatus;
  final String? uploadMessage;

  const CarPhotoState({
    this.isLoading = false,
    this.isCategoriesLoading = false,
    this.carCategoryInfo,
    this.photos = const [],
    this.categories = const [],
    this.errorMessage,
    this.uploadStatus = CarPhotoUploadStatus.initial,
    this.uploadMessage,
  });

  CarPhotoState copyWith({
    bool? isLoading,
    bool? isCategoriesLoading,
    Map<String, dynamic>? carCategoryInfo,
    List<dynamic>? photos,
    List<dynamic>? categories,
    String? errorMessage,
    CarPhotoUploadStatus? uploadStatus,
    String? uploadMessage,
  }) {
    return CarPhotoState(
      isLoading: isLoading ?? this.isLoading,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      carCategoryInfo: carCategoryInfo ?? this.carCategoryInfo,
      photos: photos ?? this.photos,
      categories: categories ?? this.categories,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadMessage: uploadMessage ?? this.uploadMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCategoriesLoading,
        carCategoryInfo,
        photos,
        categories,
        errorMessage,
        uploadStatus,
        uploadMessage,
      ];
}

// --- Bloc ---
class CarPhotoBloc extends Bloc<CarPhotoEvent, CarPhotoState> {
  final CarPhotoRepository repository;

  CarPhotoBloc({required this.repository}) : super(const CarPhotoState()) {
    on<FetchCarPhotos>(_onFetchCarPhotos);
    on<FetchCarCategories>(_onFetchCarCategories);
    on<UploadCarPhotoSingle>(_onUploadCarPhotoSingle);
    on<UploadAllCarPhotos>(_onUploadAllCarPhotos);
  }

  Future<void> _onFetchCarPhotos(
      FetchCarPhotos event, Emitter<CarPhotoState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await repository.getCarPhotoList();
      if (response != null) {
        emit(state.copyWith(
          isLoading: false,
          carCategoryInfo: response['car_category_info'],
          photos: response['data'] as List<dynamic>? ?? [],
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load car setup and photo list from server.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Connection error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFetchCarCategories(
      FetchCarCategories event, Emitter<CarPhotoState> emit) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      final list = await repository.getCarCategoryList();
      if (list != null) {
        // Filter dropdown to only ACTIVE categories and exclude PREMIUM categories
        final filteredList = list.where((cat) {
          final status = cat['status'] ?? '';
          final type = cat['car_type']?.toString().toUpperCase() ?? '';
          final isActive = status == 'ACTIVE';
          final isPremium = type.contains('PREMIUM');
          return isActive && !isPremium;
        }).toList();
        emit(state.copyWith(
          isCategoriesLoading: false,
          categories: filteredList,
        ));
      } else {
        emit(state.copyWith(isCategoriesLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isCategoriesLoading: false));
    }
  }

  Future<void> _onUploadCarPhotoSingle(
      UploadCarPhotoSingle event, Emitter<CarPhotoState> emit) async {
    emit(state.copyWith(uploadStatus: CarPhotoUploadStatus.loading, uploadMessage: null));

    try {
      final file = File(event.imagePath);
      final success = await repository.uploadCarPhoto(
        imageFile: file,
        documentType: event.documentType,
        carCategoriesUuid: event.carCategoriesUuid,
      );

      if (success) {
        emit(state.copyWith(
          uploadStatus: CarPhotoUploadStatus.success,
          uploadMessage: 'Car photo uploaded successfully',
        ));
        add(FetchCarPhotos());
      } else {
        emit(state.copyWith(
          uploadStatus: CarPhotoUploadStatus.failure,
          uploadMessage: 'Failed to upload photo image to server.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: CarPhotoUploadStatus.failure,
        uploadMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadAllCarPhotos(
      UploadAllCarPhotos event, Emitter<CarPhotoState> emit) async {
    emit(state.copyWith(uploadStatus: CarPhotoUploadStatus.loading, uploadMessage: null));

    try {
      final success = await repository.uploadAllCarPhotos(
        frontFile: event.frontFile,
        backFile: event.backFile,
        leftFile: event.leftFile,
        rightFile: event.rightFile,
        carSetFile: event.carSetFile,
        carCategoriesUuid: event.carCategoriesUuid,
      );

      if (success) {
        emit(state.copyWith(
          uploadStatus: CarPhotoUploadStatus.success,
          uploadMessage: 'All car photos uploaded successfully',
        ));
        add(FetchCarPhotos());
      } else {
        emit(state.copyWith(
          uploadStatus: CarPhotoUploadStatus.failure,
          uploadMessage: 'Failed to upload all car photos.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        uploadStatus: CarPhotoUploadStatus.failure,
        uploadMessage: e.toString(),
      ));
    }
  }
}
