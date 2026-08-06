import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ExpertService {
  final Dio _dio = ApiService.instance.dio;
  final LocalStorageService _storage;
  io.Socket? _socket;
  final ValueNotifier<bool> connectionStatus = ValueNotifier(false);

  ExpertService(this._storage);

  /// Fetch list of available experts (for User side)
  Future<List<dynamic>> getExperts() async {
    try {
      final response = await _dio.get('/expert/list');
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error fetching experts: $e');
      return [];
    }
  }

  /// Fetch active consultations for the human expert (for Expert side)
  Future<List<dynamic>> getMySessions() async {
    try {
      final response = await _dio.get('/expert/sessions');
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error fetching expert sessions: $e');
      return [];
    }
  }

  /// Fetch 1:1 Video/Direct Scheduled Consultations for Expert
  Future<List<dynamic>> getDirectSessions() async {
    try {
      final response = await _dio.get('/expert/sessions');
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error fetching direct sessions: $e');
      return [];
    }
  }

  /// Fetch list of program enrollments (for Expert side)
  Future<List<dynamic>> getEnrollments() async {
    try {
      final response = await _dio.get('/expert/enrollments');
      debugPrint('[ExpertService] getEnrollments status: ${response.statusCode}, data: ${response.data}');
      if (response.data is List) {
        return response.data as List<dynamic>;
      } else if (response.data is Map && response.data['data'] is List) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[ExpertService] Error fetching enrollments: $e');
      return [];
    }
  }

  /// Fetch enrollment details and session timeline
  Future<Map<String, dynamic>?> getEnrollmentDetails(String id) async {
    try {
      final response = await _dio.get('/expert/enrollments/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error fetching enrollment details: $e');
      return null;
    }
  }

  /// Schedule a program session for a student
  Future<bool> scheduleProgramSession({
    required String userId,
    required String programId,
    required int sessionNumber,
    required String scheduledAt,
    required String meetLink,
  }) async {
    try {
      final response = await _dio.post('/expert/sessions', data: {
        'userId': userId,
        'programId': programId,
        'sessionNumber': sessionNumber,
        'scheduledAt': scheduledAt,
        'meetLink': meetLink,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[ExpertService] Error scheduling program session: $e');
      return false;
    }
  }

  /// Mark a program session as complete
  Future<bool> completeProgramSession(String sessionId) async {
    try {
      final response = await _dio.patch('/expert/sessions/$sessionId/complete');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExpertService] Error completing program session: $e');
      return false;
    }
  }

  /// Update meeting link for a consultation
  Future<bool> updateMeetLink(String sessionId, String meetLink) async {
    try {
      final response = await _dio.patch('/expert/sessions/$sessionId/meet-link', data: {'meetLink': meetLink});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExpertService] Error updating meet link: $e');
      return false;
    }
  }

  /// Update consultation status (SCHEDULED, COMPLETED, CANCELLED, etc.)
  Future<bool> updateSessionStatus(String sessionId, String status) async {
    try {
      final response = await _dio.patch('/expert/sessions/$sessionId/status', data: {'status': status});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExpertService] Error updating status: $e');
      return false;
    }
  }

  /// Reschedule consultation
  Future<bool> rescheduleSession(String sessionId, String scheduledAt) async {
    try {
      final response = await _dio.patch('/expert/sessions/$sessionId/reschedule', data: {'scheduledAt': scheduledAt});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExpertService] Error rescheduling session: $e');
      return false;
    }
  }

  /// Get Expert Calendar Availability & Settings
  Future<Map<String, dynamic>> getCalendarSettings() async {
    try {
      final response = await _dio.get('/expert/calendar');
      return (response.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      debugPrint('[ExpertService] Error fetching calendar settings: $e');
      return {};
    }
  }

  /// Update Expert Calendar Availability & Settings
  Future<bool> updateCalendarSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _dio.put('/expert/calendar', data: settings);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExpertService] Error updating calendar settings: $e');
      return false;
    }
  }

  /// Create or get an existing session with an expert
  Future<Map<String, dynamic>?> getOrCreateSession(String expertId) async {
    try {
      final response = await _dio.post('/expert/session', data: {'expertId': expertId});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error getting session: $e');
      return null;
    }
  }

  /// Fetch message history for a session
  Future<List<dynamic>> getMessages(String sessionId) async {
    try {
      final response = await _dio.get('/expert/messages/$sessionId');
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error fetching messages: $e');
      return [];
    }
  }

  // ── Socket.io Connection ───────────────────────────────────────────────────

  /// Initialize and connect to the Expert Chat Socket
  void connectToChat(String sessionId, Function(Map<String, dynamic>) onMessageReceived) {
    final token = _storage.authToken;
    if (token == null) {
      debugPrint('[Socket] ABORT: Auth token is missing in storage');
      return;
    }

    // Use same base URL but replace /api and use http/ws
    final socketUrl = Uri.parse(_dio.options.baseUrl).origin;
    debugPrint('[Socket] Attempting connection to: $socketUrl (Session: $sessionId)');

    _socket = io.io(socketUrl, <String, dynamic>{
      'path': '/api/socket.io',
      'transports': ['websocket'],
      'forceNew': true,
      'multiplex': false,
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('[Socket] Connected to Expert Chat (Session: $sessionId)');
      connectionStatus.value = true;
      _socket?.emit('join_session', {'sessionId': sessionId});
    });

    _socket?.on('new_message', (data) {
      debugPrint('[Socket] New message received: $data');
      onMessageReceived(Map<String, dynamic>.from(data));
    });

    _socket?.onConnectError((e) {
      debugPrint('[Socket] Connect error: $e');
      connectionStatus.value = false;
    });

    _socket?.onDisconnect((_) {
      debugPrint('[Socket] Disconnected from expert chat');
      connectionStatus.value = false;
    });
  }

  /// Send a message via Socket.io
  void sendMessage(String sessionId, String content) {
    if (_socket?.connected ?? false) {
      _socket?.emit('send_message', {
        'sessionId': sessionId,
        'content': content,
      });
    } else {
      debugPrint('[Socket] Cannot send message: Not connected');
    }
  }

  Future<bool> markAsRead(String sessionId) async {
    try {
      final response = await _dio.patch('/expert/session/$sessionId/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ExpertService] Error marking as read: $e');
      return false;
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}
