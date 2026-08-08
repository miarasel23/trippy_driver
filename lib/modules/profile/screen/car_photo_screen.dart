import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/app_urls.dart';
import '../../../../utils/to_title_case.dart';
import '../../../../widgets/full_screen_image_gallery.dart';
import '../controller/car_photo_bloc.dart';
import '../repository/car_photo_repository.dart';

class CarPhotoScreen extends StatelessWidget {
  const CarPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CarPhotoBloc(
        repository: CarPhotoRepository(),
      )..add(FetchCarPhotos())..add(FetchCarCategories()),
      child: const CarPhotoView(),
    );
  }
}

class CarPhotoView extends StatefulWidget {
  const CarPhotoView({super.key});

  @override
  State<CarPhotoView> createState() => _CarPhotoViewState();
}

class _CarPhotoViewState extends State<CarPhotoView> {
  String _formatPhotoType(String type) {
    switch (type.toUpperCase()) {
      case 'FRONT':
        return 'Front View';
      case 'BACK':
        return 'Rear View';
      case 'LEFT':
        return 'Left Side View';
      case 'RIGHT':
        return 'Right Side View';
      case 'CAR_SET':
        return 'Interior Seating View';
      default:
        return type;
    }
  }

  void _showImageSourceBottomSheet(BuildContext context, String documentType, String carCategoriesUuid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  'Upload new copy for ${_formatPhotoType(documentType)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                title: Text('Upload from Mobile Gallery', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndUploadImage(context, ImageSource.gallery, documentType, carCategoriesUuid);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                title: Text('Direct Camera Photo', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndUploadImage(context, ImageSource.camera, documentType, carCategoriesUuid);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    ImageSource source,
    String documentType,
    String carCategoriesUuid,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (file != null) {
        if (context.mounted) {
          context.read<CarPhotoBloc>().add(
            UploadCarPhotoSingle(
              imagePath: file.path,
              documentType: documentType,
              carCategoriesUuid: carCategoriesUuid,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate("car_photo") ?? "Car Photo",
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocListener<CarPhotoBloc, CarPhotoState>(
          listenWhen: (previous, current) => previous.uploadStatus != current.uploadStatus,
          listener: (context, state) {
            if (state.uploadStatus == CarPhotoUploadStatus.loading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
            } else if (state.uploadStatus == CarPhotoUploadStatus.success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.uploadMessage ?? 'Photo uploaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.uploadStatus == CarPhotoUploadStatus.failure) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.uploadMessage ?? 'Failed to upload photo'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<CarPhotoBloc>().add(FetchCarPhotos());
            },
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<CarPhotoBloc, CarPhotoState>(
                      builder: (context, state) {
                        if (state.isLoading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (state.errorMessage != null) {
                          return _buildErrorWidget(context, state.errorMessage!);
                        }

                        final photos = state.photos;
                        if (photos.isEmpty) {
                          return const UploadAllCarPhotosForm();
                        }

                        final categoryInfo = state.carCategoryInfo;
                        final carCategoriesUuid = categoryInfo != null ? categoryInfo['uuid']?.toString() ?? '' : '';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CAR CATEGORY DETAILS CARD
                            if (categoryInfo != null) ...[
                              _buildSectionHeader('Assigned Category', Icons.commute_outlined),
                              const SizedBox(height: 12),
                              _buildCategoryCard(context, categoryInfo, isDark),
                              const SizedBox(height: 32),
                            ],

                            // PHOTO LIST
                            _buildSectionHeader('Verification Photos', Icons.photo_library_outlined),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: photos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final photo = photos[index];
                                final type = photo['document_type'] ?? '';
                                final status = photo['is_verified'] ?? '';
                                final url = photo['document_url'] ?? '';

                                final isActive = status.toString().toUpperCase() == 'ACTIVE';

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (url.isNotEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => FullScreenImageGallery(
                                              images: [url],
                                              initialIndex: 0,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // Image Preview
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: url.isNotEmpty
                                                      ? Image.network(
                                                          "${AppUrls.imageBaseUrl}$url",
                                                          width: 70,
                                                          height: 70,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Container(
                                                            width: 70,
                                                            height: 70,
                                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                            child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 70,
                                                          height: 70,
                                                          color: const Color(0xFFE8F0FE),
                                                          child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1A73E8)),
                                                        ),
                                                ),
                                                const SizedBox(width: 16),
                                                // Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _formatPhotoType(type),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Status: $status',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 13,
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (!isActive && carCategoriesUuid.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              const Divider(height: 1),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                onPressed: () => _showImageSourceBottomSheet(context, type, carCategoriesUuid),
                                                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                                label: Text(
                                                  'Upload New Photo copy',
                                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(double.infinity, 40),
                                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> info, bool isDark) {
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Theme.of(context).colorScheme.surface;
    final carType = info['car_type']?.toString() ?? 'N/A';
    final seatCapacity = info['set_capacity']?.toString() ?? 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_taxi, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Car Category Type',
                      style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      carType,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_outline, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seating Capacity',
                      style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$seatCapacity Persons',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String errorMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<CarPhotoBloc>().add(FetchCarPhotos());
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }
}

class UploadAllCarPhotosForm extends StatefulWidget {
  const UploadAllCarPhotosForm({super.key});

  @override
  State<UploadAllCarPhotosForm> createState() => _UploadAllCarPhotosFormState();
}

class _UploadAllCarPhotosFormState extends State<UploadAllCarPhotosForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategoryUuid;

  File? _front;
  File? _back;
  File? _left;
  File? _right;
  File? _carSet;

  Future<void> _pickImage(ImageSource source, String field) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        setState(() {
          if (field == 'front') _front = File(file.path);
          if (field == 'back') _back = File(file.path);
          if (field == 'left') _left = File(file.path);
          if (field == 'right') _right = File(file.path);
          if (field == 'carSet') _carSet = File(file.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceOptions(String field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                title: Text('Upload from Mobile Gallery', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(c);
                  _pickImage(ImageSource.gallery, field);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                title: Text('Direct Camera Photo', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(c);
                  _pickImage(ImageSource.camera, field);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilePickerItem({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: file != null ? Colors.transparent : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(file != null ? 0.8 : 0.2),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: file != null
              ? Image.file(file, fit: BoxFit.cover, width: double.infinity)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 22, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate() || _selectedCategoryUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Car Category first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_front == null || _back == null || _left == null || _right == null || _carSet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All 5 vehicle photos are required (Front, Back, Left, Right, Interior Seating).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<CarPhotoBloc>().add(
      UploadAllCarPhotos(
        frontFile: _front!,
        backFile: _back!,
        leftFile: _left!,
        rightFile: _right!,
        carSetFile: _carSet!,
        carCategoriesUuid: _selectedCategoryUuid!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Theme.of(context).colorScheme.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Car Photos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dropdown Category
            BlocBuilder<CarPhotoBloc, CarPhotoState>(
              builder: (context, state) {
                if (state.isCategoriesLoading) {
                  return const LinearProgressIndicator();
                }

                final items = state.categories;
                if (items.isEmpty) {
                  return Text(
                    'No active car categories available.',
                    style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategoryUuid,
                  decoration: InputDecoration(
                    labelText: 'Select Car Category *',
                    labelStyle: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.local_taxi_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  items: items.map((cat) {
                    final label = "${cat['car_type'].toString().replaceAll('_', ' ')} (${cat['set_capacity']} Seats)";
                    return DropdownMenuItem<String>(
                      value: cat['uuid'].toString(),
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryUuid = val;
                    });
                  },
                  validator: (val) => val == null ? 'Car category is required' : null,
                );
              },
            ),
            const SizedBox(height: 24),

            // Pickers
            Text(
              'Front & Rear Views *',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Front View *',
                    file: _front,
                    onTap: () => _showImageSourceOptions('front'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Rear View *',
                    file: _back,
                    onTap: () => _showImageSourceOptions('back'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            Text(
              'Side Views *',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Left Side *',
                    file: _left,
                    onTap: () => _showImageSourceOptions('left'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Right Side *',
                    file: _right,
                    onTap: () => _showImageSourceOptions('right'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            Text(
              'Interior Seating View *',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _buildFilePickerItem(
              label: 'Upload Interior View *',
              file: _carSet,
              onTap: () => _showImageSourceOptions('carSet'),
            ),
            const SizedBox(height: 28),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                'Upload & Submit All',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
