import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CommunitySocketService {
  final LocalStorageService _storage;
  IO.Socket? _socket;
  IO.Socket? _eventsSocket;
  final ValueNotifier<Map<String, int>> unreadUpdates = ValueNotifier({});
  final ValueNotifier<MentorAvailability?> availabilityUpdates = ValueNotifier(null);
  final ValueNotifier<Map<String, dynamic>?> queueUpdates = ValueNotifier(null);
  final ValueNotifier<int> liveEventQuestionCount = ValueNotifier(0);
  
  final _chatEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get chatEvents => _chatEventController.stream;

  final _liveEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get liveEvents => _liveEventController.stream;

  CommunitySocketService(this._storage) {
    _storage.addListener(_handleStorageChange);
  }

  void _handleStorageChange() {
    final token = _storage.authToken;
    if (token != null && (_socket == null || !_socket!.connected)) {
      debugPrint('[CommunitySocket] Token detected, connecting...');
      connect();
    } else if (token == null && _socket != null) {
      debugPrint('[CommunitySocket] No token, disconnecting...');
      dispose();
    }
  }

  void connect() {
    final token = _storage.authToken;
    if (token == null) {
      debugPrint('[CommunitySocket] Cannot connect: No token');
      return;
    }

    if (_socket?.connected == true) return;

    final baseUrl = ApiService.instance.dio.options.baseUrl.replaceAll('/api', '');
    debugPrint('[CommunitySocket] Connecting to components...');
    
    // Core/PeerLine Namespace
    _socket = IO.io('$baseUrl/peerline', <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'forceNew': true,
      'auth': {'token': token},
    });

    // Events Namespace
    _eventsSocket = IO.io('$baseUrl/events', <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'forceNew': true,
      'auth': {'token': token},
    });

    _socket?.connect();
    _eventsSocket?.connect();

    _socket?.onConnect((_) {
      debugPrint('[CommunitySocket] PeerLine Connected');
      _socket?.emit('subscribe', {'channel': 'circles'});
      _socket?.emit('subscribe_availability');
    });

    _eventsSocket?.onConnect((_) {
      debugPrint('[CommunitySocket] Events Connected');
    });

    _socket?.on('new_post', (data) {
      if (data is Map && data.containsKey('circle_id')) {
        final circleId = data['circle_id'] as String;
        final currentUpdates = Map<String, int>.from(unreadUpdates.value);
        currentUpdates[circleId] = (currentUpdates[circleId] ?? 0) + 1;
        unreadUpdates.value = currentUpdates;
      }
    });
    
    _socket?.on('mentor_availability_update', (data) {
      if (data != null && data is Map<String, dynamic>) {
        debugPrint('[CommunitySocket] Availability update: $data');
        availabilityUpdates.value = MentorAvailability.fromJson(data);
      }
    });

    _socket?.on('queue_position_update', (data) {
      if (data != null && data is Map<String, dynamic>) {
        queueUpdates.value = data;
      }
    });

    // Events Namespace Listeners
    _eventsSocket?.on('event_update', (data) {
      debugPrint('[CommunitySocket] Event update received: $data');
      _liveEventController.add(data as Map<String, dynamic>);
    });

    _eventsSocket?.on('question_count_update', (data) {
      if (data != null && data is Map && data.containsKey('count')) {
        liveEventQuestionCount.value = data['count'] as int;
      }
    });

    // PeerLine Chat Events
    _socket?.on('message', (data) => _chatEventController.add({'type': 'message', ...data}));
    _socket?.on('message_deleted', (data) => _chatEventController.add({'type': 'message_deleted', ...data}));
    _socket?.on('peer_typing', (data) => _chatEventController.add({'type': 'peer_typing', ...data}));
    _socket?.on('crisis_resource', (data) => _chatEventController.add({'type': 'crisis_resource', ...data}));
    _socket?.on('session_ended', (data) => _chatEventController.add({'type': 'session_ended', ...data}));
    _socket?.on('session_ready', (data) => _chatEventController.add({'type': 'session_ready', ...data}));
    _socket?.on('session_paused', (data) => _chatEventController.add({'type': 'session_paused', ...data}));
    _socket?.on('error', (data) => _chatEventController.add({'type': 'error', ...data}));
    _socket?.on('queue_count_changed', (data) => _chatEventController.add({'type': 'queue_count_changed', ...data}));

    _socket?.onDisconnect((_) => debugPrint('[CommunitySocket] PeerLine Disconnected'));
    _eventsSocket?.onDisconnect((_) => debugPrint('[CommunitySocket] Events Disconnected'));
  }

  void reconnect() {
    dispose();
    connect();
  }

  // Events specialized methods
  void subscribeToEvent(String eventId) {
    _eventsSocket?.emit('subscribe_event', eventId);
  }

  void unsubscribeFromEvent(String eventId) {
    _eventsSocket?.emit('unsubscribe_event', eventId);
  }

  // PeerLine specialized methods
  void subscribeToSession(String sessionId) {
    _socket?.emit('subscribe_session', sessionId);
  }

  void unsubscribeFromSession(String sessionId) {
    _socket?.emit('unsubscribe_session', sessionId);
  }

  void subscribeToMentorUpdates() {
    _socket?.emit('subscribe_mentor_updates');
  }

  void unsubscribeFromMentorUpdates() {
    _socket?.emit('unsubscribe_mentor_updates');
  }

  void sendMessage(String sessionId, String content, String senderRole, {String? clientId}) {
    _socket?.emit('send_message', {
      'sessionId': sessionId,
      'content': content,
      'senderRole': senderRole,
      'clientId': clientId,
    });
  }

  void unsendMessage(String sessionId, String messageId) {
    _socket?.emit('delete_message', {
      'sessionId': sessionId,
      'messageId': messageId,
    });
  }

  void pauseSession(String sessionId) {
    _socket?.emit('pause_session', {
      'sessionId': sessionId,
    });
  }

  void sendTypingIndicator(String sessionId, bool isTyping, String senderRole) {
    _socket?.emit('typing_indicator', {
      'sessionId': sessionId,
      'isTyping': isTyping,
      'senderRole': senderRole,
    });
  }

  void sendTypingStop(String sessionId, String senderRole) {
    _socket?.emit('typing_stop', {
      'sessionId': sessionId,
      'senderRole': senderRole,
    });
  }

  void endSession(String sessionId, String reason) {
    _socket?.emit('end_session', {
      'sessionId': sessionId,
      'reason': reason,
    });
  }

  void dispose() {
    _storage.removeListener(_handleStorageChange);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
