import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class FriendsSocketService {
  final LocalStorageService _storage;
  IO.Socket? _socket;
  
  final _chatEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatEvents => _chatEventController.stream;

  Stream<Map<String, dynamic>> get matchEvents => chatEvents.where((e) => e['type'] == 'friend_match');

  FriendsSocketService(this._storage) {
    _storage.addListener(_handleStorageChange);
  }

  void _handleStorageChange() {
    final token = _storage.authToken;
    if (token != null && (_socket == null || !_socket!.connected)) {
      connect();
    } else if (token == null && _socket != null) {
      dispose();
    }
  }

  void connect() {
    final token = _storage.authToken;
    if (token == null) return;
    if (_socket?.connected == true) return;

    final baseUrl = ApiService.instance.dio.options.baseUrl.replaceAll('/api', '');
    
    _socket = IO.io('$baseUrl/friends', <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'forceNew': true,
      'auth': {'token': token},
    });

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('[FriendsSocket] Connected');
    });

    _socket?.on('message', (data) => _chatEventController.add({'type': 'message', ...data}));
    _socket?.on('peer_typing', (data) => _chatEventController.add({'type': 'peer_typing', ...data}));
    _socket?.on('safety_alert', (data) => _chatEventController.add({'type': 'safety_alert', ...data}));
    _socket?.on('grooming_check', (data) => _chatEventController.add({'type': 'grooming_check', ...data}));
    _socket?.on('friend_match', (data) => _chatEventController.add({'type': 'friend_match', ...data}));
    _socket?.on('error', (data) => _chatEventController.add({'type': 'error', ...data}));

    _socket?.onDisconnect((_) => debugPrint('[FriendsSocket] Disconnected'));
  }

  void subscribeToChat(String matchId) {
    _socket?.emit('subscribe_chat', matchId);
  }

  void unsubscribeFromChat(String matchId) {
    _socket?.emit('unsubscribe_chat', matchId);
  }

  void sendMessage(String matchId, String content, {String? clientId}) {
    _socket?.emit('send_message', {
      'matchId': matchId,
      'content': content,
      'clientId': clientId,
    });
  }

  void sendTypingIndicator(String matchId, bool isTyping) {
    _socket?.emit('typing_indicator', {
      'matchId': matchId,
      'isTyping': isTyping,
    });
  }

  void dispose() {
    _storage.removeListener(_handleStorageChange);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
