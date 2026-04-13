import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:infano_care_mobile/core/router/app_router.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/data/onboarding_repository.dart';
import 'package:infano_care_mobile/features/tracker/bloc/tracker_bloc.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';
import 'package:infano_care_mobile/core/services/privacy_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:infano_care_mobile/core/services/notification_service.dart';

void main() async {
  debugPrint('[App] Starting initialization...');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // 1. Initialize Firebase
    debugPrint('[App] Initializing Firebase...');
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    debugPrint('[App] Firebase initialized ✅');
  } catch (e) {
    debugPrint('[App] Firebase initialization failed ❌: $e');
  }

  try {
    // 2. Bootstrap services
    debugPrint('[App] Initializing services...');
    final storage = await LocalStorageService.create();
    ApiService.init(storage);
    debugPrint('[App] Services initialized ✅');

    runApp(InfanoCareApp(storage: storage));
  } catch (e) {
    debugPrint('[App] Critical initialization error ❌: $e');
    // Still try to run app to show some UI or handle the error
    final storage = await LocalStorageService.create();
    runApp(InfanoCareApp(storage: storage));
  }
}

class InfanoCareApp extends StatefulWidget {
  const InfanoCareApp({super.key, required this.storage});
  final LocalStorageService storage;

  @override
  State<InfanoCareApp> createState() => _InfanoCareAppState();
}

class _InfanoCareAppState extends State<InfanoCareApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router;
  late final OnboardingRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = OnboardingRepository(ApiService.instance);
    _router = createRouter(widget.storage);
    
    // Initialize notifications
    NotificationService().initialize(_navigatorKey, storage: widget.storage);
  }

  @override
  Widget build(BuildContext context) {
    // Build the shared TrackerRepository once
    final trackerRepo = TrackerRepository(
      ApiService.instance.dio,
      PrivacyService(const FlutterSecureStorage()),
    );

    return ChangeNotifierProvider.value(
      value: widget.storage,
      child: Provider<TrackerRepository>.value(
        value: trackerRepo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => OnboardingBloc(_repo, widget.storage)
                ..add(const SyncFromStorage()),
            ),
            BlocProvider(
              create: (_) =>
                  TrackerBloc(trackerRepo)..add(const TrackerEvent.load()),
            ),
          ],
          child: MaterialApp.router(
            key: _navigatorKey,
            title: 'Infano.Care',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
