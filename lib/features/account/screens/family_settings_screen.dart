import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/account/screens/daughter_report_screen.dart';

class FamilySettingsScreen extends StatefulWidget {
  const FamilySettingsScreen({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  State<FamilySettingsScreen> createState() => _FamilySettingsScreenState();
}

class _FamilySettingsScreenState extends State<FamilySettingsScreen> {
  final _phoneController = TextEditingController();
  List<dynamic> _links = [];
  bool _isLoading = true;
  bool _isInviting = false;
  String? _error;
  String? _success;
  String? _processingLinkId;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _roleLabel {
    final role = widget.storage.role;
    if (role == 'TEEN') return 'Parent';
    if (role == 'PARENT' || role == 'GUARDIAN') return 'Daughter';
    return 'Family Member';
  }

  bool get _isTeen => widget.storage.role == 'TEEN';

  Future<void> _fetchLinks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final res = await ApiService.instance.dio.get('/parent');
      if (mounted) {
        setState(() {
          _links = res.data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch family connections. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendInvite() async {
    final phone = _phoneController.value.text.trim();
    if (phone.isEmpty || phone.length < 10 || phone.length > 15) {
      setState(() => _error = 'Please enter a valid phone number (10-15 digits)');
      return;
    }

    setState(() {
      _isInviting = true;
      _error = null;
      _success = null;
    });

    try {
      await ApiService.instance.dio.post('/parent/invite', data: {'phone': phone});
      _phoneController.clear();
      _success = 'Invitation sent successfully to $phone!';
      await _fetchLinks();
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'] ?? 'Failed to send invite';
      setState(() => _error = serverError);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isInviting = false);
      }
    }
  }

  Future<void> _acceptInvite(String linkId) async {
    setState(() => _processingLinkId = linkId);
    try {
      await ApiService.instance.dio.post('/parent/accept/$linkId');
      _success = 'Linking invitation accepted!';
      await _fetchLinks();
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'] ?? 'Failed to accept invite';
      setState(() => _error = serverError);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _processingLinkId = null);
      }
    }
  }

  Future<void> _cancelOrDeclineInvite(String linkId, {bool isDecline = false}) async {
    setState(() => _processingLinkId = linkId);
    try {
      await ApiService.instance.dio.post('/parent/cancel/$linkId');
      _success = isDecline ? 'Invitation declined.' : 'Invitation cancelled.';
      await _fetchLinks();
    } on DioException catch (e) {
      final serverError = e.response?.data?['error'] ?? 'Failed to process invite';
      setState(() => _error = serverError);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _processingLinkId = null);
      }
    }
  }

  Future<void> _confirmUnlink(String linkId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Account?'),
        content: Text('Are you sure you want to unlink from $displayName? You will no longer share access to enrolled programs, sessions, or wellness progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelOrDeclineInvite(linkId, isDecline: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedAccounts = _links.where((l) => l['status'] == 'LINKED').toList();
    final pendingInvites = _links.where((l) => l['status'] == 'PENDING').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F7),
      appBar: AppBar(
        title: Text(
          'Family Settings',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.purple),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLinks,
        color: AppColors.purple,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 12),
                    if (_error != null) _buildAlertCard(_error!, isError: true),
                    if (_success != null) _buildAlertCard(_success!, isError: false),
                    if (_error != null || _success != null) const SizedBox(height: 12),
                    _buildLinkedAccounts(linkedAccounts),
                    const SizedBox(height: 12),
                    _buildPendingRequests(pendingInvites),
                    const SizedBox(height: 12),
                    _buildSendInviteSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, color: AppColors.purple, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Family Settings',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isTeen ? 'Connect with Parent' : 'Connect with Daughter',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isTeen
                ? 'Link your parent\'s account to share progress, sessions, and enrolled program details with them.'
                : 'Link your daughter\'s account to monitor her wellness journey, sessions, and program progress together.',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String message, {required bool isError}) {
    final bgColor = isError ? Colors.red[50] : Colors.green[50];
    final textColor = isError ? Colors.red[850] : Colors.green[850];
    final borderColor = isError ? Colors.red[200] : Colors.green[200];
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.transparent, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedAccounts(List<dynamic> linkedAccounts) {
    if (linkedAccounts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Linked $_roleLabel Account${linkedAccounts.length > 1 ? 's' : ''}',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: linkedAccounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final link = linkedAccounts[index];
              final otherUser = _isTeen ? link['parent'] : link['teen'];
              final displayNameRaw = otherUser?['profile']?['displayName']?.toString() ?? '';
              final displayName = displayNameRaw.trim().isEmpty ? 'Linked Account' : displayNameRaw;
              final displayPhone = otherUser?['phone'] ?? link['receiverPhone'] ?? '';
              final avatarUrl = otherUser?['profile']?['avatarUrl']?.toString();
              final teenId = link['teenId']?.toString();

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50]?.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100] ?? Colors.transparent, width: 1),
                ),
                child: Row(
                  children: [
                    // Profile photo or initial circle
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green[100],
                        border: Border.all(color: Colors.green[300] ?? Colors.green, width: 1.5),
                        image: avatarUrl != null && avatarUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green[800],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              fontSize: 13.5,
                            ),
                          ),
                          if (displayPhone.toString().isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              displayPhone,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (link['wellnessScore'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Wellness: ${link['wellnessScore']}%',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.purple,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: (link['wellnessScore'] as num) / 100.0,
                                      backgroundColor: Colors.grey[200],
                                      color: AppColors.purple,
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // For Parent user: Eye Icon to open Daughter Activity & Wellness Report Sheet
                    if (!_isTeen && teenId != null) ...[
                      Material(
                        color: Colors.transparent,
                        child: Tooltip(
                          message: 'View Activity & Wellness Report',
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DaughterReportScreen(
                                    teenId: teenId,
                                    daughterName: displayName,
                                    avatarUrl: avatarUrl,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.remove_red_eye_rounded,
                                size: 18,
                                color: AppColors.purple,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Icon-only Unlink Button
                    Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: 'Unlink Account',
                        child: InkWell(
                          onTap: () => _confirmUnlink(link['id'], displayName),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(
                              Icons.link_off_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequests(List<dynamic> pendingInvites) {
    if (pendingInvites.isEmpty) return const SizedBox.shrink();

    final userId = widget.storage.userId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                'Pending Invitations',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingInvites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final link = pendingInvites[index];
              final isSender = link['senderId'] == userId;
              final isProcessing = _processingLinkId == link['id'];

              if (isSender) {
                // Sent invitation (User is sender)
                final receiverUser = link['receiver'] ?? (link['teenId'] == userId ? link['parent'] : link['teen']);
                final displayNameRaw = receiverUser?['profile']?['displayName']?.toString() ??
                    receiverUser?['profile']?['fullName']?.toString() ??
                    receiverUser?['username']?.toString() ??
                    '';
                final displayPhone = link['receiverPhone'] ?? receiverUser?['phone'] ?? '';
                final displayName = displayNameRaw.trim().isNotEmpty
                    ? displayNameRaw
                    : (displayPhone.isNotEmpty ? displayPhone : (_isTeen ? 'Parent Invitation' : 'Daughter Invitation'));
                final avatarUrl = receiverUser?['profile']?['avatarUrl']?.toString();
                final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'F';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFDF5), Color(0xFFFEF3C7)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.outgoing_mail, size: 13, color: Color(0xFFB45309)),
                                const SizedBox(width: 5),
                                Text(
                                  'Sent Invitation',
                                  style: GoogleFonts.nunito(
                                    color: const Color(0xFFB45309),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pending',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Image.network(
                                      avatarUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 52,
                                        height: 52,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFDE68A),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.nunito(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFDE68A),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.nunito(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E1B4B),
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (displayPhone.isNotEmpty && displayPhone != displayName) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_iphone_rounded, size: 12, color: Color(0xFF92400E)),
                                        const SizedBox(width: 4),
                                        Text(
                                          displayPhone,
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF78350F),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Waiting for them to accept your invitation…',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB45309),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isProcessing ? null : () => _cancelOrDeclineInvite(link['id'], isDecline: false),
                            icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMedium),
                            label: isProcessing
                                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLight))
                                : Text(
                                    'Cancel Invitation',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              } else {
                // Received invitation (User is receiver e.g. Daughter receiving Parent invite)
                final senderUser = link['sender'] ?? (link['parentId'] == userId ? link['teen'] : link['parent']);
                final displayNameRaw = senderUser?['profile']?['displayName']?.toString() ??
                    senderUser?['profile']?['fullName']?.toString() ??
                    senderUser?['username']?.toString() ??
                    '';
                final displayPhone = senderUser?['phone'] ?? link['receiverPhone'] ?? '';
                final displayName = displayNameRaw.trim().isNotEmpty
                    ? displayNameRaw
                    : (displayPhone.isNotEmpty ? displayPhone : (_isTeen ? 'Parent Link Request' : 'Daughter Link Request'));
                final avatarUrl = senderUser?['profile']?['avatarUrl']?.toString();
                final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'P';
                final roleBadgeText = _isTeen ? 'Parent Request' : 'Daughter Request';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFCF9FF), Color(0xFFF3E8FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.family_restroom_rounded, size: 14, color: AppColors.purple),
                                const SizedBox(width: 5),
                                Text(
                                  roleBadgeText,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Action Required',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Photo
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(27),
                                    child: Image.network(
                                      avatarUrl,
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 54,
                                        height: 54,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE9D5FF),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.nunito(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.purple,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE9D5FF),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.nunito(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1E1B4B),
                                    fontSize: 16.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (displayPhone.isNotEmpty && displayPhone != displayName) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFDDD6FE), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_iphone_rounded, size: 12, color: AppColors.purple),
                                        const SizedBox(width: 4),
                                        Text(
                                          displayPhone,
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF5B21B6),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  'Wants to link accounts with you on Infano Care',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B7280),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9D5FF), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.purple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Linking lets you stay connected and share wellness progress with care.',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing ? null : () => _cancelOrDeclineInvite(link['id'], isDecline: true),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.red.shade200),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              child: Text(
                                'Decline',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: isProcessing ? null : () => _acceptInvite(link['id']),
                              icon: isProcessing
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                              label: isProcessing
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      'Accept Link Request',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.purple,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSendInviteSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link a $_roleLabel',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter their registered phone number to send a link invitation.',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 9876543210',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isInviting ? null : _sendInvite,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isInviting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.add, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Send Invite',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
