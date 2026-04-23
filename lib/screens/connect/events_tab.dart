import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/models/event.dart';
import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/widgets/event_card.dart';
import 'package:infano_care_mobile/widgets/challenge_banner.dart';
import 'package:infano_care_mobile/screens/connect/live_event_screen.dart';
import 'package:provider/provider.dart';

class EventsTab extends StatefulWidget {
  const EventsTab({Key? key}) : super(key: key);

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> with SingleTickerProviderStateMixin {
  late CommunityApi _api;
  late Future<List<CommunityEvent>> _upcomingEventsFuture;
  late Future<List<CommunityEvent>> _liveEventsFuture;
  late Future<List<CommunityEvent>> _pastEventsFuture;
  late Future<WeeklyChallenge> _challengeFuture;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _api = Provider.of<CommunityApi>(context, listen: false);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _refreshData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() {
      _upcomingEventsFuture = _api.getCommunityEvents(status: 'upcoming');
      _liveEventsFuture = _api.getCommunityEvents(status: 'live');
      _pastEventsFuture = _api.getCommunityEvents(status: 'past');
      _challengeFuture = _api.getWeeklyChallenge();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildLiveBannerSection(),
          _buildWeeklyChallengeSection(),
          _buildCulturalCalendar(),
          const SizedBox(height: 32),
          _buildSectionHeader('Live & Upcoming', Icons.event_available),
          const SizedBox(height: 16),
          _buildEventsList(_liveEventsFuture, isLive: true),
          _buildEventsList(_upcomingEventsFuture),
          const SizedBox(height: 32),
          _buildSectionHeader('Past Events (Archive)', Icons.history),
          const SizedBox(height: 16),
          _buildPastEventsSection(),
        ],
      ),
    );
  }

  Widget _buildLiveBannerSection() {
    return FutureBuilder<List<CommunityEvent>>(
      future: _liveEventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final liveEvent = snapshot.data!.first;
        
        return FadeTransition(
          opacity: Tween(begin: 0.6, end: 1.0).animate(_pulseController),
          child: GestureDetector(
            onTap: () => _openLiveEvent(liveEvent),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE NOW',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12),
                        ),
                        Text(
                          liveEvent.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChallengeSection() {
    return FutureBuilder<WeeklyChallenge>(
      future: _challengeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return ChallengeBanner(
          challenge: snapshot.data!,
          onTap: () {
            // Tapping opens the challenge tab in first available circle
          },
        );
      },
    );
  }

  Widget _buildCulturalCalendar() {
    final days = [
      {'emoji': '🩺', 'name': 'World Health Day', 'date': 'Apr 7'},
      {'emoji': '🌍', 'name': 'Earth Day', 'date': 'Apr 22'},
      {'emoji': '🎨', 'name': 'Art Awareness', 'date': 'May 1'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cultural Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMedium),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Text(day['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(day['date']!, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.purple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
      ],
    );
  }

  Widget _buildEventsList(Future<List<CommunityEvent>> future, {bool isLive = false}) {
    return FutureBuilder<List<CommunityEvent>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final events = snapshot.data!;
        return Column(
          children: events.map((event) => EventCard(
            event: event,
            onTap: () => _openLiveEvent(event),
          )).toList(),
        );
      },
    );
  }

  Widget _buildPastEventsSection() {
    return FutureBuilder<List<CommunityEvent>>(
      future: _pastEventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const Text('No past events yet.', style: TextStyle(color: Colors.grey));

        return Column(
          children: events.map((event) => _buildArchivedEventCard(event)).toList(),
        );
      },
    );
  }

  Widget _buildArchivedEventCard(CommunityEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.shade100.withOpacity(0.3)),
            ),
            child: Icon(Icons.history, color: Colors.blueGrey.shade300),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.question_answer_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${event.questionCount} Qs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.visibility_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${event.viewCount} views', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  void _openLiveEvent(CommunityEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveEventScreen(event: event),
      ),
    );
  }
}
