import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/screens/phone_entry_screen.dart';
import 'package:infano_care_mobile/features/auth/screens/otp_verify_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/landing_screen.dart';
import 'package:infano_care_mobile/features/account/screens/account_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/path_selector_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/name_pronouns_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_request_screen.dart';
import 'package:infano_care_mobile/screens/connect/peerline_chat_screen.dart';
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

// Gigi Imports
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/chat/screens/chat_screen.dart';
import 'package:infano_care_mobile/features/chat/data/chat_repository.dart';
import 'package:infano_care_mobile/features/chat/bloc/chat_bloc.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_dashboard_screen.dart';

// Expert Imports
import 'package:infano_care_mobile/features/expert/screens/expert_list_screen.dart';
import 'package:infano_care_mobile/features/expert/screens/expert_chat_screen.dart';

GoRouter createRouter(LocalStorageService storage) {
  final chatRepo = ChatRepository(ApiService.instance);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: storage,
    redirect: (context, state) {
      final token = storage.authToken;
      final role = storage.role;
      final tempToken = storage.tempToken;
      final stage = storage.stageComplete;
      final path = state.uri.path;

      // 1. Screens always accessible
      if (path == '/splash' || path.startsWith('/auth')) return null;

      // 2. Not Authenticated (no access token)
      if (token == null) {
        if (tempToken != null) {
          if (path.startsWith('/onboarding')) return null;
          return '/onboarding/path';
        }
        return '/splash';
      }

      // Expert Redirect
      if (role == 'EXPERT') {
        if (path == '/home' || path == '/splash' || path.startsWith('/onboarding')) {
          return '/expert/dashboard';
        }
        return null;
      }

      // 3. Authenticated (token != null)
      final bool onOnboarding = path.startsWith('/onboarding');
      final bool onAuth = path.startsWith('/auth') || path == '/splash';

      if (stage != '13') {
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
        final target = routes[stage ?? '0'] ?? '/onboarding/path';
        
        if (path != target && !path.contains('tracker') && !path.contains('expert') && path != '/onboarding/welcome' && path != '/chat') {
          if (!onOnboarding) return target;
          if (path == '/home' || path == '/account') return target;
        }
      } else {
        if (onAuth || onOnboarding) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/account',  builder: (_, __) => AccountScreen(storage: storage)),
      
      // Expert Dashboard
      GoRoute(path: '/expert/dashboard', builder: (_, __) => ExpertDashboardScreen(storage: storage)),
      
      // Expert Chat
      GoRoute(path: '/expert/list', builder: (_, __) => ExpertListScreen(storage: storage)),
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
        builder: (_, __) => BlocProvider(
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

      // PeerLine Focus
      GoRoute(path: '/peerline/request', builder: (_, __) => const PeerLineRequestScreen()),
      GoRoute(
        path: '/peerline/chat/:sessionId',
        builder: (_, state) => PeerLineChatScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),

      // Community Circles
      GoRoute(path: '/community/circle', builder: (_, state) => CircleScreen(circle: state.extra as Circle)),

      // Home
      GoRoute(path: '/home', builder: (_, __) => DashboardScreen(storage: storage)),
    ],
  );
}
