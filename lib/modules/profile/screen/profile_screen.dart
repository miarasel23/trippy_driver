import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization/app_localization.dart';
import '../../../routes/app_routes.dart';
import '../../../store/user_data_store.dart';
import '../../../utils/app_urls.dart';
import '../../../utils/custom_map_body_builder.dart';
import '../../../utils/to_title_case.dart';
import '../../../core/utils/ui_utils.dart';
import '../../splash/model/current_user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widgets/profile_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNotifLoading = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = UserDataStore.userData?.data?.user;
    final name = toTiTleCase(user?.fullName ?? loc.translate('user_name'));
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
              // ── HEADER: name + avatar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ProfileHeader(
                        name: name,
                        isActive: user?.isActive,
                        onViewProfile: () => showEditProfileDialog(
                          context: context,
                          initialName: name,
                          initialEmail: email,
                          initialPhone: phone,
                          langCode: loc.locale.languageCode,
                          onSaved: () => setState(() {}),
                        ),
                      ),
                    ),
                    ProfileAvatar(onRefresh: () => setState(() {})),
                  ],
                ),
              ),

              // ── REGISTRATION INFO CARD ─────────────────────────────────────
              RegistrationInfoCard(isActive: user?.isActive),

              // ── PREFERENCES ───────────────────────────────────────────────
              ProfileSectionTitle(title: loc.translate('preferences')),

              ProfileListItem(
                icon: Icons.dark_mode_outlined,
                title: loc.translate('theme'),
                trailingWidget: const ThemeDropdown(),
                onTap: () {},
              ),

              ProfileListItem(
                icon: Icons.language,
                title: loc.translate('language'),
                trailingWidget: const LanguageDropdown(),
                onTap: () {},
              ),

              ProfileListItem(
                icon: Icons.notifications_none,
                title: loc.translate('notification'),
                trailingWidget: _isNotifLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: UserDataStore.userData?.data?.user
                                ?.isNotificationEnabled ??
                            false,
                        onChanged: (val) => _updateNotification(val, loc),
                        activeThumbColor: Theme.of(context).colorScheme.onSurface,
                      ),
                onTap: () {
                  if (!_isNotifLoading) {
                    final currentVal = UserDataStore.userData?.data?.user
                            ?.isNotificationEnabled ??
                        false;
                    _updateNotification(!currentVal, loc);
                  }
                },
              ),

              // ProfileListItem(
              //   icon: Icons.menu_book,
              //   title: loc.translate('tutorial'),
              //   onTap: () {},
              // ),

              const Divider(),

              // ── LEGAL ─────────────────────────────────────────────────────
              ProfileSectionTitle(title: loc.translate('legal')),

              ProfileListItem(
                icon: Icons.help_outline,
                title: loc.translate('help'),
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.legalPolicy,
                    arguments: 'HELP_AND_SUPPORT'),
              ),
              ProfileListItem(
                icon: Icons.article_outlined,
                title: loc.translate('terms_conditions'),
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.legalPolicy,
                    arguments: 'TERMS_CONDITION'),
              ),
              ProfileListItem(
                icon: Icons.description_outlined,
                title: loc.translate('trip_terms_conditions'),
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.legalPolicy,
                    arguments: 'TRIP_POLICY'),
              ),
              ProfileListItem(
                icon: Icons.privacy_tip_outlined,
                title: loc.translate('privacy_policy'),
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.legalPolicy,
                    arguments: 'PRIVACY_POLICY'),
              ),
              ProfileListItem(
                icon: Icons.logout,
                title: loc.translate('logout'),
                onTap: () => _logout(),
                isDestructive: true,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOGIC: update notification ─────────────────────────────────────────
  Future<void> _updateNotification(bool val, AppLocalizations loc) async {
    setState(() => _isNotifLoading = true);

    final Map<String, dynamic> data = CustomMapBodyBuilder.build(
      actionWhen: 'driver_profile_edit',
      languageCode: loc.locale.languageCode,
      data: {
        'uuid': UserDataStore.uuid,
        'is_notification_enabled': val ? '1' : '0',
        'device_token_for_notification':
            UserDataStore.userData?.data?.user?.deviceTokenForNotification ?? '',
        'is_active': UserDataStore.userData?.data?.user?.isActive ?? 'ACTIVE',
      },
    );

    try {
      final response = await http.post(
        Uri.parse(AppUrls.driverProfileUpdate),
        body: data,
        headers: {'Authorization': 'Bearer ${UserDataStore.accessToken}'},
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

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification updated successfully')),
            );
          }
        } else {
          throw Exception('Failed to update: status is false');
        }
      } else {
        throw Exception(
            'Failed to update notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showApiErrorPopup(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isNotifLoading = false);
      }
    }
  }

  // ─── LOGIC: logout ──────────────────────────────────────────────────────
  Future<void> _logout() async {
    await UserDataStore.clearAllData();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.numberInput,
        (route) => false,
      );
    }
  }
}
