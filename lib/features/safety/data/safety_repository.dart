import 'package:dio/dio.dart';

class SosPreferences {
  final String defaultEmergencyType;
  final bool locationEnabled;
  final bool setupCompleted;
  final DateTime? setupCompletedAt;
  final DateTime? lastTestedAt;

  SosPreferences({
    required this.defaultEmergencyType,
    required this.locationEnabled,
    required this.setupCompleted,
    this.setupCompletedAt,
    this.lastTestedAt,
  });

  factory SosPreferences.fromJson(Map<String, dynamic> json) {
    return SosPreferences(
      defaultEmergencyType: json['defaultEmergencyType'] ?? 'physical_threat',
      locationEnabled: json['locationEnabled'] ?? false,
      setupCompleted: json['setupCompleted'] ?? false,
      setupCompletedAt: json['setupCompletedAt'] != null
          ? DateTime.parse(json['setupCompletedAt'])
          : null,
      lastTestedAt: json['lastTestedAt'] != null
          ? DateTime.parse(json['lastTestedAt'])
          : null,
    );
  }

  factory SosPreferences.defaults() => SosPreferences(
        defaultEmergencyType: 'physical_threat',
        locationEnabled: false,
        setupCompleted: false,
      );
}

class SafetyRepository {
  final Dio _dio;

  SafetyRepository(this._dio);

  // ─── Trusted Contacts ───────────────────────────────────────────────────────

  Future<List<dynamic>> getTrustedContacts() async {
    final response = await _dio.get('/safety/trusted-contacts');
    return response.data as List<dynamic>;
  }

  Future<dynamic> addTrustedContact(
      String name, String phone, String relation) async {
    final response = await _dio.post('/safety/trusted-contacts', data: {
      'name': name,
      'phone': phone,
      'relation': relation,
    });
    return response.data;
  }

  Future<void> deleteTrustedContact(String id) async {
    await _dio.delete('/safety/trusted-contacts/$id');
  }

  Future<dynamic> updateContactEmergencies(
      String id, List<String> types) async {
    final response =
        await _dio.put('/safety/trusted-contacts/$id/emergencies', data: {
      'emergencyTypes': types,
    });
    return response.data;
  }

  // ─── Preferences ───────────────────────────────────────────────────────────

  Future<SosPreferences> getPreferences() async {
    try {
      final response = await _dio.get('/safety/preferences');
      return SosPreferences.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return SosPreferences.defaults();
    }
  }

  Future<SosPreferences> savePreferences({
    String? defaultEmergencyType,
    bool? locationEnabled,
    bool? setupCompleted,
  }) async {
    final response = await _dio.put('/safety/preferences', data: {
      if (defaultEmergencyType != null)
        'defaultEmergencyType': defaultEmergencyType,
      if (locationEnabled != null) 'locationEnabled': locationEnabled,
      if (setupCompleted != null) 'setupCompleted': setupCompleted,
    });
    return SosPreferences.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── SOS Trigger ───────────────────────────────────────────────────────────

  Future<dynamic> triggerSos(double lat, double lng,
      {String? emergencyType}) async {
    final response = await _dio.post('/safety/sos/trigger', data: {
      'lat': lat,
      'lng': lng,
      'emergencyType': emergencyType,
    });
    return response.data;
  }

  Future<dynamic> testSos(double lat, double lng,
      {String? emergencyType}) async {
    final response = await _dio.post('/safety/sos/test', data: {
      'lat': lat,
      'lng': lng,
      'emergencyType': emergencyType,
    });
    return response.data;
  }

  Future<dynamic> getActiveIncident() async {
    try {
      final response = await _dio.get('/safety/sos/active');
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> updateSosLocation(
      String incidentId, double lat, double lng) async {
    final response =
        await _dio.post('/safety/sos/$incidentId/location', data: {
      'lat': lat,
      'lng': lng,
    });
    return response.data;
  }

  Future<dynamic> cancelSos(String incidentId) async {
    final response = await _dio.post('/safety/sos/$incidentId/cancel');
    return response.data;
  }

  Future<dynamic> resolveSos(String incidentId) async {
    final response = await _dio.post('/safety/sos/$incidentId/resolve');
    return response.data;
  }
}
