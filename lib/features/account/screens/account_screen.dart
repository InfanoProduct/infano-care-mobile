import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/notification_service.dart';
import 'package:infano_care_mobile/features/auth/repository/auth_repository.dart';
import 'package:infano_care_mobile/features/creative_journey/widgets/creative_certificate_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _uploadError;
  List<CreativeCertificate> _certificates = [];
  bool _isLoadingCerts = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
    _syncProfile();
  }

  Future<void> _loadCertificates() async {
    try {
      final certs = await CreativeCertificateService.getCertificates();
      if (mounted) {
        setState(() {
          _certificates = certs;
          _isLoadingCerts = false;
        });
      }
    } catch (e) {
      debugPrint('[AccountScreen] Certificates load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingCerts = false;
        });
      }
    }
  }

  Future<void> _syncProfile() async {
    try {
      final repo = AuthRepository(widget.storage);
      await repo.syncProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[AccountScreen] Profile sync failed: $e');
    }
  }

  Future<void> _pickAndCropAvatar() async {
    setState(() {
      _uploadError = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: AppColors.purple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            activeControlsWidgetColor: AppColors.purple,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
            resetButtonHidden: false,
            aspectRatioPickerButtonHidden: true,
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile != null) {
        await _uploadAvatar(File(croppedFile.path));
      }
    } catch (e) {
      debugPrint('[AccountScreen] Error picking/cropping: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar(File file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await ApiService.instance.dio.post(
        '/user/profile/avatar',
        data: formData,
      );

      if (response.data != null && response.data['success'] == true) {
        final avatarUrl = response.data['avatarUrl'] as String;
        await widget.storage.setAvatarUrl(avatarUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully!')),
          );
        }
      } else {
        throw Exception('Failed to save avatar url');
      }
    } on DioException catch (e) {
      final errMsg = e.response?.data?['error'] ?? 'Server error during upload';
      setState(() {
        _uploadError = errMsg;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $errMsg')),
        );
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAF5FF),
          appBar: AppBar(
            title: const Text(
              'Account Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.5,
            foregroundColor: AppColors.textDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildCertificatesSection(context),
                  const SizedBox(height: 20),
                  _buildInfoSection(context),
                  const SizedBox(height: 20),
                  _buildNavigationSection(context),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificatesSection(BuildContext context) {
    final hasCert = _certificates.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA78BFA).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🎓', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Graduation Certificates',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4C1D95),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      hasCert
                          ? '${_certificates.length} Official Certificate${_certificates.length > 1 ? 's' : ''} Earned'
                          : 'Complete Journeys to Earn Certificates',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasCert ? '🏆 ACTIVE' : '✨ PREVIEW',
                  style: GoogleFonts.nunito(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5B21B6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasCert) ...[
            ..._certificates.map((cert) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        CreativeCertificateDialog.show(context, certificate: cert);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Row(
                          children: [
                            const Text('📜', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cert.journeyTitle,
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF4C1D95),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Issued ${cert.issueDate} • ${cert.totalEpisodes} Episodes',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDE9FE)),
              ),
              child: Row(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete all episodes in a Creative Journey to claim your signed certificate!',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B21B6),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      CreativeCertificateDialog.show(
                        context,
                        certificate: CreativeCertificate(
                          id: 'INF-CERT-PREVIEW',
                          journeyId: 'cj_my_changing_body',
                          journeyTitle: 'My Changing Body',
                          recipientName: widget.storage.displayName ?? 'Young Explorer',
                          issueDate: 'August 2026',
                          totalEpisodes: 6,
                          totalNodes: 58,
                          gigiQuote: 'Embrace your unique growth with courage, body gratitude, and wisdom!',
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Preview',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatarUrl = widget.storage.avatarUrl;
    final hasValidAvatar = avatarUrl != null &&
        avatarUrl.trim().isNotEmpty &&
        avatarUrl.trim() != 'null' &&
        (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://'));
    final displayName = (widget.storage.displayName?.trim().isNotEmpty == true)
        ? widget.storage.displayName!
        : 'Infano Member';
    final phone = (widget.storage.phone?.trim().isNotEmpty == true)
        ? widget.storage.phone!
        : (widget.storage.pronouns?.trim().isNotEmpty == true
            ? widget.storage.pronouns!
            : 'Welcome to Infano.Care');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndCropAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDDD6FE), width: 3),
                  ),
                  child: ClipOval(
                    child: hasValidAvatar
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.purple,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('🌸', style: TextStyle(fontSize: 38)),
                              );
                            },
                          )
                        : const Center(
                            child: Text('🌸', style: TextStyle(fontSize: 38)),
                          ),
                  ),
                ),
                if (_isUploading)
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (!_isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (_uploadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _uploadError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final uid = widget.storage.userId;
    final displayUid = (uid != null && uid.isNotEmpty)
        ? (uid.length >= 8 ? uid.substring(0, 8) : uid)
        : 'N/A';
    final role = widget.storage.role ?? 'MEMBER';
    final roleLabel = role == 'TEEN'
        ? 'Teen Member'
        : (role == 'PARENT' || role == 'GUARDIAN'
            ? 'Parent Care'
            : (role == 'EXPERT' ? 'Expert Partner' : 'Bloom Member'));

    final birthday = (widget.storage.birthMonth != null && widget.storage.birthYear != null)
        ? '${widget.storage.birthMonth}/${widget.storage.birthYear}'
        : 'Not set';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.stars_rounded, 'Points Earned', '${widget.storage.points} ✨'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.verified_user_outlined, 'User ID', displayUid),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.badge_outlined, 'Account Type', roleLabel),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInfoRow(Icons.cake_outlined, 'Birthday', birthday),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNavRow(
            context,
            icon: Icons.family_restroom_rounded,
            label: 'Family & Linked Accounts',
            route: '/account/family',
            iconColor: const Color(0xFF8B5CF6),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildNavRow(
            context,
            icon: Icons.bookmark_outline_rounded,
            label: 'My Library',
            route: '/account/saved',
            iconColor: const Color(0xFFEC4899),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildNavRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'Location & GPS Settings',
            route: '/safety/location',
            iconColor: const Color(0xFF10B981),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildNavRow(
            context,
            icon: Icons.notifications_none_rounded,
            label: 'Notification Preferences',
            route: '/account/notifications',
            iconColor: const Color(0xFFF59E0B),
          ),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _buildNavRow(
            context,
            icon: Icons.settings_outlined,
            label: 'Settings & Privacy',
            route: '/settings',
            iconColor: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    Color iconColor = AppColors.purple,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: AppColors.textDark,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Color(0xFF94A3B8),
      ),
      onTap: () => context.push(route),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.purple, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        label: Text(
          'Logout Session',
          style: GoogleFonts.nunito(
            color: AppColors.error,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFFECDD3), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout?',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to sign out? Your progress is saved safely.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(color: AppColors.textMedium, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.nunito(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService().unregisterToken();
      } catch (e) {
        debugPrint('Logout: Could not unregister FCM token: $e');
      }

      await widget.storage.clearAll();
      if (context.mounted) {
        context.go('/splash');
      }
    }
  }
}
