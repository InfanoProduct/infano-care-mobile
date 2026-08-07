import 'package:dio/dio.dart';

class SafetyRepository {
  final Dio _dio;

  SafetyRepository(this._dio);

  Future<List<dynamic>> getTrustedContacts() async {
    final response = await _dio.get('/safety/trusted-contacts');
    return response.data as List<dynamic>;
  }

  Future<dynamic> addTrustedContact(String name, String phone, String relation) async {
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

  Future<dynamic> triggerSos(double lat, double lng, {String? emergencyType}) async {
    final response = await _dio.post('/safety/sos/trigger', data: {
      'lat': lat,
      'lng': lng,
      'emergencyType': emergencyType,
    });
    return response.data;
  }

  Future<dynamic> updateContactEmergencies(String id, List<String> types) async {
    final response = await _dio.put('/safety/trusted-contacts/$id/emergencies', data: {
      'emergencyTypes': types,
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
