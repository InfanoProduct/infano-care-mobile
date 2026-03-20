import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/core/router/app_router.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:infano_care_mobile/features/onboarding/data/onboarding_repository.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Bootstrap services
  final storage = await LocalStorageService.create();
  ApiService.init(storage);

  runApp(InfanoCareApp(storage: storage));
}

class InfanoCareApp extends StatelessWidget {
  InfanoCareApp({super.key, required this.storage});
  final LocalStorageService storage;

  @override
  Widget build(BuildContext context) {
    final repo   = OnboardingRepository(ApiService.instance);
    final router = createRouter(storage);

    return BlocProvider(
      create: (_) => OnboardingBloc(repo, storage),
      child: MaterialApp.router(
        title: 'Infano.Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
