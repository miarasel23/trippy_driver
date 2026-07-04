import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../utils/app_urls.dart';
import '../../../utils/colors_code.dart';
import '../../../utils/enums.dart';
import '../../../core/utils/ui_utils.dart';
import '../controller/edit_profile_info_bloc.dart';
import '../controller/edit_profile_info_event.dart';
import '../controller/edit_profile_info_state.dart';
import '../controller/edit_profile_picture_bloc.dart';
import '../controller/edit_profile_picture_event.dart'
    show EditProfilePicture;
import '../controller/edit_profile_picture_state.dart';

class EditprofileScreen extends StatefulWidget {
  const EditprofileScreen({super.key});

  @override
  State<EditprofileScreen> createState() => _EditprofileScreenState();
}

class _EditprofileScreenState extends State<EditprofileScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _email = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(AppLocalizations loc) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      context.read<EditProfilePictureBloc>().add(
        EditProfilePicture(
          imageFile: File(image.path),
          languageCode: loc.locale.languageCode,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    _name.text = loc.translate("user_name");
    _phoneNumber.text = loc.translate("user_phone_number");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.translate("Profile"),
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocListener<EditProfileInfoBloc, EditProfileUpdateState>(
          listener: (context, state) {
            if (state.status == EditProfileUpdateStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.translate("profile_updated_successfully")),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state.status == EditProfileUpdateStatus.failure) {
              UiUtils.showApiErrorPopup(context, state.errorMessage ?? loc.translate("failed"));
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                width: double.infinity,
                                height: 65,
                              ),
                              Positioned(
                                top: 28,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      BlocBuilder<
                                        EditProfilePictureBloc,
                                        EditProfilePictureState
                                      >(
                                        builder: (context, state) {
                                          if (state.status ==
                                                  EditProfilePictureStatus.success &&
                                              state.avatar != null) {
                                            return ClipOval(
                                              child: Image.file(
                                                state.avatar!,
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          }
            
                                          if (state.status ==
                                              EditProfilePictureStatus.loading) {
                                            return Container(
                                              padding: EdgeInsets.all(8.0),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 3,
                                                  color: Colors.white,
                                                ),
                                                color: Theme.of(context).colorScheme.surfaceContainer,
                                                shape: BoxShape.circle,
                                              ),
                                              child: CircularProgressIndicator(
                                                color: AppColors
                                                    .editProfileScreenCircularProgressIndicator,
                                              ),
                                            );
                                          }
            
                                          final imageUrl = AppUrls.profileImageUrl;
            
                                          return GestureDetector(
                                            onTap: () {
                                              _pickImage(loc);
                                            },
                                            child: ClipOval(
                                              child: SizedBox(
                                                width: 70,
                                                height: 70,
                                                child: Builder(
                                                  builder: (context) {
                                                    // 1. Local image (highest priority)
                                                    if (state.avatar != null) {
                                                      return Image.file(
                                                        state.avatar!,
                                                        fit: BoxFit.cover,
                                                      );
                                                    }
            
                                                    // 2. Network image
                                                    if (imageUrl != null &&
                                                        imageUrl.isNotEmpty) {
                                                      return Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder:
                                                            (
                                                              context,
                                                              child,
                                                              loadingProgress,
                                                            ) {
                                                              if (loadingProgress ==
                                                                  null) {
                                                                return child;
                                                              }
            
                                                              return const Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              );
                                                            },
                                                        errorBuilder: (_, _, _) {
                                                          return const Icon(
                                                            Icons.person,
                                                          );
                                                        },
                                                      );
                                                    }
            
                                                    // 3. Fallback icon
                                                    return const Icon(
                                                      Icons.person,
                                                      size: 35,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            _pickImage(loc);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4.0),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainer,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.outline,
                                                width: 2,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(1.0),
                                              child: Icon(
                                                Icons.edit,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                size: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 38),
                          Text(
                            loc.translate("name"),
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _name,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            loc.translate("phone_number"),
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneNumber,
                            readOnly: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            loc.translate("email"),
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: _email,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          const SizedBox(height: 40),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  onPressed: () {},
                                  child: Text(
                                    loc.translate("delete_account"),
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  onPressed: () async {
                                    context.read<EditProfileInfoBloc>().add(
                                      EditProfileInfo(
                                        languageCode: loc.locale.languageCode,
                                        email: _email.text.trim(),
                                        phoneNumber: _phoneNumber.text.trim(),
                                        fullName: _name.text.trim(),
                                      ),
                                    );
                                  },
                                  child:
                                      BlocBuilder<
                                        EditProfileInfoBloc,
                                        EditProfileUpdateState
                                      >(
                                        builder: (context, state) {
                                          switch (state.status) {
                                            case EditProfileUpdateStatus.loading:
                                              return const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              );
          
                                            case EditProfileUpdateStatus.success:
                                              return Text(
                                                loc.translate("update"),
                                                style: GoogleFonts.poppins(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              );
                                            case EditProfileUpdateStatus.initial:
                                              return Text(
                                                loc.translate("update"),
                                                style: GoogleFonts.poppins(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              );
                                            case EditProfileUpdateStatus.failure:
                                              return Text(
                                                loc.translate("failed"),
                                                style: GoogleFonts.poppins(
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              );
                                            default:
                                              return SizedBox();
                                          }
                                        },
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phoneNumber.dispose();
    super.dispose();
  }
}
