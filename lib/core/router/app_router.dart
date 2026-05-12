import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/screens/phone_entry_screen.dart';
import 'package:infano_care_mobile/features/auth/screens/otp_verify_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/landing_screen.dart';
import 'package:infano_care_mobile/features/account/screens/account_screen.dart';
import 'package:infano_care_mobile/features/account/screens/notification_preferences_screen.dart';
import 'package:infano_care_mobile/features/account/screens/data_rights_privacy_screen.dart';
import 'package:infano_care_mobile/features/account/screens/saved_articles_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/path_selector_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/name_pronouns_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_topic_selection_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_results_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_chat_screen.dart';
import 'package:infano_care_mobile/screens/connect/friend_chat_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/birthday_input_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/parental_consent_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/consent_waiting_screen.dart';
import 'package:infano_care_mobile/screens/connect/circle_screen.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/features/onboarding/screens/assent_terms_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/goals_selection_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/period_comfort_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/period_experience_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/interest_topics_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/avatar_builder_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/journey_name_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/welcome_world_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/last_period_date_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/cycle_details_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/tracker_activated_screen.dart';
import 'package:infano_care_mobile/features/home/screens/dashboard_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/doctor_summary_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/cycle_insights_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/cycle_settings_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/first_period_celebration_screen.dart';
import 'package:infano_care_mobile/features/home/screens/track_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/calendar_screen.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/bloc/calendar_cubit.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/quest_repository.dart';
import 'package:infano_care_mobile/features/tracker/bloc/quest_bloc.dart';
import 'package:infano_care_mobile/features/home/screens/quest_screen.dart';

// Gigi & Expert Imports
import 'package:infano_care_mobile/features/chat/screens/chat_screen.dart';
import 'package:infano_care_mobile/features/chat/data/chat_repository.dart';
import 'package:infano_care_mobile/features/chat/bloc/chat_bloc.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_dashboard_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_list_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_chat_screen.dart';

// Learning Journey Imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/learning/repositories/learning_repository.dart';
import 'package:infano_care_mobile/features/learning/application/journey_list_bloc.dart';
import 'package:infano_care_mobile/features/learning/application/journey_detail_bloc.dart';
import 'package:infano_care_mobile/features/learning/application/episode_player_bloc.dart';
import 'package:infano_care_mobile/features/learning/screens/journey_explorer_screen.dart';
import 'package:infano_care_mobile/features/learning/screens/journey_detail_screen.dart';
import 'package:infano_care_mobile/features/learning/screens/episode_player_screen.dart';
import 'package:infano_care_mobile/features/learning/models/learning_models.dart';

String getRouteForStep(String step, {String? periodStatus}) {
  final routes = {
    '0':  '/onboarding/path',
    '1':  '/onboarding/name',
    '2':  '/onboarding/birthday',
    '3':  '/onboarding/consent/send',
    '4':  '/onboarding/goals',
    '5':  '/onboarding/period-comfort',
    '6':  '/onboarding/period-status',
    '7':  '/onboarding/interests',
    '8':  '/onboarding/avatar',
    '9':  '/onboarding/journey-name',
    '10': '/onboarding/terms',
    '11': '/onboarding/tracker/date',
    '12': '/onboarding/tracker/details',
  };

  // Conditional skip: If period status is not active, skip tracker setup (11, 12)
  if (periodStatus != null && periodStatus != 'active') {
    if (step == '11' || step == '12') {
      return '/home';
    }
  }

  return routes[step] ?? '/onboarding/path';
}

// Expert creation helper functions...

GoRouter createRouter(LocalStorageService storage) {
  final chatRepo = ChatRepository(ApiService.instance);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: storage,
    debugLogDiagnostics: true, // Enable logs for easier debugging of redirects
    redirect: (context, state) {
      final token = storage.authToken;
      final role = storage.role;
      final tempToken = storage.tempToken;
      final step = storage.stepComplete;
      final path = state.uri.path;

      final onAuth = path.startsWith('/auth') || path == '/splash';

      // 1. Not Authenticated
      if (token == null) {
        if (tempToken != null) {
          if (path.startsWith('/onboarding') || onAuth) return null;
          return '/onboarding/path';
        }
        // No tokens: allow auth/splash, otherwise force splash (Landing Page)
        if (onAuth) return null;
        return '/splash';
      }

      // 2. Expert Redirect
      if (role == 'EXPERT') {
        if (path == '/home' || path == '/splash' || path.startsWith('/onboarding')) {
          return '/expert/dashboard';
        }
        return null; // Let them access expert routes
      }

      // 3. Authenticated (token != null)
      final bool onOnboarding = path.startsWith('/onboarding');
      // step is already declared above via storage.stepComplete

      // OPTIMIZATION: If fully onboarded, jump to home immediately
      if (storage.isOnboarded) {
        if (onAuth || (onOnboarding && !path.contains('tracker'))) return '/home';
        return null;
      }

      // 4. Authenticated but NOT Onboarded
      if (path == '/splash' || path == '/auth/otp' || path == '/auth/phone') {
        // After login, send them to their next step
        return getRouteForStep(step ?? '0', periodStatus: storage.periodStatus);
      }

      if (!storage.isOnboarded) {
        // Enforce onboarding flow
        final target = getRouteForStep(step ?? '0', periodStatus: storage.periodStatus);
        
        if (path != target && !path.contains('tracker') && !path.contains('expert') && path != '/onboarding/welcome' && path != '/chat') {
          if (!onOnboarding) return target;
          if (path == '/home' || path == '/account') return target;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, _) => const LandingScreen()),
      GoRoute(path: '/account',  builder: (_, _) => AccountScreen(storage: storage)),
      GoRoute(path: '/account/notifications', builder: (_, _) => const NotificationPreferencesScreen()),
      GoRoute(path: '/account/data-rights', builder: (_, _) => const DataRightsPrivacyScreen()),
      GoRoute(path: '/account/saved', builder: (_, _) => const SavedArticlesScreen()),
      
      // Expert Dashboard
      GoRoute(path: '/expert/dashboard', builder: (_, _) => ExpertDashboardScreen(storage: storage)),
      
      // Expert Chat
      GoRoute(path: '/expert/list', builder: (_, _) => ExpertListScreen(storage: storage)),
      GoRoute(
        path: '/expert/chat/:sessionId', 
        builder: (_, state) {
          final expertName = (state.extra as Map?)?['expertName'] ?? 'Expert';
          return ExpertChatScreen(
            sessionId: state.pathParameters['sessionId']!,
            expertName: expertName,
            storage: storage,
          );
        },
      ),

      // Gigi assistant
      GoRoute(
        path: '/chat',
        builder: (_, _) => BlocProvider(
          create: (context) => ChatBloc(chatRepo)..add(LoadSessions()),
          child: const ChatScreen(),
        ),
      ),

      // Auth (Phone + OTP)
      GoRoute(
        path: '/auth/phone',
        builder: (_, state) => PhoneEntryScreen(
          storage: storage,
          fromOnboarding: state.uri.queryParameters['fromOnboarding'] == 'true',
        ),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpVerifyScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
          storage: storage,
          fromOnboarding: state.uri.queryParameters['fromOnboarding'] == 'true',
        ),
      ),

      // Onboarding
      GoRoute(path: '/onboarding/path',           builder: (_, _) => const PathSelectorScreen()),
      GoRoute(path: '/onboarding/name',            builder: (_, _) => const NamePronounsScreen()),
      GoRoute(path: '/onboarding/birthday',        builder: (_, _) => const BirthdayInputScreen()),
      GoRoute(path: '/onboarding/consent/send',    builder: (_, _) => const ParentalConsentScreen()),
      GoRoute(path: '/onboarding/consent/waiting', builder: (_, _) => const ConsentWaitingScreen()),
      GoRoute(path: '/onboarding/terms',           builder: (_, _) => const AssentTermsScreen()),
      GoRoute(path: '/onboarding/goals',           builder: (_, _) => const GoalsSelectionScreen()),
      GoRoute(path: '/onboarding/period-comfort',  builder: (_, _) => const PeriodComfortScreen()),
      GoRoute(path: '/onboarding/period-status',   builder: (_, _) => const PeriodExperienceScreen()),
      GoRoute(path: '/onboarding/interests',       builder: (_, _) => const InterestTopicsScreen()),
      GoRoute(path: '/onboarding/avatar',          builder: (_, _) => const AvatarBuilderScreen()),
      GoRoute(path: '/onboarding/journey-name',    builder: (_, _) => const JourneyNameScreen()),
      GoRoute(path: '/onboarding/welcome',         builder: (_, _) => const WelcomeWorldScreen()),
      GoRoute(path: '/onboarding/tracker/date',    builder: (_, _) => const LastPeriodDateScreen()),
      GoRoute(path: '/onboarding/tracker/details', builder: (_, _) => const CycleDetailsScreen()),
      GoRoute(path: '/onboarding/tracker/done',    builder: (_, _) => const TrackerActivatedScreen()),

      // Deep Link Routes for Notifications
      GoRoute(path: '/tracker/log', builder: (_, _) => const TrackScreen()), // Placeholder for direct log sheet
      GoRoute(path: '/tracker/prediction', builder: (_, _) => const TrackScreen()),
      GoRoute(path: '/tracker/phase', builder: (_, _) => const TrackScreen()), // Placeholder
      GoRoute(path: '/tracker/doctor-connect', builder: (_, _) => const DoctorSummaryScreen()),

      // Tracker Reporting

      GoRoute(path: '/tracker/doctor-summary', builder: (_, _) => const DoctorSummaryScreen()),
      GoRoute(path: '/tracker/settings', builder: (_, _) => const CycleSettingsScreen()),
      GoRoute(
        path: '/tracker/calendar', 
        builder: (context, _) => BlocProvider(
          create: (_) => CalendarCubit(context.read<TrackerRepository>())..loadCalendarData(),
          child: const CalendarScreen(),
        ),
      ),
      GoRoute(path: '/tracker/milestone/first-period', builder: (_, _) => const FirstPeriodCelebrationScreen()),
      GoRoute(
        path: '/tracker/insights', 
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CycleInsightsScreen(
            profile: extra['profile'] as CycleProfileModel,
            logs: extra['logs'] as List<CycleLogModel>,
            history: (extra['history'] as List<CycleRecordModel>?) ?? [],
          );
        }
      ),
      GoRoute(
        path: '/quests',
        builder: (_, _) {
          final repo = QuestRepository(ApiService.instance.dio);
          return BlocProvider(
            create: (context) => QuestBloc(repo)..add(const QuestEvent.load()),
            child: const QuestScreen(),
          );
        },
      ),

      // PeerLine Focus
      GoRoute(path: '/peerline/request', builder: (_, _) => const PeerLineTopicSelectionScreen()),
      GoRoute(
        path: '/peerline/results', 
        builder: (_, state) {
          final topics = state.extra as List<String>? ?? [];
          return PeerLineResultsScreen(selectedTopics: topics);
        }
      ),
      GoRoute(
        path: '/peerline/chat/:sessionId',
        builder: (_, state) => PeerLineChatScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/friends/chat/:matchId',
        builder: (_, state) => FriendChatScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),

      // Community Circles
      GoRoute(path: '/community/circle', builder: (_, state) => CircleScreen(circle: state.extra as Circle)),
      // Home
      GoRoute(
        path: '/home', 
        builder: (_, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          final subtab = int.tryParse(state.uri.queryParameters['subtab'] ?? '2') ?? 2;
          return DashboardScreen(storage: storage, initialTab: tab, initialSubTab: subtab);
        }

      ),


      // Learning Journey Module
      GoRoute(
        path: '/learning/journeys',
        builder: (_, _) {
          final repo = LearningRepository(ApiService.instance.dio);
          return BlocProvider(
            create: (context) => JourneyListBloc(repo),
            child: const JourneyExplorerScreen(),
          );
        },
      ),
      GoRoute(
        path: '/journey/:id',
        builder: (_, state) {
          final journeyId = state.pathParameters['id']!;
          final repo = LearningRepository(ApiService.instance.dio);
          return BlocProvider(
            create: (context) => JourneyDetailBloc(repo)..add(JourneyDetailEvent.loadJourney(journeyId)),
            child: JourneyDetailScreen(journeyId: journeyId),
          );
        },
      ),
      GoRoute(
        path: '/journey/:id/episode/:episodeId',
        builder: (_, state) {
          // DEFENSIVE PARSING: Handle both Episode objects and raw JSON maps
          final extra = state.extra;
          final Episode episode;
          
          if (extra is Episode) {
            episode = extra;
          } else if (extra is Map<String, dynamic>) {
            episode = Episode.fromJson(extra);
          } else {
            // Fallback: If no extra is provided, we should ideally fetch it, 
            // but for now we'll throw a more descriptive error or use a dummy.
            // This prevents the 'subtype' crash in the UI.
            throw Exception('Episode data missing from route. Expected Episode or Map.');
          }

          final repo = LearningRepository(ApiService.instance.dio);
          return BlocProvider(
            create: (context) => EpisodePlayerBloc(repo),
            child: EpisodePlayerScreen(episode: episode),
          );
        },
      ),
    ],
  );
}
