// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:infano_care_mobile/core/services/privacy_service.dart' as _i48;
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart'
    as _i721;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i48.PrivacyService>(
      () => _i48.PrivacyService(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i721.TrackerRepository>(
      () => _i721.TrackerRepository(gh<_i361.Dio>(), gh<_i48.PrivacyService>()),
    );
    return this;
  }
}
