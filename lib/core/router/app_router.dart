import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/screens/phone_entry_screen.dart';
import 'package:infano_care_mobile/features/auth/screens/otp_verify_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/landing_screen.dart';
import 'package:infano_care_mobile/features/account/screens/account_screen.dart';
import 'package:infano_care_mobile/features/account/screens/notification_preferences_screen.dart';
import 'package:infano_care_mobile/features/account/screens/data_rights_privacy_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/path_selector_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/name_pronouns_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/birthday_input_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/parental_consent_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/consent_waiting_screen.dart';
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
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

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

GoRouter createRouter(LocalStorageService storage) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: storage,
    redirect: (context, state) {
      final token = storage.authToken;
      final tempToken = storage.tempToken;
      final step = storage.stepComplete;
      final path = state.uri.path;

      final onAuth = path.startsWith('/auth') || path == '/splash';

      // 1. Not Authenticated
      if (token == null) {
        // If they have a tempToken, they can continue early onboarding
        if (tempToken != null) {
          if (path.startsWith('/onboarding') || onAuth) return null;
          return '/onboarding/path';
        }
        // No tokens: allow auth/splash, otherwise force splash
        if (onAuth) return null;
        return '/splash';
      }

      // 2. Authenticated (token != null)
      final bool onOnboarding = path.startsWith('/onboarding');

      // Always allow splash screen to load so it can remove the native splash
      // and perform the initial API synchronization.
      if (path == '/splash') {
        return null;
      }

      if (!storage.isOnboarded) {
        // Enforce onboarding flow
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
        final currentStep = step ?? '0';
        String target = routes[currentStep] ?? '/onboarding/path';

        // Conditional skip: If period status is not active, skip tracker setup (11, 12)
        final periodStatus = storage.periodStatus;
        if (periodStatus != null && periodStatus != 'active') {
          if (currentStep == '11' || currentStep == '12') {
            target = '/home'; // Or a completion screen
          }
        }
        
        if (path != target && !path.contains('tracker') && path != '/onboarding/welcome') {
          if (!onOnboarding) return target;
          if (path == '/home' || path == '/account') return target;
        }
      } else {
        // Step 13 (Complete) - Send to home if on auth/onboarding
        // Allow tracker setup screens even if already onboarded
        if (onAuth || (onOnboarding && !path.contains('tracker'))) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/account',  builder: (_, __) => AccountScreen(storage: storage)),
      GoRoute(path: '/account/notifications', builder: (_, __) => const NotificationPreferencesScreen()),
      GoRoute(path: '/account/data-rights', builder: (_, __) => const DataRightsPrivacyScreen()),

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
      GoRoute(path: '/onboarding/path',           builder: (_, __) => const PathSelectorScreen()),
      GoRoute(path: '/onboarding/name',            builder: (_, __) => const NamePronounsScreen()),
      GoRoute(path: '/onboarding/birthday',        builder: (_, __) => const BirthdayInputScreen()),
      GoRoute(path: '/onboarding/consent/send',    builder: (_, __) => const ParentalConsentScreen()),
      GoRoute(path: '/onboarding/consent/waiting', builder: (_, __) => const ConsentWaitingScreen()),
      GoRoute(path: '/onboarding/terms',           builder: (_, __) => const AssentTermsScreen()),
      GoRoute(path: '/onboarding/goals',           builder: (_, __) => const GoalsSelectionScreen()),
      GoRoute(path: '/onboarding/period-comfort',  builder: (_, __) => const PeriodComfortScreen()),
      GoRoute(path: '/onboarding/period-status',   builder: (_, __) => const PeriodExperienceScreen()),
      GoRoute(path: '/onboarding/interests',       builder: (_, __) => const InterestTopicsScreen()),
      GoRoute(path: '/onboarding/avatar',          builder: (_, __) => const AvatarBuilderScreen()),
      GoRoute(path: '/onboarding/journey-name',    builder: (_, __) => const JourneyNameScreen()),
      GoRoute(path: '/onboarding/welcome',         builder: (_, __) => const WelcomeWorldScreen()),
      GoRoute(path: '/onboarding/tracker/date',    builder: (_, __) => const LastPeriodDateScreen()),
      GoRoute(path: '/onboarding/tracker/details', builder: (_, __) => const CycleDetailsScreen()),
      GoRoute(path: '/onboarding/tracker/done',    builder: (_, __) => const TrackerActivatedScreen()),

      // Tracker Reporting
      GoRoute(path: '/tracker/doctor-summary', builder: (_, __) => const DoctorSummaryScreen()),
      GoRoute(path: '/tracker/settings', builder: (_, __) => const CycleSettingsScreen()),
      GoRoute(
        path: '/tracker/insights', 
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CycleInsightsScreen(
            profile: extra['profile'] as CycleProfileModel,
            logs: extra['logs'] as List<CycleLogModel>,
          );
        }
      ),

      // Home
      GoRoute(path: '/home', builder: (_, __) => DashboardScreen(storage: storage)),

      // Learning Journey Module
      GoRoute(
        path: '/learning/journeys',
        builder: (_, __) {
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
          final episode = state.extra as Episode;
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
