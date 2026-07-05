import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/custom_map_body_builder.dart';
import '../../splash/model/current_user_model.dart';


import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_urls.dart';
import '../../../utils/colors_code.dart';
import '../../../store/user_data_store.dart';
import '../../../utils/to_title_case.dart';
import '../../../core/utils/ui_utils.dart';

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../editProfile/controller/edit_profile_picture_bloc.dart';
import '../../editProfile/controller/edit_profile_picture_event.dart';
import '../../editProfile/controller/edit_profile_picture_state.dart';
import '../../../utils/enums.dart';
import '../../theme/controller/theme_bloc.dart';
import '../../localization/Controller/localization_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNotifLoading = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppUrls.profileImageUrl;
    final loc = AppLocalizations.of(context);
    final user = UserDataStore.userData?.data?.user;
    final name = toTiTleCase(user?.fullName ?? loc.translate("user_name"));
    final phone = user?.phoneNumber ?? 'N/A';
    final email = user?.email ?? 'N/A';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).colorScheme.surface,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
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
                              // Container(
                              //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              //   decoration: BoxDecoration(
                              //     color: Theme.of(context).colorScheme.surfaceContainer,
                              //     borderRadius: BorderRadius.circular(16),
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       Icon(Icons.star, size: 14, color: Theme.of(context).colorScheme.onSurface),
                              //       const SizedBox(width: 4),
                              //       Text(
                              //         loc.translate("5"),
                              //         style: GoogleFonts.poppins(
                              //           fontSize: 14,
                              //           fontWeight: FontWeight.w600,
                              //           color: Theme.of(context).colorScheme.onSurface,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              // const SizedBox(width: 12),
                              InkWell(
                                onTap: () => _showProfilePopup(context, name, email, phone, loc.locale.languageCode),
                                child: Text(
                                  loc.translate("view_profile"),
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
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          context.read<EditProfilePictureBloc>().add(
                            EditProfilePicture(
                              imageFile: File(pickedFile.path),
                              languageCode: loc.locale.languageCode,
                            ),
                          );
                        }
                      },
                      child: BlocConsumer<EditProfilePictureBloc, EditProfilePictureState>(
                        listener: (context, state) {
                          if (state.status == EditProfilePictureStatus.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.translate("profile_picture_updated") ?? "Profile picture updated")),
                            );
                            setState(() {}); // to refresh AppUrls.profileImageUrl
                          } else if (state.status == EditProfilePictureStatus.failure) {
                            UiUtils.showApiErrorPopup(context, state.errorMessage ?? "Failed to update profile picture");
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
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                    border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
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
                    ),
                  ],
                ),
              ),

              // POINTS & VOUCHERS (Horizontal Cards)
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 24),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: GestureDetector(
              //           onTap: () => Navigator.pushNamed(context, AppRoutes.points),
              //           child: Container(
              //             padding: const EdgeInsets.all(16),
              //             decoration: BoxDecoration(
              //               color: Theme.of(context).colorScheme.surfaceContainer,
              //               borderRadius: BorderRadius.circular(16),
              //             ),
              //             child: Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 Icon(Icons.wallet_giftcard, color: Theme.of(context).colorScheme.onSurface, size: 28),
              //                 const SizedBox(height: 12),
              //                 Text(
              //                   loc.translate("points"),
              //                   style: GoogleFonts.poppins(
              //                     fontSize: 16,
              //                     fontWeight: FontWeight.w600,
              //                     color: Theme.of(context).colorScheme.onSurface,
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: GestureDetector(
              //           onTap: () => Navigator.pushNamed(context, AppRoutes.voucher),
              //           child: Container(
              //             padding: const EdgeInsets.all(16),
              //             decoration: BoxDecoration(
              //               color: Theme.of(context).colorScheme.surfaceContainer,
              //               borderRadius: BorderRadius.circular(16),
              //             ),
              //             child: Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 Icon(Icons.local_offer_outlined, color: Theme.of(context).colorScheme.onSurface, size: 28),
              //                 const SizedBox(height: 12),
              //                 Text(
              //                   loc.translate("voucher"),
              //                   style: GoogleFonts.poppins(
              //                     fontSize: 16,
              //                     fontWeight: FontWeight.w600,
              //                     color: Theme.of(context).colorScheme.onSurface,
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),
              // const Divider(),

              // PREFERENCES LIST
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  loc.translate("preferences"),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              _buildListItem(
                icon: Icons.dark_mode_outlined,
                title: loc.translate("theme") ?? "Theme",
                trailingWidget: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return DropdownButton<ThemeMode>(
                      value: state.themeMode,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text("System", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface))),
                        DropdownMenuItem(value: ThemeMode.light, child: Text("Light", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface))),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text("Dark", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface))),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          context.read<ThemeBloc>().add(ThemeChanged(mode));
                        }
                      },
                    );
                  },
                ),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.language,
                title: loc.translate("language") ?? "Language",
                trailingWidget: BlocBuilder<LocalizationBloc, LocalizationState>(
                  builder: (context, state) {
                    return DropdownButton<String>(
                      value: state.locale.languageCode,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurface),
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                      items: [
                        DropdownMenuItem(value: 'en', child: Text("English", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface))),
                        DropdownMenuItem(value: 'bn', child: Text("বাংলা", style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface))),
                      ],
                      onChanged: (code) {
                        if (code != null) {
                          context.read<LocalizationBloc>().add(ChangeLanguageEvent(code));
                        }
                      },
                    );
                  },
                ),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.notifications_none,
                title: loc.translate("notification"),
                trailingWidget: _isNotifLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: user?.isNotificationEnabled ?? false,
                        onChanged: (val) async {
                          setState(() {
                            _isNotifLoading = true;
                          });
                          
                          final Map<String, dynamic> data = CustomMapBodyBuilder.build(
                            actionWhen: "customer_profile_edit",
                            languageCode: loc.locale.languageCode,
                            data: {
                              "uuid": UserDataStore.uuid,
                              "is_notification_enabled": val ? "true" : "false",
                              "device_token_for_notification": user?.deviceTokenForNotification ?? "",
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
                              final getResponse = await http.get(
                                Uri.parse(AppUrls.getCurrentDriverUser).replace(
                                  queryParameters: {
                                    "platform": CustomMapBodyBuilder.getPlatform(),
                                    "language_code": loc.locale.languageCode,
                                    "action_when": "admin_login",
                                  },
                                ),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Accept': 'application/json',
                                  'Authorization': 'Bearer ${UserDataStore.accessToken}'
                                }
                              );

                              if (getResponse.statusCode == 200) {
                                final jsonData = jsonDecode(getResponse.body);
                                CurrentUserModel currentUserModel = CurrentUserModel.fromJson(jsonData);
                                await UserDataStore.saveUserData(currentUserModel);
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Notification updated successfully')),
                                  );
                                }
                              } else {
                                throw Exception("Failed to fetch user");
                              }
                            } else {
                               throw Exception("Failed to update notification: ${response.statusCode} - ${response.body}");
                            }
                          } catch (e) {
                             if (mounted) {
                               UiUtils.showApiErrorPopup(context, e.toString());
                             }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isNotifLoading = false;
                              });
                            }
                          }
                        },
                        activeColor: Theme.of(context).colorScheme.onSurface,
                      ),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.menu_book,
                title: loc.translate("tutorial"),
                onTap: () {},
              ),

              const Divider(),

              // LEGAL LIST
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  loc.translate("legal"),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              _buildListItem(
                icon: Icons.help_outline,
                title: loc.translate("help"),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.article_outlined,
                title: loc.translate("terms_conditions"),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.description_outlined,
                title: loc.translate("trip_terms_conditions"),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.privacy_tip_outlined,
                title: loc.translate("privacy_policy"),
                onTap: () {},
              ),
              _buildListItem(
                icon: Icons.logout,
                title: loc.translate("logout"),
                onTap: () async {
                  await UserDataStore.clearAllData();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.numberInput,
                      (route) => false,
                    );
                  }
                },
                isDestructive: true,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
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
                color: isDestructive ? Colors.red.shade600 : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red.shade600 : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (trailingWidget != null)
                trailingWidget
              else
                Icon(
                  Icons.chevron_right,
                  color: isDestructive ? Colors.red.shade600 : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  
  void _showProfilePopup(BuildContext context, String initialName, String initialEmail, String initialPhone, String langCode) {
    TextEditingController nameController = TextEditingController(text: initialName);
    TextEditingController emailController = TextEditingController(text: initialEmail);
    TextEditingController phoneController = TextEditingController(text: initialPhone);
    TextEditingController nidController = TextEditingController();
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      readOnly: true,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nidController,
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'NID Number',
                        labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
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
                        UiUtils.showApiErrorPopup(this.context, 'Full Name is required');
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      
                      final Map<String, dynamic> data = CustomMapBodyBuilder.build(
                        actionWhen: "customer_profile_edit",
                        languageCode: langCode,
                        data: {
                          "phone_number": phoneController.text,
                          "country_code": "BD",
                          "uuid": UserDataStore.uuid,
                          "full_name": nameController.text,
                          "email": emailController.text,
                          "nid_number": nidController.text.trim(),
                          "is_notification_enabled": (UserDataStore.userData?.data?.user?.isNotificationEnabled ?? false).toString(),
                          "device_token_for_notification": UserDataStore.userData?.data?.user?.deviceTokenForNotification ?? "",
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
                          // Success! Now fetch updated user
                          final getResponse = await http.get(
                            Uri.parse(AppUrls.getCurrentDriverUser).replace(
                              queryParameters: {
                                "platform": CustomMapBodyBuilder.getPlatform(),
                                "language_code": langCode,
                                "action_when": "admin_login",
                              },
                            ),
                            headers: {
                              'Content-Type': 'application/json',
                              'Accept': 'application/json',
                              'Authorization': 'Bearer ${UserDataStore.accessToken}'
                            }
                          );

                          if (getResponse.statusCode == 200) {
                            final jsonData = jsonDecode(getResponse.body);
                            CurrentUserModel currentUserModel = CurrentUserModel.fromJson(jsonData);
                            await UserDataStore.saveUserData(currentUserModel);
                            
                            // Rebuild profile screen
                            setState(() {});
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Profile updated successfully')),
                              );
                            }
                          } else {
                            print("GET ERROR: ${getResponse.statusCode} - ${getResponse.body}");
                            throw Exception("Failed to fetch user: ${getResponse.body}");
                          }
                        } else {
                           print("POST ERROR: ${response.statusCode} - ${response.body}");
                           throw Exception("Failed to update profile: ${response.body}");
                        }
                      } catch (e) {
                         if (mounted) {
                           UiUtils.showApiErrorPopup(this.context, e.toString());
                         }
                      } finally {
                        if (mounted) {
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
}

