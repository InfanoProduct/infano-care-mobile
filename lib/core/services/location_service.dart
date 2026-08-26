import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDiagnostics {
  final bool isServiceEnabled;
  final LocationPermission permission;
  final Position? position;
  final String? address;
  final String? errorMessage;

  const LocationDiagnostics({
    required this.isServiceEnabled,
    required this.permission,
    this.position,
    this.address,
    this.errorMessage,
  });

  bool get isReady =>
      isServiceEnabled &&
      (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) &&
      position != null;

  bool get hasPermission =>
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}

class LocationHelperService {
  static final LocationHelperService instance = LocationHelperService._();
  LocationHelperService._();

  static Position? _cachedPosition;

  /// Check GPS service and permissions, and retrieve current position with fast fallback.
  Future<Position?> getCurrentPosition({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        debugPrint('[LocationHelperService] Location service disabled on device');
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _cachedPosition = lastKnown;
          return lastKnown;
        }
        return _cachedPosition;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('[LocationHelperService] Location permission denied: $permission');
          return _cachedPosition;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationHelperService] Location permission denied forever');
        return _cachedPosition;
      }

      // Check last known position immediately for instant baseline
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _cachedPosition = lastKnown;
      }

      // Platform-tailored high-accuracy location settings (fused provider on Android)
      LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 1),
          timeLimit: timeout,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: timeout,
        );
      } else {
        locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        );
      }

      // Try high-accuracy location first
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
        _cachedPosition = pos;
        debugPrint('[LocationHelperService] Fresh GPS position acquired: ${pos.latitude}, ${pos.longitude}');
        return pos;
      } catch (e) {
        debugPrint('[LocationHelperService] Fresh GPS fetch failed/timed out ($e), using fallback...');
        if (_cachedPosition != null) return _cachedPosition;
        if (lastKnown != null) return lastKnown;

        // Fast fallback to balanced/medium accuracy
        try {
          final fallbackPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 3),
            ),
          );
          _cachedPosition = fallbackPos;
          return fallbackPos;
        } catch (_) {
          return _cachedPosition;
        }
      }
    } catch (e) {
      debugPrint('[LocationHelperService] Error in getCurrentPosition: $e');
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) _cachedPosition = lastKnown;
        return _cachedPosition;
      } catch (_) {
        return _cachedPosition;
      }
    }
  }

  /// Reverse geocode coordinates to human-readable address.
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.name != null && place.name!.isNotEmpty && place.name != place.street) place.name!,
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality!,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea!,
          if (place.postalCode != null && place.postalCode!.isNotEmpty) place.postalCode!,
        ];
        return parts.toSet().join(', ');
      }
    } catch (e) {
      debugPrint('[LocationHelperService] Reverse geocode failed: $e');
    }
    return null;
  }

  /// Comprehensive diagnostic of device GPS state
  Future<LocationDiagnostics> runDiagnostics() async {
    bool serviceEnabled = false;
    LocationPermission permission = LocationPermission.unableToDetermine;
    Position? position;
    String? address;
    String? error;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      permission = await Geolocator.checkPermission();

      if (serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse)) {
        position = await getCurrentPosition(timeout: const Duration(seconds: 6));
        if (position != null) {
          address = await getAddressFromCoordinates(position.latitude, position.longitude);
        } else {
          error = 'Could not acquire GPS fix. Try moving closer to an open window or outdoors.';
        }
      } else if (!serviceEnabled) {
        error = 'Device GPS/Location services are turned off. Please turn on Location in Settings.';
      } else {
        error = 'Location permission has not been granted yet.';
      }
    } catch (e) {
      error = 'Location diagnostic error: $e';
    }

    return LocationDiagnostics(
      isServiceEnabled: serviceEnabled,
      permission: permission,
      position: position,
      address: address,
      errorMessage: error,
    );
  }

  /// Request permission explicitly
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open device GPS hardware settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings page for permissions
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
