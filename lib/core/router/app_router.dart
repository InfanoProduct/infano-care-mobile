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
      final tempToken = storage.tempToken;
      final stage = storage.stageComplete;
      final path  = state.uri.path;

      // 1. Splash & Auth are always accessible
      if (path == '/splash' || path.startsWith('/auth')) return null;

      // 2. Not Authenticated
      if (token == null) {
        // If they have a tempToken, they can perform onboarding
        if (tempToken != null) {
          if (path.startsWith('/onboarding')) {
            // Check for resumption within survey
            if (path == '/onboarding/path' || path == '/onboarding/welcome') return null; // allow these
            
            if (stage == '1') {
               final allowed = ['/onboarding/goals', '/onboarding/period-comfort', '/onboarding/period-status', '/onboarding/interests'];
               if (!allowed.any((a) => path.startsWith(a))) {
                 return '/onboarding/goals';
               }
            }
            if (stage == '2') {
               final allowed = ['/onboarding/avatar', '/onboarding/journey-name'];
               if (!allowed.any((a) => path.startsWith(a))) {
                 return '/onboarding/avatar';
               }
            }
            if (stage == '3') {
               if (path != '/onboarding/terms') return '/onboarding/terms';
            }
            return null;
          }
          // If they try to go home or elsewhere, send to onboarding
          return '/onboarding/path';
        }
        // No tokens at all: must be at splash/auth
        return '/splash';
      }

      // 3. Authenticated (token != null)
      if (path == '/splash' || path.startsWith('/auth') || path == '/onboarding/path') {
         if (stage == '4') return '/onboarding/tracker/date';
         if (stage == '5') return '/home';
         return '/home'; // default for auth users
      }

      if (stage == '5' && path.startsWith('/onboarding') && !path.contains('tracker')) {
        return '/home';
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
