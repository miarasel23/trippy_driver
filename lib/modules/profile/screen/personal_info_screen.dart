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
import '../controller/personal_info_bloc.dart';
import '../repository/personal_info_repository.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PersonalInfoBloc(
        repository: PersonalInfoRepository(),
      )..add(FetchPersonalInfoDocuments()),
      child: const PersonalInfoView(),
    );
  }
}

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({super.key});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  String _formatDocType(String type) {
    switch (type) {
      case 'NID_FRONT_COPY':
        return 'NID Front Copy';
      case 'NID_BACK_COPY':
        return 'NID Back Copy';
      case 'LICENSE_FONT_COPY':
        return 'License Front Copy';
      case 'LICENSE_BACK_COPY':
        return 'License Back Copy';
      default:
        return type
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
            .join(' ');
    }
  }

  void _showEditNamePopup(BuildContext context, String initialName) {
    final controller = TextEditingController(text: initialName);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Name',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          content: TextField(
            controller: controller,
            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Full Name *',
              labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                context.read<PersonalInfoBloc>().add(UpdateProfileName(newName));
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
          context.read<PersonalInfoBloc>().add(
            UploadDriverDocument(
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
    final user = UserDataStore.userData?.data?.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final phone = user?.phoneNumber ?? 'N/A';
    final name = toTiTleCase(user?.fullName ?? '');
    final email = user?.email ?? 'N/A';

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
          loc.translate("personal_info") ?? "Personal Info",
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocListener<PersonalInfoBloc, PersonalInfoState>(
          listenWhen: (previous, current) =>
              previous.updateStatus != current.updateStatus ||
              previous.uploadStatus != current.uploadStatus,
          listener: (context, state) {
            // Check Profile Update State
            if (state.updateStatus == ProfileUpdateStatus.loading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
            } else if (state.updateStatus == ProfileUpdateStatus.success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.updateMessage ?? 'Profile updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {});
            } else if (state.updateStatus == ProfileUpdateStatus.failure) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.updateMessage ?? 'Failed to update profile'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }

            // Check Document Upload State
            if (state.uploadStatus == DocumentUploadStatus.loading) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
            } else if (state.uploadStatus == DocumentUploadStatus.success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.uploadMessage ?? 'Document copy uploaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.uploadStatus == DocumentUploadStatus.failure) {
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
              context.read<PersonalInfoBloc>().add(FetchPersonalInfoDocuments());
            },
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: PROFILE INFO
                    _buildSectionHeader(loc.translate("profile_info") ?? "Profile info", Icons.badge_outlined),
                    const SizedBox(height: 12),
                    _buildProfileCard(context, name, phone, email, isDark),
                    
                    const SizedBox(height: 32),

                    // SECTION 2: DOCUMENT INFO
                    _buildSectionHeader(loc.translate("document_info") ?? "Document info", Icons.description_outlined),
                    const SizedBox(height: 12),

                    BlocBuilder<PersonalInfoBloc, PersonalInfoState>(
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
                          return _buildEmptyWidget(context, loc);
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: documents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            final type = doc['document_type'] ?? '';
                            final number = doc['document_number'] ?? '';
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
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Number: $number',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Status Badge (light green if active, red if not active)
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

  Widget _buildProfileCard(BuildContext context, String name, String phone, String email, bool isDark) {
    final cardBgColor = isDark 
        ? const Color(0xFF1E293B) 
        : Theme.of(context).colorScheme.surface;

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
          _buildProfileItem(
            context,
            Icons.person_outline,
            'Full Name',
            name,
            onEdit: () => _showEditNamePopup(context, name),
          ),
          const Divider(height: 24),
          _buildProfileItem(context, Icons.phone_android_outlined, 'Phone Number', phone),
          const Divider(height: 24),
          _buildProfileItem(context, Icons.mail_outline, 'Email Address', email),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String label, String value, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
            color: Theme.of(context).colorScheme.primary,
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
              context.read<PersonalInfoBloc>().add(FetchPersonalInfoDocuments());
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
