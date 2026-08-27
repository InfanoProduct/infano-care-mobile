import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/app_sound_service.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';

class PeerSessionHelper {
  static PeerLineSession? findActiveSession(
    Map<String, dynamic> mentor,
    List<PeerLineSession> sessions,
  ) {
    final mentorId = (mentor['id'] as String?)?.trim() ?? '';
    final mentorName = (mentor['name'] as String? ?? mentor['fullName'] as String? ?? '').trim().toLowerCase();
    final serverSessionId = mentor['sessionId'] as String?;
    final bool serverActive = mentor['hasActiveSession'] == true;

    for (final s in sessions) {
      final sMentorId = (s.mentorId ?? '').trim();
      final sMenteeId = (s.menteeId).trim();
      final sMentorName = (s.mentorName ?? '').trim().toLowerCase();
      final sId = s.id;

      final bool idMatch = mentorId.isNotEmpty && (sMentorId == mentorId || sMenteeId == mentorId);
      final bool nameMatch = mentorName.isNotEmpty &&
          (sMentorName == mentorName ||
              sMentorName.contains(mentorName) ||
              mentorName.contains(sMentorName));
      final bool serverIdMatch = serverSessionId != null && serverSessionId == sId;

      final bool isOngoing = s.status.toLowerCase() == 'active' ||
          s.messages.isNotEmpty ||
          (s.startedAt != null && s.status.toLowerCase() != 'cancelled');

      if ((idMatch || nameMatch || serverIdMatch) && isOngoing) {
        return s;
      }
    }

    if (serverActive && serverSessionId != null && serverSessionId.isNotEmpty) {
      return PeerLineSession(
        id: serverSessionId,
        menteeId: '',
        topicIds: [],
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        messages: [],
      );
    }

    return null;
  }

  static PeerLineSession? findPendingSession(
    Map<String, dynamic> mentor,
    List<PeerLineSession> sessions,
  ) {
    final mentorId = (mentor['id'] as String?)?.trim() ?? '';
    final mentorName = (mentor['name'] as String? ?? mentor['fullName'] as String? ?? '').trim().toLowerCase();
    final bool serverPending = mentor['hasPendingRequest'] == true;

    for (final s in sessions) {
      final sMentorId = (s.mentorId ?? '').trim();
      final sMenteeId = (s.menteeId).trim();
      final sMentorName = (s.mentorName ?? '').trim().toLowerCase();
      final bool idMatch = mentorId.isNotEmpty && (sMentorId == mentorId || sMenteeId == mentorId);
      final bool nameMatch = mentorName.isNotEmpty &&
          (sMentorName == mentorName ||
              sMentorName.contains(mentorName) ||
              mentorName.contains(sMentorName));

      final bool isPending = s.status.toLowerCase() == 'matching' || s.status.toLowerCase() == 'queued';

      if ((idMatch || nameMatch) && isPending) {
        return s;
      }
    }

    if (serverPending) {
      return PeerLineSession(
        id: (mentor['sessionId'] as String?) ?? '',
        menteeId: '',
        topicIds: [],
        status: 'MATCHING',
        createdAt: DateTime.now(),
        messages: [],
      );
    }

    return null;
  }
}

class PeerMentorDetailSheet {
  static const Color purpleTheme = Color(0xFF644D95);

  static void show({
    required BuildContext context,
    required Map<String, dynamic> mentor,
    bool? hasChat,
    bool? isPending,
    List<PeerLineSession> sessions = const [],
    PeerLineSession? activeSession,
    PeerLineSession? pendingSession,
    required Future<void> Function(Map<String, dynamic> mentor) onAction,
  }) {
    final resolvedActiveSession = activeSession ?? PeerSessionHelper.findActiveSession(mentor, sessions);
    final resolvedPendingSession = pendingSession ?? PeerSessionHelper.findPendingSession(mentor, sessions);
    final bool resolvedHasChat = hasChat ?? (resolvedActiveSession != null);
    final bool resolvedIsPending = isPending ?? (resolvedPendingSession != null && !resolvedHasChat);

    AppSoundService.instance.playPop();

    final List<Color> pastelColors = const [
      Color(0xFFF7EFF5),
      Color(0xFFF4EAF1),
      Color(0xFFFAF2F7),
      Color(0xFFF5ECF3),
    ];
    final mentorId = (mentor['id'] as String?) ?? '';
    final cardBg = pastelColors[mentorId.hashCode.abs() % pastelColors.length];

    final rawBadges = mentor['topics'] ?? mentor['certifiedTopicIds'] ?? [];
    final List<String> badges = (rawBadges is List)
        ? rawBadges
            .map<String>((b) => b is Map ? (b['name']?.toString() ?? '') : b.toString())
            .where((s) => s.isNotEmpty)
            .toList()
        : ['Mental & Emotional Health'];

    final name = mentor['name'] ?? mentor['fullName'] ?? 'Peer Mentor';
    final fullName = mentor['fullName'] ?? mentor['name'] ?? 'Peer Mentor';
    final initial = (mentor['initial'] as String?) ??
        (name.toString().isNotEmpty ? name.toString().substring(0, 1).toUpperCase() : 'P');
    
    final headline = (mentor['headline'] as String?)?.isNotEmpty == true
        ? (mentor['headline'] as String)
        : (badges.isNotEmpty
            ? 'Certified Peer Listener & ${badges.first} Coach'
            : 'Certified Peer Listener & Emotional Health Coach');
            
    final rating = (mentor['rating']?.toString()) ?? '5.0';
    final reviewsCount = mentor['reviewsCount'] ?? '48 reviews';
    final sessionsCount = mentor['sessionsCount'] ?? '50+ Mentees';
    final responseTime = mentor['responseTime'] ?? '< 15 mins';
    final languages = mentor['languages'] ?? 'English, Hindi';
    final fullBio = mentor['fullBio'] ?? mentor['bio'] ?? 'Hi there! I am here to help you feel supported and heard.';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MentorDetail',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: const Color(0xFFB48BA6).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB48BA6).withValues(alpha: 0.25),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 22,
                  right: 22,
                  top: 14,
                  bottom: MediaQuery.of(ctx).padding.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Pill Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB48BA6).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Avatar + Name + Headline + Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: purpleTheme.withValues(alpha: 0.25),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: purpleTheme.withValues(alpha: 0.15),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: GoogleFonts.nunito(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: purpleTheme,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 3,
                                right: 3,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        fullName,
                                        style: GoogleFonts.nunito(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF1E1B4B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: Color(0xFF059669),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  headline,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Color(0xFFF59E0B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$rating ($reviewsCount)',
                                            style: GoogleFonts.nunito(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFB45309),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        sessionsCount,
                                        style: GoogleFonts.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFE2D4DE), thickness: 1.5),
                      const SizedBox(height: 14),

                      // Specialties & Topics Section
                      Text(
                        'SPECIALTIES & TOPICS',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF7A61AC),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: badges.map((badgeText) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: purpleTheme.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: purpleTheme,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // About Mentor Section
                      Text(
                        'ABOUT MENTOR',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF7A61AC),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fullBio,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Metadata Tags (Response Time & Languages)
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Responds in $responseTime',
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.translate_rounded,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                languages,
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Bottom Unified Action CTA Button
                      Builder(
                        builder: (btnContext) {
                          final String ctaText = resolvedHasChat
                              ? 'Start Chat'
                              : (resolvedIsPending ? 'Request Sent' : 'Chat Request');
                          final IconData ctaIcon = resolvedHasChat
                              ? Icons.chat_bubble_rounded
                              : (resolvedIsPending ? Icons.hourglass_empty_rounded : Icons.send_rounded);

                          return GestureDetector(
                            onTap: resolvedIsPending
                                ? null
                                : () async {
                                    if (Navigator.canPop(ctx)) {
                                      Navigator.pop(ctx);
                                    }
                                    if (resolvedHasChat && resolvedActiveSession != null) {
                                      context.push('/peerline/chat/${resolvedActiveSession.id}');
                                    } else {
                                      await onAction(mentor);
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: resolvedHasChat
                                      ? const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]
                                      : (resolvedIsPending
                                          ? [Colors.grey.shade400, Colors.grey.shade500]
                                          : const [Color(0xFF7A61AC), purpleTheme]),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (resolvedHasChat
                                            ? const Color(0xFF7C3AED)
                                            : (resolvedIsPending ? Colors.grey : purpleTheme))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    ctaIcon,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    ctaText,
                                    style: GoogleFonts.nunito(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
