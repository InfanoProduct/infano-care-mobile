import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/screens/phone_entry_screen.dart';
import 'package:infano_care_mobile/features/auth/screens/otp_verify_screen.dart';
import 'package:infano_care_mobile/features/tracker/presentation/screens/all_articles_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/landing_screen.dart';
import 'package:infano_care_mobile/features/account/screens/account_screen.dart';
import 'package:infano_care_mobile/features/account/screens/family_settings_screen.dart';
import 'package:infano_care_mobile/features/account/screens/notification_preferences_screen.dart';
import 'package:infano_care_mobile/features/account/screens/data_rights_privacy_screen.dart';
import 'package:infano_care_mobile/features/account/screens/saved_articles_screen.dart';
import 'package:infano_care_mobile/features/account/screens/settings_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/path_selector_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/name_pronouns_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_topic_selection_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_results_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_chat_screen.dart';
import 'package:infano_care_mobile/screens/connect/friend_chat_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/birthday_input_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/parental_consent_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/consent_waiting_screen.dart';
import 'package:infano_care_mobile/widgets/circle_details_sheet.dart';
import 'package:infano_care_mobile/models/circle.dart';
import 'package:infano_care_mobile/features/onboarding/screens/assent_terms_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/goals_selection_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/period_comfort_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/period_experience_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/interest_topics_screen.dart';
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
import 'package:infano_care_mobile/features/safety/screens/sos_cancel_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_active_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/contact_picker_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/safety_welcome_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_config_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_type_setup_screen.dart';
import 'package:infano_care_mobile/features/safety/screens/sos_test_screen.dart';

// Gigi & Expert Imports
import 'package:infano_care_mobile/features/chat/screens/chat_screen.dart';
import 'package:infano_care_mobile/features/chat/screens/my_chats_screen.dart';
import 'package:infano_care_mobile/features/chat/screens/chat_search_screen.dart';
import 'package:infano_care_mobile/features/chat/data/chat_repository.dart';
import 'package:infano_care_mobile/features/chat/bloc/chat_bloc.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_dashboard_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_list_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_chat_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_consultations_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_calendar_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_program_sessions_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_enrollment_detail_screen.dart';

// Learning Journey Imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/learning/screens/learn_hub_screen.dart';
import 'package:infano_care_mobile/features/learning/screens/payments_and_orders_screens.dart';
import 'package:infano_care_mobile/features/learning/screens/order_details_screen.dart';

// Journal Module Imports
import 'package:infano_care_mobile/features/journal/application/journal_cubit.dart';
import 'package:infano_care_mobile/features/journal/data/repositories/journal_repository.dart';
import 'package:infano_care_mobile/features/journal/screens/journal_home_screen.dart';
import 'package:infano_care_mobile/features/journal/screens/journal_mode_picker_screen.dart';
import 'package:infano_care_mobile/features/journal/screens/journal_composer_screen.dart';
import 'package:infano_care_mobile/features/journal/screens/journal_entry_detail_screen.dart';
import 'package:infano_care_mobile/features/journal/screens/journal_lock_screen.dart';

// Creative Journey v2 Module
import 'package:infano_care_mobile/features/creative_journey/screens/creative_journey_hub_screen.dart';
import 'package:infano_care_mobile/features/creative_journey/screens/journey_detail_screen.dart';
import 'package:infano_care_mobile/features/creative_journey/screens/episode_path_screen.dart';

String getRouteForStep(String step, {String? periodStatus, String? role}) {
  if (role != null && step == '0') {
    return '/onboarding/name';
  }

  final routes = {
    '0': '/onboarding/path',
    '1': '/onboarding/name',
    '2': '/onboarding/birthday',
    '3': '/onboarding/consent/send',
    '4': '/onboarding/goals',
    '5': '/onboarding/period-comfort',
    '6': '/onboarding/period-status',
    '7': '/onboarding/interests',
    '8': '/onboarding/terms',
    '9': '/onboarding/tracker/date',
    '10': '/onboarding/tracker/details',
  };

  // Skip tracker setup if period status is not active
  if (periodStatus != null && periodStatus != 'active') {
    if (step == '9' || step == '10') return '/home';
  }

  return routes[step] ??
      (role != null ? '/onboarding/name' : '/onboarding/path');
}

// Expert creation helper functions...

GoRouter createRouter(
  LocalStorageService storage,
  GlobalKey<NavigatorState> navigatorKey,
) {
  final chatRepo = ChatRepository(ApiService.instance);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    refreshListenable: storage,
    redirect: (context, state) {
      final token = storage.authToken;
      final role = storage.role;
      final step = storage.stepComplete;
      final path = state.uri.path;

      final onAuth = path.startsWith('/auth') || path == '/splash';

      // 1. Not authenticated — send to splash/auth
      if (token == null) {
        if (onAuth) return null;
        return '/splash';
      }

      // 2. Fully onboarded
      if (storage.isOnboarded) {
        // Experts go to their dashboard
        if (role == 'EXPERT') {
          if (path == '/home' ||
              path == '/splash' ||
              path.startsWith('/onboarding')) {
            return '/expert/dashboard';
          }
          return null;
        }
        // Others go home
        if (onAuth ||
            (path.startsWith('/onboarding') && !path.contains('tracker'))) {
          return '/home';
        }
        return null;
      }

      // 3. Not fully onboarded — enforce onboarding flow
      // If they land on splash/auth after login, send to their step
      if (path == '/splash' || path == '/auth/otp' || path == '/auth/phone') {
        if (role != null) return '/onboarding/name';
        return '/onboarding/path';
      }

      // Allow onboarding screens and tracker screens freely
      if (path.startsWith('/onboarding') ||
          path.contains('tracker') ||
          path == '/settings' ||
          path == '/account' ||
          path == '/chat') {
        return null;
      }

      // Any other screen while not onboarded → redirect to correct step
      final target = getRouteForStep(
        step ?? '0',
        periodStatus: storage.periodStatus,
        role: role,
      );
      return target;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const LandingScreen()),
      GoRoute(
        path: '/account',
        builder: (_, _) => AccountScreen(storage: storage),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => SettingsScreen(storage: storage),
      ),
      GoRoute(
        path: '/account/notifications',
        builder: (_, _) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/account/data-rights',
        builder: (_, _) => const DataRightsPrivacyScreen(),
      ),
      GoRoute(
        path: '/account/saved',
        builder: (_, _) => const SavedArticlesScreen(),
      ),
      GoRoute(
        path: '/account/family',
        builder: (_, _) => FamilySettingsScreen(storage: storage),
      ),

      // Expert Dashboard & Tools
      GoRoute(
        path: '/expert/dashboard',
        builder: (_, _) => ExpertDashboardScreen(storage: storage),
      ),
      GoRoute(
        path: '/expert/program-sessions',
        builder: (_, _) => ExpertProgramSessionsScreen(storage: storage),
      ),
      GoRoute(
        path: '/expert/enrollment-details/:id',
        builder: (_, state) => ExpertEnrollmentDetailScreen(
          enrollmentId: state.pathParameters['id']!,
          storage: storage,
        ),
      ),
      GoRoute(
        path: '/expert/consultations',
        builder: (_, _) => ExpertConsultationsScreen(storage: storage),
      ),
      GoRoute(
        path: '/expert/calendar',
        builder: (_, _) => ExpertCalendarScreen(storage: storage),
      ),

      // Expert Chat
      GoRoute(
        path: '/expert/list',
        builder: (_, _) => ExpertListScreen(storage: storage),
      ),
      GoRoute(path: '/my-chats', builder: (_, _) => const MyChatsScreen()),
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

      // Gigi assistant (Redirect /chat to universal MyChatsScreen)
      GoRoute(path: '/chat', builder: (_, _) => const MyChatsScreen()),
      GoRoute(
        path: '/gigi/chat/:sessionId',
        builder: (_, state) => BlocProvider(
          create: (context) =>
              ChatBloc(chatRepo)
                ..add(SelectSession(state.pathParameters['sessionId']!)),
          child: ChatScreen(sessionId: state.pathParameters['sessionId']!),
        ),
      ),
      GoRoute(
        path: '/my-chats/search',
        builder: (_, _) => const ChatSearchScreen(),
      ),
      GoRoute(
        path: '/good-to-know',
        builder: (_, _) => const AllArticlesScreen(),
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
      GoRoute(
        path: '/onboarding/path',
        builder: (_, _) => const PathSelectorScreen(),
      ),
      GoRoute(
        path: '/onboarding/name',
        builder: (_, _) => const NamePronounsScreen(),
      ),
      GoRoute(
        path: '/onboarding/birthday',
        builder: (_, _) => const BirthdayInputScreen(),
      ),
      GoRoute(
        path: '/onboarding/consent/send',
        builder: (_, _) => const ParentalConsentScreen(),
      ),
      GoRoute(
        path: '/onboarding/consent/waiting',
        builder: (_, _) => const ConsentWaitingScreen(),
      ),
      GoRoute(
        path: '/onboarding/terms',
        builder: (_, _) => const AssentTermsScreen(),
      ),
      GoRoute(
        path: '/onboarding/goals',
        builder: (_, _) => const GoalsSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/period-comfort',
        builder: (_, _) => const PeriodComfortScreen(),
      ),
      GoRoute(
        path: '/onboarding/period-status',
        builder: (_, _) => const PeriodExperienceScreen(),
      ),
      GoRoute(
        path: '/onboarding/interests',
        builder: (_, _) => const InterestTopicsScreen(),
      ),
      // GoRoute(path: '/onboarding/avatar',          builder: (_, _) => const AvatarBuilderScreen()),
      // GoRoute(path: '/onboarding/journey-name',    builder: (_, _) => const JourneyNameScreen()),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (_, _) => const WelcomeWorldScreen(),
      ),
      GoRoute(
        path: '/onboarding/tracker/date',
        builder: (_, _) => const LastPeriodDateScreen(),
      ),
      GoRoute(
        path: '/onboarding/tracker/details',
        builder: (_, _) => const CycleDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/tracker/done',
        builder: (_, _) => const TrackerActivatedScreen(),
      ),

      // Deep Link Routes for Notifications
      GoRoute(
        path: '/track',
        builder: (_, _) => const TrackScreen(),
      ),
      GoRoute(
        path: '/tracker/log',
        builder: (_, _) => const TrackScreen(),
      ), // Placeholder for direct log sheet
      GoRoute(
        path: '/tracker/prediction',
        builder: (_, _) => const TrackScreen(),
      ),
      GoRoute(
        path: '/tracker/phase',
        builder: (_, _) => const TrackScreen(),
      ), // Placeholder
      GoRoute(
        path: '/tracker/doctor-connect',
        builder: (_, _) => const DoctorSummaryScreen(),
      ),

      // Tracker Reporting
      GoRoute(
        path: '/tracker/doctor-summary',
        builder: (_, _) => const DoctorSummaryScreen(),
      ),
      GoRoute(
        path: '/tracker/settings',
        builder: (_, _) => const CycleSettingsScreen(),
      ),
      GoRoute(
        path: '/tracker/calendar',
        builder: (context, _) => BlocProvider(
          create: (_) =>
              CalendarCubit(context.read<TrackerRepository>())
                ..loadCalendarData(),
          child: const CalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/tracker/milestone/first-period',
        builder: (_, _) => const FirstPeriodCelebrationScreen(),
      ),
      GoRoute(
        path: '/tracker/insights',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CycleInsightsScreen(
            profile: extra['profile'] as CycleProfileModel,
            logs: extra['logs'] as List<CycleLogModel>,
            history: (extra['history'] as List<CycleRecordModel>?) ?? [],
          );
        },
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
      GoRoute(
        path: '/peerline/request',
        builder: (_, _) => const PeerLineTopicSelectionScreen(),
      ),
      GoRoute(
        path: '/peerline/results',
        builder: (_, state) {
          final topics = state.extra as List<String>? ?? [];
          return PeerLineResultsScreen(selectedTopics: topics);
        },
      ),
      GoRoute(
        path: '/peerline/chat/:sessionId',
        builder: (_, state) =>
            PeerLineChatScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: '/friends/chat/:matchId',
        builder: (_, state) =>
            FriendChatScreen(matchId: state.pathParameters['matchId']!),
      ),

      // Community Circles
      GoRoute(
        path: '/community/circle',
        builder: (_, state) => CircleDetailsSheet(circle: state.extra as Circle),
      ),
      // Home
      GoRoute(
        path: '/home',
        builder: (_, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          final subtab =
              int.tryParse(state.uri.queryParameters['subtab'] ?? '1') ?? 1;
          return DashboardScreen(
            storage: storage,
            initialTab: tab,
            initialSubTab: subtab,
          );
        },
      ),

      // ── Safety / SOS Module ───────────────────────────────────────────────────────
      GoRoute(
        path: '/safety/welcome',
        builder: (_, _) => const SafetyWelcomeScreen(),
      ),
      GoRoute(
        path: '/safety/contacts',
        builder: (_, state) => ContactPickerScreen(
          fromWizard: state.uri.queryParameters['wizard'] == 'true',
        ),
      ),
      GoRoute(
        path: '/safety/setup-type',
        builder: (_, state) => SosTypeSetupScreen(
          fromWizard: state.uri.queryParameters['wizard'] == 'true',
        ),
      ),
      GoRoute(
        path: '/safety/test',
        builder: (_, _) => const SosTestScreen(),
      ),
      GoRoute(
        path: '/safety/sos',
        builder: (_, _) => const SosHubScreen(),
      ),
      GoRoute(
        path: '/safety/sos/countdown',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SosCountdownScreen(
            emergencyType: extra['emergencyType'] as String? ?? 'physical_threat',
            contacts: extra['contacts'] as List<dynamic>? ?? [],
          );
        },
      ),
      GoRoute(
        path: '/safety/sos/active',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SosActiveScreen(
            incidentId: extra['incidentId'] as String?,
            contacts: extra['contacts'] as List<dynamic>? ?? [],
            emergencyType: extra['emergencyType'] as String? ?? 'physical_threat',
          );
        },
      ),
      // Legacy alias kept for backwards compat
      GoRoute(
        path: '/safety/sos_config',
        builder: (_, _) => const SosConfigScreen(),
      ),

      // ── Journal Module ────────────────────────────────────────────────────────
      GoRoute(
        path: '/journal',
        builder: (_, _) {
          final repo = JournalRepository(ApiService.instance.dio);
          return BlocProvider(
            create: (_) => JournalCubit(repo)..loadFeed(),
            child: const JournalLockScreen(child: JournalHomeScreen()),
          );
        },
      ),
      GoRoute(
        path: '/journal/new',
        builder: (_, state) {
          final repo = JournalRepository(ApiService.instance.dio);
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => JournalCubit(repo),
            child: JournalModePickerScreen(extra: extra),
          );
        },
      ),
      GoRoute(
        path: '/journal/compose',
        builder: (_, state) {
          final repo = JournalRepository(ApiService.instance.dio);
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => JournalCubit(repo),
            child: JournalComposerScreen(extra: extra),
          );
        },
      ),
      GoRoute(
        path: '/journal/:id',
        builder: (_, state) {
          final repo = JournalRepository(ApiService.instance.dio);
          return BlocProvider(
            create: (_) => JournalCubit(repo)..loadFeed(),
            child: JournalEntryDetailScreen(id: state.pathParameters['id']!),
          );
        },
      ),

      // ── Creative Learning Journey v2 ────────────────────────────────────────
      GoRoute(
        path: '/creative-journey',
        builder: (_, _) => const CreativeJourneyHubScreen(),
      ),
      GoRoute(
        path: '/creative-journey/journey/:journeyId',
        builder: (_, state) => CreativeJourneyDetailScreen(
          journeyId: state.pathParameters['journeyId']!,
        ),
      ),
      GoRoute(
        path: '/creative-journey/episode/:episodeId',
        builder: (_, state) => EpisodePathScreen(
          episodeId: state.pathParameters['episodeId']!,
        ),
      ),
      GoRoute(
        path: '/creative-journey/episodes/:episodeId',
        builder: (_, state) => EpisodePathScreen(
          episodeId: state.pathParameters['episodeId']!,
        ),
      ),
      // Learning Journey Module
      // Learning Journey Module Redirect to Creative Journey v2
      GoRoute(
        path: '/learning/journeys',
        builder: (_, _) => const CreativeJourneyHubScreen(),
      ),
      GoRoute(
        path: '/learning/programs',
        builder: (_, _) => LearningProgramsScreen(storage: storage),
      ),

      GoRoute(
        path: '/orders',
        builder: (_, _) => MyOrdersScreen(storage: storage),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => MyOrderDetailsScreen(
          orderId: state.pathParameters['id']!,
          storage: storage,
        ),
      ),
      GoRoute(
        path: '/program-payment/:id',
        builder: (_, state) => MyProgramPaymentDetailsScreen(
          enrollmentId: state.pathParameters['id']!,
          storage: storage,
        ),
      ),
    ],
  );
}
