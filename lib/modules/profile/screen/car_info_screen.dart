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
import '../controller/car_info_bloc.dart';
import '../repository/car_info_repository.dart';

class CarInfoScreen extends StatelessWidget {
  const CarInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CarInfoBloc(
        repository: CarInfoRepository(),
      )..add(FetchCarDocuments()),
      child: const CarInfoView(),
    );
  }
}

class CarInfoView extends StatefulWidget {
  const CarInfoView({super.key});

  @override
  State<CarInfoView> createState() => _CarInfoViewState();
}

class _CarInfoViewState extends State<CarInfoView> {
  String _formatDocType(String type) {
    switch (type) {
      case 'VEHICLE_REGISTRATION_SMART_CARD_COPY':
        return 'Registration Smart Card Copy';
      case 'VEHICLE_TAX_FONT_COPY':
      case 'VEHICLE_TAX_FRONT_COPY':
        return 'Vehicle Tax Front Copy';
      case 'VEHICLE_TAX_BACK_COPY':
        return 'Vehicle Tax Back Copy';
      case 'VEHICLE_FITNESS_CERTIFICATE_FONT_COPY':
      case 'VEHICLE_FITNESS_CERTIFICATE_FRONT_COPY':
        return 'Fitness Certificate Front Copy';
      case 'VEHICLE_FITNESS_CERTIFICATE_BACK_COPY':
        return 'Fitness Certificate Back Copy';
      default:
        return type
            .replaceAll('VEHICLE_', '')
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' ');
    }
  }

  void _showImageSourceBottomSheet(BuildContext context, String documentType, String documentNumber) {
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
                  'Upload new copy for ${_formatDocType(documentType)}',
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
                  _pickAndUploadImage(context, ImageSource.gallery, documentType, documentNumber);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                title: Text('Direct Camera Photo', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickAndUploadImage(context, ImageSource.camera, documentType, documentNumber);
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
    String documentNumber,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (file != null) {
        if (context.mounted) {
          context.read<CarInfoBloc>().add(
            UploadCarDocument(
              imagePath: file.path,
              documentType: documentType,
              documentNumber: documentNumber,
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
          loc.translate("car_info") ?? "Car Info",
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocListener<CarInfoBloc, CarInfoState>(
          listenWhen: (previous, current) => previous.uploadStatus != current.uploadStatus,
          listener: (context, state) {
            if (state.uploadStatus == CarDocumentUploadStatus.loading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
            } else if (state.uploadStatus == CarDocumentUploadStatus.success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.uploadMessage ?? 'Document copy uploaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.uploadStatus == CarDocumentUploadStatus.failure) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.uploadMessage ?? 'Failed to upload document copy'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<CarInfoBloc>().add(FetchCarDocuments());
            },
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DOCUMENT INFO
                    _buildSectionHeader(loc.translate("document_info") ?? "Document info", Icons.description_outlined),
                    const SizedBox(height: 12),

                    BlocBuilder<CarInfoBloc, CarInfoState>(
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

                        final documents = state.documents;
                        if (documents.isEmpty) {
                          return const UploadAllCarDocumentsForm();
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: documents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            final type = doc['document_type'] ?? '';
                            final number = doc['document_number'] ?? 'N/A';
                            final status = doc['is_verified'] ?? '';
                            final url = doc['document_url'] ?? '';

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
                                            // Image Thumbnail or Icon
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: url.isNotEmpty
                                                  ? Image.network(
                                                      "${AppUrls.imageBaseUrl}$url",
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        width: 60,
                                                        height: 60,
                                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                        child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                      ),
                                                    )
                                                  : Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: const Color(0xFFE8F0FE),
                                                      child: const Icon(Icons.file_present_rounded, color: Color(0xFF1A73E8)),
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Info details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatDocType(type),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  if (type == 'VEHICLE_REGISTRATION_SMART_CARD_COPY') ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Reg Number: $number',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
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
                                        if (!isActive) ...[
                                          const SizedBox(height: 12),
                                          const Divider(height: 1),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _showImageSourceBottomSheet(context, type, number),
                                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                            label: Text(
                                              'Upload New Document Copy',
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
              context.read<CarInfoBloc>().add(FetchCarDocuments());
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

  Widget _buildEmptyWidget(BuildContext context, AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          Text(
            'No verified documents available.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class UploadAllCarDocumentsForm extends StatefulWidget {
  const UploadAllCarDocumentsForm({super.key});

  @override
  State<UploadAllCarDocumentsForm> createState() => _UploadAllCarDocumentsFormState();
}

class _UploadAllCarDocumentsFormState extends State<UploadAllCarDocumentsForm> {
  final _formKey = GlobalKey<FormState>();
  final _regNumController = TextEditingController();

  File? _smartCard;
  File? _taxFront;
  File? _taxBack;
  File? _fitnessFront;
  File? _fitnessBack;

  @override
  void dispose() {
    _regNumController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String field) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        setState(() {
          if (field == 'smartCard') _smartCard = File(file.path);
          if (field == 'taxFront') _taxFront = File(file.path);
          if (field == 'taxBack') _taxBack = File(file.path);
          if (field == 'fitnessFront') _fitnessFront = File(file.path);
          if (field == 'fitnessBack') _fitnessBack = File(file.path);
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_smartCard == null || _taxFront == null || _taxBack == null || _fitnessFront == null || _fitnessBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All document photos are required. Please upload Smart Card, Tax Front, Tax Back, Fitness Front, and Fitness Back copies.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<CarInfoBloc>().add(
      UploadAllCarDocuments(
        smartCardFile: _smartCard!,
        registrationNumber: _regNumController.text.trim(),
        taxFrontFile: _taxFront!,
        taxBackFile: _taxBack!,
        fitnessFrontFile: _fitnessFront!,
        fitnessBackFile: _fitnessBack!,
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
              'Upload Car Documents',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Reg Number input
            TextFormField(
              controller: _regNumController,
              keyboardType: TextInputType.text,
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Vehicle Registration Number *',
                labelStyle: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Registration Number is required' : null,
            ),
            const SizedBox(height: 20),

            // Smart Card Picker Card
            Text(
              'Registration Smart Card Copy *',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _buildFilePickerItem(
              label: 'Upload Smart Card Copy *',
              file: _smartCard,
              onTap: () => _showImageSourceOptions('smartCard'),
            ),
            const Divider(height: 32),

            // Tax Pickers Row
            Text(
              'Vehicle Tax Token Copies *',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Tax Token Front *',
                    file: _taxFront,
                    onTap: () => _showImageSourceOptions('taxFront'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Tax Token Back *',
                    file: _taxBack,
                    onTap: () => _showImageSourceOptions('taxBack'),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Fitness Pickers Row
            Text(
              'Fitness Certificate Copies *',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Fitness Front *',
                    file: _fitnessFront,
                    onTap: () => _showImageSourceOptions('fitnessFront'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFilePickerItem(
                    label: 'Fitness Back *',
                    file: _fitnessBack,
                    onTap: () => _showImageSourceOptions('fitnessBack'),
                  ),
                ),
              ],
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
