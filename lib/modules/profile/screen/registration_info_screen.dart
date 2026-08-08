import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/localization/app_localization.dart';
import '../../../../routes/app_routes.dart';
import '../../../../store/user_data_store.dart';
import '../../../../utils/to_title_case.dart';
import '../../../../utils/app_urls.dart';
import '../repository/personal_info_repository.dart';
import '../repository/car_photo_repository.dart';

class RegistrationInfoScreen extends StatefulWidget {
  const RegistrationInfoScreen({super.key});

  @override
  State<RegistrationInfoScreen> createState() => _RegistrationInfoScreenState();
}

class _RegistrationInfoScreenState extends State<RegistrationInfoScreen> {
  bool _isLoading = true;
  List<dynamic> _documents = [];
  List<dynamic> _carPhotos = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final docs = await PersonalInfoRepository().getDriverDocumentList();
      final photoRes = await CarPhotoRepository().getCarPhotoList();
      final photos = photoRes != null ? photoRes['data'] as List<dynamic>? ?? [] : [];

      if (mounted) {
        setState(() {
          _documents = docs ?? [];
          _carPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool get _isPersonalInfoVerified {
    if (_documents.isEmpty) return false;

    final personalTypes = [
      'NID_FRONT_COPY',
      'NID_BACK_COPY',
      'LICENSE_FONT_COPY',
      'LICENSE_FRONT_COPY',
      'LICENSE_BACK_COPY',
    ];

    final personalDocs = _documents.where((doc) {
      final type = doc['document_type'] ?? '';
      return personalTypes.contains(type);
    }).toList();

    if (personalDocs.isEmpty) return false;

    for (var doc in personalDocs) {
      if (doc['is_verified']?.toString().toUpperCase() != 'ACTIVE') {
        return false;
      }
    }
    return true;
  }

  bool get _isCarInfoVerified {
    if (_documents.isEmpty) return false;

    final carTypes = [
      'VEHICLE_REGISTRATION_SMART_CARD_COPY',
      'VEHICLE_TAX_FONT_COPY',
      'VEHICLE_TAX_FRONT_COPY',
      'VEHICLE_TAX_BACK_COPY',
      'VEHICLE_FITNESS_CERTIFICATE_FONT_COPY',
      'VEHICLE_FITNESS_CERTIFICATE_FRONT_COPY',
      'VEHICLE_FITNESS_CERTIFICATE_BACK_COPY',
    ];

    final carDocs = _documents.where((doc) {
      final type = doc['document_type'] ?? '';
      return carTypes.contains(type);
    }).toList();

    if (carDocs.isEmpty) return false;

    for (var doc in carDocs) {
      if (doc['is_verified']?.toString().toUpperCase() != 'ACTIVE') {
        return false;
      }
    }
    return true;
  }

  bool get _isCarPhotoVerified {
    if (_carPhotos.isEmpty) return false;

    final requiredPhotoTypes = ['FRONT', 'BACK', 'LEFT', 'RIGHT', 'CAR_SET'];
    final existingTypes = _carPhotos.map((p) => p['document_type']?.toString().toUpperCase() ?? '').toList();

    for (var type in requiredPhotoTypes) {
      if (!existingTypes.contains(type)) {
        return false;
      }
    }

    for (var photo in _carPhotos) {
      if (photo['is_verified']?.toString().toUpperCase() != 'ACTIVE') {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = UserDataStore.userData?.data?.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fallbacks
    final status = user?.isActive ?? 'INACTIVE';

    // Status mapping for header
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status.toString().toUpperCase()) {
      case 'ACTIVE':
        statusColor = Colors.green;
        statusLabel = loc.translate("active") ?? "Active";
        statusIcon = Icons.verified_user_rounded;
        break;
      case 'PROGRESS':
        statusColor = Colors.orange;
        statusLabel = loc.translate("under_review") ?? "Under Review";
        statusIcon = Icons.pending_actions_rounded;
        break;
      default:
        statusColor = Colors.redAccent;
        statusLabel = loc.translate("inactive") ?? "Inactive";
        statusIcon = Icons.error_outline_rounded;
    }

    return Scaffold(
      backgroundColor: isDark 
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate("registration_info") ?? "Registration Info",
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchDocuments,
                color: Theme.of(context).colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Status Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                  : [Colors.white, const Color(0xFFF8FAFC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.translate("status") ?? 'Account Status',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(statusIcon, color: statusColor, size: 20),
                                        const SizedBox(width: 6),
                                        Text(
                                          statusLabel,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      status.toString().toUpperCase() == 'ACTIVE'
                                          ? 'Your profile is approved. You are ready to accept trips!'
                                          : 'We are verifying your documents. This usually takes 24 hours.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Checklist Section Title
                        Text(
                          'Verification Checklist',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 1: Personal Info
                        _buildRegistrationCard(
                          context: context,
                          icon: Icons.person_rounded,
                          title: loc.translate("personal_info") ?? "Personal Info",
                          subtitle: "Driver name, NID card and Driving license copies",
                          isVerified: _isPersonalInfoVerified,
                          isWarning: !_isPersonalInfoVerified,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.personalInfo).then((_) => _fetchDocuments()),
                        ),
                        
                        // Card 2: Car Info
                        _buildRegistrationCard(
                          context: context,
                          icon: Icons.directions_car_rounded,
                          title: loc.translate("car_info") ?? "Car Info",
                          subtitle: "Registration, tax token and fitness certificate documents",
                          isVerified: _isCarInfoVerified,
                          isWarning: !_isCarInfoVerified,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.carInfo).then((_) => _fetchDocuments()),
                        ),
                        
                        // Card 3: Car Photo
                        _buildRegistrationCard(
                          context: context,
                          icon: Icons.local_taxi_rounded,
                          title: loc.translate("car_photo") ?? "Car Photo",
                          subtitle: "External image copy of the registered vehicle",
                          isVerified: _isCarPhotoVerified,
                          isWarning: !_isCarPhotoVerified,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.carPhoto).then((_) => _fetchDocuments()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRegistrationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    required bool isWarning,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color itemBorderColor;
    Color iconBgColor;
    Color iconColor;
    Widget? statusBadge;

    if (isVerified) {
      itemBorderColor = Colors.green.withOpacity(0.2);
      iconBgColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 14),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    } else if (isWarning) {
      itemBorderColor = Colors.red.withOpacity(0.2);
      iconBgColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 14),
            const SizedBox(width: 4),
            Text(
              'Action Needed',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      itemBorderColor = theme.colorScheme.outlineVariant.withOpacity(0.3);
      iconBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE);
      iconColor = const Color(0xFF1A73E8);
      statusBadge = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: itemBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Row(
              children: [
                // Left Icon with dynamic color scheme matching completion state
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Completion badge
                if (statusBadge != null) statusBadge,
                const SizedBox(width: 8),
                // Trailing Arrow icon shown for ALL tabs
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
