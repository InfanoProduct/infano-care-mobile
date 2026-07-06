import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';

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
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 22),
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
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
                    if (_error != null) _buildAlertCard(_error!, isError: true),
                    if (_success != null) _buildAlertCard(_success!, isError: false),
                    if (_error != null || _success != null) const SizedBox(height: 20),
                    _buildLinkedAccounts(linkedAccounts),
                    const SizedBox(height: 20),
                    _buildPendingRequests(pendingInvites),
                    const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link, color: AppColors.purple, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Family Settings',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isTeen ? 'Connect with Parent' : 'Connect with Daughter',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isTeen
                ? 'Link your parent\'s account to share progress, sessions, and enrolled program details with them.'
                : 'Link your daughter\'s account to monitor her wellness journey, sessions, and program progress together.',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
              fontSize: 13,
              height: 1.4,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Linked $_roleLabel Account${linkedAccounts.length > 1 ? 's' : ''}',
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
            itemCount: linkedAccounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final link = linkedAccounts[index];
              final otherUser = _isTeen ? link['parent'] : link['teen'];
              final displayNameRaw = otherUser?['profile']?['displayName']?.toString() ?? '';
              final displayName = displayNameRaw.trim().isEmpty ? 'Linked Account' : displayNameRaw;
              final displayPhone = otherUser?['phone'] ?? link['receiverPhone'] ?? '';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50]?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[100] ?? Colors.transparent, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          displayName.toString().substring(0, 1).toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: Colors.green[800],
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                          if (displayPhone.toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              displayPhone,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _confirmUnlink(link['id'], displayName),
                      icon: const Icon(Icons.link_off, size: 14, color: Colors.red),
                      label: Text(
                        'Unlink',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[100] ?? Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                // Sent invitation
                final displayPhone = link['receiverPhone'] ?? '';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50]?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[100] ?? Colors.transparent, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.orange, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayPhone,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Waiting for them to accept…',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[750],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: isProcessing ? null : () => _cancelOrDeclineInvite(link['id'], isDecline: false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300] ?? Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        child: isProcessing
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLight))
                            : Text(
                                'Cancel',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  color: AppColors.textMedium,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              } else {
                // Received invitation (User is accepter)
                final senderUser = link['sender'];
                final displayNameRaw = senderUser?['profile']?['displayName']?.toString() ?? '';
                final displayName = displayNameRaw.trim().isEmpty ? 'Family Link Request' : displayNameRaw;
                final displayPhone = senderUser?['phone'] ?? link['receiverPhone'] ?? '';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.family_restroom, color: AppColors.purple, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                    fontSize: 13,
                                  ),
                                ),
                                if (displayPhone.toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    displayPhone,
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isProcessing ? null : () => _cancelOrDeclineInvite(link['id'], isDecline: true),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red[200] ?? Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: isProcessing ? null : () => _acceptInvite(link['id']),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: isProcessing
                                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    'Accept Link',
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
