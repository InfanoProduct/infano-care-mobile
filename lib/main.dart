import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 1. Force local bundled font loading only (0ms font resolution, no HTTP blocking)
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    // 2. Fast non-blocking storage initialization
    final storage = await LocalStorageService.create();
    ApiService.init(storage);

    // 3. Launch UI immediately without waiting for remote networks
    runApp(InfanoCareApp(storage: storage));

    // 4. Initialize Firebase in the background without holding the splash screen
    unawaited(
      Firebase.initializeApp()
          .then((app) {
            FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
          })
          .catchError((e) {
            debugPrint('[App] Firebase background initialization warning: $e');
          }),
    );
  } catch (e) {
    debugPrint('[App] Critical initialization fallback: $e');
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

    // Remove native splash as quickly as possible
    FlutterNativeSplash.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      // Initialize background notification handling after first frame
      NotificationService().initialize(_navigatorKey, storage: widget.storage);
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
            create: (_) => TrackerBloc(trackerRepo, widget.storage),
          ),
          BlocProvider(
            create: (_) => JourneyMapCubit(
              CreativeJourneyRepository(ApiService.instance.dio),
            ),
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
