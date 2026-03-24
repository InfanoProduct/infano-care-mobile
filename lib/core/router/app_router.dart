import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/screens/phone_entry_screen.dart';
import 'package:infano_care_mobile/features/auth/screens/otp_verify_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/landing_screen.dart';
import 'package:infano_care_mobile/features/account/screens/account_screen.dart';
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

GoRouter createRouter(LocalStorageService storage) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final token = storage.authToken;
      final tempToken = storage.tempToken;
      final stage = storage.stageComplete;
      final path = state.uri.path;

      // 1. Screens always accessible
      if (path == '/splash' || path.startsWith('/auth')) return null;

      // 2. Not Authenticated (no access token)
      if (token == null) {
        // If they have a tempToken, they can continue early onboarding
        if (tempToken != null) {
          if (path.startsWith('/onboarding')) return null;
          return '/onboarding/path';
        }
        // No tokens: force to splash
        return '/splash';
      }

      // 3. Authenticated (token != null)
      final bool onOnboarding = path.startsWith('/onboarding');
      final bool onAuth = path.startsWith('/auth') || path == '/splash';

      if (stage != '13') {
        // Enforce onboarding flow
        final routes = {
          '0':  '/onboarding/path',
          '1':  '/onboarding/name',
          '2':  '/onboarding/birthday',
          '3':  '/onboarding/consent/send', // Or terms if not needed
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
        
        if (path != target && !path.contains('tracker') && path != '/onboarding/welcome') {
          if (!onOnboarding) return target;
          if (path == '/home' || path == '/account') return target;
        }
      } else {
        // Stage 13 (Complete) - Send to home if on auth/onboarding
        if (onAuth || onOnboarding) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/account',  builder: (_, __) => AccountScreen(storage: storage)),

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

      // Home
      GoRoute(path: '/home', builder: (_, __) => DashboardScreen(storage: storage)),
    ],
  );
}
