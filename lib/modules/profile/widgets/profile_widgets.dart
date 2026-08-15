import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../core/utils/ui_utils.dart';
import '../../../routes/app_routes.dart';
import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';
import '../../../utils/custom_map_body_builder.dart';

import '../../editProfile/controller/edit_profile_picture_bloc.dart';
import '../../editProfile/controller/edit_profile_picture_event.dart';
import '../../editProfile/controller/edit_profile_picture_state.dart';
import '../../localization/Controller/localization_controller.dart';
import '../../splash/model/current_user_model.dart';
import '../../theme/controller/theme_bloc.dart';
import '../../../utils/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE HEADER WIDGET
// Shows name, active status badge, view profile link
// ─────────────────────────────────────────────────────────────────────────────
class ProfileHeader extends StatelessWidget {
  final String name;
  final String? isActive;
  final VoidCallback onViewProfile;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.isActive,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final statusStr = isActive?.toUpperCase() ?? 'INACTIVE';
    final active = statusStr == 'ACTIVE';
    final isProgress = statusStr == 'PROGRESS' || statusStr == 'UNDER_REVIEW';

    final Color badgeBgColor = active
        ? Colors.green.shade100
        : (isProgress ? Colors.orange.shade100 : Colors.red.shade100);

    final Color badgeTextColor = active
        ? Colors.green.shade800
        : (isProgress ? Colors.orange.shade800 : Colors.red.shade800);

    final String label = active
        ? loc.translate('active')
        : (isProgress ? loc.translate('under_review') : loc.translate('inactive'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onViewProfile,
              child: Text(
                loc.translate('view_profile'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE AVATAR WIDGET
// Shows avatar with edit button, handles image picking and BLoC
// ─────────────────────────────────────────────────────────────────────────────
class ProfileAvatar extends StatelessWidget {
  final VoidCallback onRefresh;

  const ProfileAvatar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () async {
        final bloc = context.read<EditProfilePictureBloc>();
        final langCode = loc.locale.languageCode;
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          bloc.add(
            EditProfilePicture(
              imageFile: File(pickedFile.path),
              languageCode: langCode,
            ),
          );
        }
      },
      child: BlocConsumer<EditProfilePictureBloc, EditProfilePictureState>(
        listener: (context, state) {
          if (state.status == EditProfilePictureStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    loc.translate('profile_picture_updated')),
              ),
            );
            onRefresh();
          } else if (state.status == EditProfilePictureStatus.failure) {
            UiUtils.showApiErrorPopup(
                context, state.errorMessage ?? 'Failed to update profile picture');
          }
        },
        builder: (context, state) {
          Widget avatarWidget;
          if (state.status == EditProfilePictureStatus.loading) {
            avatarWidget = CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: const CircularProgressIndicator(),
            );
          } else {
            final currentImageUrl = AppUrls.profileImageUrl;
            if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
              avatarWidget = CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(currentImageUrl),
                backgroundColor: Colors.grey.shade200,
              );
            } else {
              avatarWidget = CircleAvatar(
                radius: 40,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              );
            }
          }

          return Stack(
            children: [
              avatarWidget,
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.surface,
                    size: 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTRATION INFO CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class RegistrationInfoCard extends StatelessWidget {
  final String? isActive;

  const RegistrationInfoCard({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final active = isActive?.toUpperCase() == 'ACTIVE';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final Color contentColor;
    final Color iconBgColor;
    final Border cardBorder;

    if (active) {
      contentColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      iconBgColor = isDark
          ? const Color(0xFF81C784).withValues(alpha: 0.15)
          : const Color(0xFFE8F5E9);
      cardBorder = Border.all(
        color:
            (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32)).withValues(alpha: 0.4),
        width: 1.5,
      );
    } else {
      contentColor = isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
      iconBgColor = isDark
          ? const Color(0xFFE57373).withValues(alpha: 0.15)
          : const Color(0xFFFFEBEE);
      cardBorder = Border.all(
        color:
            (isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F)).withValues(alpha: 0.4),
        width: 1.5,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: cardBorder,
          boxShadow: [
            BoxShadow(
              color: cardBgColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.registrationInfo),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: contentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('registration_info'),
                          style: GoogleFonts.poppins(
                            color: contentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.translate('view_and_verify_documents'),
                          style: GoogleFonts.poppins(
                            color: contentColor.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: contentColor,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE SECTION TITLE WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class ProfileSectionTitle extends StatelessWidget {
  final String title;

  const ProfileSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE LIST ITEM WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileListItem({
    super.key,
    required this.icon,
    required this.title,
    this.trailingText,
    this.trailingWidget,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isDestructive
                    ? Colors.red.shade600
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive
                        ? Colors.red.shade600
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (trailingWidget != null)
                trailingWidget!
              else
                Icon(
                  Icons.chevron_right,
                  color: isDestructive
                      ? Colors.red.shade600
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME DROPDOWN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class ThemeDropdown extends StatelessWidget {
  const ThemeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return DropdownButton<ThemeMode>(
          value: state.themeMode,
          underline: const SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onSurface),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
          style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface),
          items: [
            DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface))),
            DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface))),
            DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface))),
          ],
          onChanged: (mode) {
            if (mode != null) {
              context.read<ThemeBloc>().add(ThemeChanged(mode));
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE DROPDOWN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        return DropdownButton<String>(
          value: state.locale.languageCode,
          underline: const SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.onSurface),
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
          style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface),
          items: [
            DropdownMenuItem(
                value: 'en',
                child: Text('English',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface))),
            DropdownMenuItem(
                value: 'bn',
                child: Text('বাংলা',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface))),
          ],
          onChanged: (code) {
            if (code != null) {
              context.read<LocalizationBloc>().add(ChangeLanguageEvent(code));
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE DIALOG — shows a dialog to edit name, email, NID
// ─────────────────────────────────────────────────────────────────────────────
void showEditProfileDialog({
  required BuildContext context,
  required String initialName,
  required String initialEmail,
  required String initialPhone,
  required String langCode,
  required VoidCallback onSaved,
}) {
  final nameController = TextEditingController(text: initialName);
  final emailController = TextEditingController(text: initialEmail);
  final phoneController = TextEditingController(text: initialPhone);
  final nidController = TextEditingController();
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style:
                        GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      labelStyle: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    readOnly: true,
                    style:
                        GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style:
                        GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nidController,
                    style:
                        GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'NID Number',
                      labelStyle: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      UiUtils.showApiErrorPopup(context, 'Full Name is required');
                      return;
                    }

                    setDialogState(() => isLoading = true);

                    final Map<String, dynamic> data = CustomMapBodyBuilder.build(
                      actionWhen: 'driver_profile_edit',
                      languageCode: langCode,
                      data: {
                        'phone_number': phoneController.text,
                        'country_code': 'BD',
                        'uuid': UserDataStore.uuid,
                        'full_name': nameController.text,
                        'email': emailController.text,
                        'nid_number': nidController.text.trim(),
                        'is_notification_enabled':
                            (UserDataStore.userData?.data?.user?.isNotificationEnabled ??
                                    false)
                                ? '1'
                                : '0',
                        'device_token_for_notification':
                            UserDataStore.userData?.data?.user
                                    ?.deviceTokenForNotification ??
                                '',
                        'is_active':
                            UserDataStore.userData?.data?.user?.isActive ?? 'ACTIVE',
                      },
                    );

                    try {
                      final response = await http.post(
                        Uri.parse(AppUrls.driverProfileUpdate),
                        body: data,
                        headers: {
                          'Authorization': 'Bearer ${UserDataStore.accessToken}'
                        },
                      );

                      if (response.statusCode == 200) {
                        final jsonData = jsonDecode(response.body);
                        if (jsonData['status'] == true &&
                            jsonData['data'] != null &&
                            jsonData['data']['user'] != null) {
                          final updatedUser = User.fromJson(jsonData['data']['user']);
                          if (UserDataStore.userData != null &&
                              UserDataStore.userData!.data != null) {
                            UserDataStore.userData!.data!.user = updatedUser;
                            await UserDataStore.saveUserData(UserDataStore.userData!);
                          }

                          onSaved();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                  content: Text('Profile updated successfully')),
                            );
                          }
                        } else {
                          throw Exception('Failed to update: status is false');
                        }
                      } else {
                        throw Exception(
                            'Failed to update profile: ${response.body}');
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        UiUtils.showApiErrorPopup(dialogContext, e.toString());
                      }
                    } finally {
                      if (dialogContext.mounted) {
                        setDialogState(() => isLoading = false);
                      }
                    }
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
    },
  );
}
