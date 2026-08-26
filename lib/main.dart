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
import 'package:infano_care_mobile/features/creative_journey/application/journey_map_cubit.dart';
import 'package:infano_care_mobile/features/creative_journey/repositories/creative_journey_repository.dart';

import 'package:infano_care_mobile/services/community_api.dart';
import 'package:infano_care_mobile/services/community_socket_service.dart';
import 'package:infano_care_mobile/services/friends_socket_service.dart';
import 'package:infano_care_mobile/services/mindful_api.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:infano_care_mobile/core/services/notification_service.dart';

void main() async {
  debugPrint('[App] Starting optimized initialization...');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    // 1. Initialize Local Storage and Firebase in parallel
    final results = await Future.wait([
      LocalStorageService.create(),
      Firebase.initializeApp()
          .then((app) {
            FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
            return app;
          })
          .catchError((e) {
            debugPrint('[App] Firebase initialization warning ⚠️: $e');
            return null;
          }),
    ]);

    final storage = results[0] as LocalStorageService;
    ApiService.init(storage);
    debugPrint('[App] Core services initialized ✅');

    runApp(InfanoCareApp(storage: storage));
  } catch (e) {
    debugPrint('[App] Critical initialization fallback ❌: $e');
    final storage = await LocalStorageService.create();
    ApiService.init(storage);
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
    _router = createRouter(widget.storage, _navigatorKey);

    // Initialize notifications asynchronously without blocking the UI thread
    NotificationService().initialize(_navigatorKey, storage: widget.storage);

    // Remove native splash as soon as the first frame is successfully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build the shared TrackerRepository once
    final trackerRepo = TrackerRepository(
      ApiService.instance.dio,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalStorageService>.value(value: widget.storage),
        Provider<TrackerRepository>.value(value: trackerRepo),
        Provider<CommunityApi>(
          create: (_) => CommunityApi(ApiService.instance.dio),
        ),
        Provider<MindfulApi>(
          create: (_) => MindfulApi(ApiService.instance.dio),
        ),
        Provider<CommunitySocketService>(
          create: (_) => CommunitySocketService(widget.storage),
          dispose: (_, s) => s.dispose(),
        ),
        Provider<FriendsSocketService>(
          create: (_) => FriendsSocketService(widget.storage),
          dispose: (_, s) => s.dispose(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => OnboardingBloc(_repo, widget.storage)
              ..add(const SyncFromStorage()),
          ),
          BlocProvider(
            create: (_) =>
                TrackerBloc(trackerRepo, widget.storage)..add(const TrackerEvent.load()),
          ),
          BlocProvider(
            create: (_) => JourneyMapCubit(
              CreativeJourneyRepository(ApiService.instance.dio),
            )..load(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Infano.Care',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
