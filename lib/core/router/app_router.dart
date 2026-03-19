import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/auth/screens/phone_entry_screen.dart';
import 'package:infano_care_mobile/features/auth/screens/otp_verify_screen.dart';
import 'package:infano_care_mobile/features/onboarding/screens/splash_screen.dart';
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
      // Resume logic — map ob_stage_complete to correct route
      final token = storage.authToken;
      final stage = storage.stageComplete;
      final path  = state.uri.path;

      // Skip redirect for routes that handle themselves
      if (path == '/splash') return null;
      if (path.startsWith('/auth')) return null;
      if (path.startsWith('/onboarding')) return null;

      if (token == null && stage == null) return '/splash';
      
      // New User Resume Logic (Survey stages)
      if (token == null) {
        if (stage == '1') return '/onboarding/goals';
        if (stage == '2') return '/onboarding/avatar';
        if (stage == '3') return '/onboarding/terms';
        return null;
      }

      // Authenticated User Resume Logic
      if (token != null) {
        if (stage == '4') return '/onboarding/tracker/date';
        if (stage == '5') return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const SplashScreen()),

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
      GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
    ],
  );
}
