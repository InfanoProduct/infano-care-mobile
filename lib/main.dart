import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Bootstrap services
  final storage = await LocalStorageService.create();
  ApiService.init(storage);

  runApp(InfanoCareApp(storage: storage));
}

class InfanoCareApp extends StatefulWidget {
  const InfanoCareApp({super.key, required this.storage});
  final LocalStorageService storage;

  @override
  State<InfanoCareApp> createState() => _InfanoCareAppState();
}

class _InfanoCareAppState extends State<InfanoCareApp> {
  late final GoRouter _router;
  late final OnboardingRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = OnboardingRepository(ApiService.instance);
    _router = createRouter(widget.storage);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OnboardingBloc(_repo, widget.storage)..add(const SyncFromStorage()),
        ),
        BlocProvider(
          create: (_) {
            final repo = TrackerRepository(
              ApiService.instance.dio,
              PrivacyService(const FlutterSecureStorage()),
            );
            return TrackerBloc(repo)..add(const TrackerEvent.load());
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Infano.Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
