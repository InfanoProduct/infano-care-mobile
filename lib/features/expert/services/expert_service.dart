import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ExpertService {
  final Dio _dio = ApiService.instance.dio;
  final LocalStorageService _storage;
  IO.Socket? _socket;
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
      final response = await _dio.get('/expert/my-sessions');
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('[ExpertService] Error fetching expert sessions: $e');
      return [];
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
    final socketUrl = _dio.options.baseUrl.replaceAll('/api', '');
    debugPrint('[Socket] Attempting connection to: $socketUrl (Session: $sessionId)');

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
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
