import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/models/peerline_session.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class CommunitySocketService {
  final LocalStorageService _storage;
  io.Socket? _socket;
  io.Socket? _eventsSocket;
  final ValueNotifier<Map<String, int>> unreadUpdates = ValueNotifier({});
  final ValueNotifier<MentorAvailability?> availabilityUpdates = ValueNotifier(null);
  final ValueNotifier<int> pendingRequestsCount = ValueNotifier(0);
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

  String? _currentConnectionId;

  Map<String, dynamic> _toMap(String eventType, dynamic data) {
    final result = <String, dynamic>{'type': eventType};
    if (data is Map) {
      data.forEach((k, v) {
        result[k.toString()] = v;
      });
    } else if (data != null) {
      result['data'] = data;
    }
    return result;
  }

  void connect() {
    final token = _storage.authToken;
    if (token == null) {
      debugPrint('[CommunitySocket] Cannot connect: No token');
      return;
    }

    if (_socket?.connected == true) return;

    final baseUrl = ApiService.instance.dio.options.baseUrl.split('/api')[0];
    debugPrint('[CommunitySocket] Connecting to components at baseUrl: $baseUrl...');

    // Core/PeerLine Namespace
    _socket = io.io('$baseUrl/peerline', <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'forceNew': true,
      'auth': {'token': token},
    });

    // Events Namespace
    _eventsSocket = io.io('$baseUrl/events', <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'forceNew': true,
      'auth': {'token': token},
    });

    _socket?.connect();
    _eventsSocket?.connect();

    _socket?.onConnect((_) {
      debugPrint('[CommunitySocket] PeerLine Connected successfully');
      _socket?.emit('subscribe', {'channel': 'circles'});
      _socket?.emit('subscribe_availability');
      _socket?.emit('subscribe_mentor_updates');
      // Re-subscribe to the current chat connection if any
      if (_currentConnectionId != null) {
        debugPrint('[CommunitySocket] Resubscribing to connection: $_currentConnectionId');
        _socket?.emit('subscribe_session', _currentConnectionId);
      }
    });

    _socket?.on('connect_error', (err) {
      debugPrint('[CommunitySocket] PeerLine Connect Error: $err');
    });

    _socket?.on('connect_timeout', (data) {
      debugPrint('[CommunitySocket] PeerLine Connect Timeout: $data');
    });

    _socket?.on('error', (err) {
      debugPrint('[CommunitySocket] PeerLine Socket Error: $err');
    });

    _eventsSocket?.onConnect((_) {
      debugPrint('[CommunitySocket] Events Connected successfully');
    });

    _eventsSocket?.on('connect_error', (err) {
      debugPrint('[CommunitySocket] Events Connect Error: $err');
    });

    // ─── Availability ─────────────────────────────────────────────────────────
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

    // ─── Mentor-side: pending requests count ──────────────────────────────────
    _socket?.on('pending_requests_update', (data) {
      if (data != null && data is Map && data.containsKey('count')) {
        pendingRequestsCount.value = data['count'] as int;
      }
    });

    // ─── Events Namespace ─────────────────────────────────────────────────────
    _eventsSocket?.on('event_update', (data) {
      debugPrint('[CommunitySocket] Event update received: $data');
      _liveEventController.add(data as Map<String, dynamic>);
    });

    _eventsSocket?.on('question_count_update', (data) {
      if (data != null && data is Map && data.containsKey('count')) {
        liveEventQuestionCount.value = data['count'] as int;
      }
    });

    // ─── PeerLine Chat Events ─────────────────────────────────────────────────
    _socket?.on('message', (data) {
      debugPrint('[CommunitySocket] Socket received message: $data');
      _chatEventController.add(_toMap('message', data));
    });

    _socket?.on('message_deleted', (data) =>
        _chatEventController.add(_toMap('message_deleted', data)));

    _socket?.on('peer_typing', (data) =>
        _chatEventController.add(_toMap('peer_typing', data)));

    _socket?.on('crisis_resource', (data) =>
        _chatEventController.add(_toMap('crisis_resource', data)));

    // Connection lifecycle events (replaces session_ready / session_ended)
    _socket?.on('connection_accepted', (data) =>
        _chatEventController.add(_toMap('connection_accepted', data)));

    _socket?.on('connection_declined', (data) =>
        _chatEventController.add(_toMap('connection_declined', data)));

    _socket?.on('connection_request', (data) =>
        _chatEventController.add(_toMap('connection_request', data)));

    _socket?.on('error', (data) =>
        _chatEventController.add(_toMap('error', data)));

    _socket?.onDisconnect((_) =>
        debugPrint('[CommunitySocket] PeerLine Disconnected'));
    _eventsSocket?.onDisconnect((_) =>
        debugPrint('[CommunitySocket] Events Disconnected'));
  }

  void reconnect() {
    dispose();
    connect();
  }

  // ─── Events specialized methods ───────────────────────────────────────────────
  void subscribeToEvent(String eventId) {
    _eventsSocket?.emit('subscribe_event', eventId);
  }

  void unsubscribeFromEvent(String eventId) {
    _eventsSocket?.emit('unsubscribe_event', eventId);
  }

  // ─── PeerLine Chat methods ────────────────────────────────────────────────────

  /// Subscribe to real-time events for a specific chat connection (teen-peer pair).
  void subscribeToConnection(String connectionId) {
    _currentConnectionId = connectionId;
    debugPrint('[CommunitySocket] Subscribing to connection: $connectionId');
    _socket?.emit('subscribe_session', connectionId);
  }

  /// Unsubscribe from a chat connection room.
  void unsubscribeFromConnection(String connectionId) {
    if (_currentConnectionId == connectionId) {
      _currentConnectionId = null;
    }
    _socket?.emit('unsubscribe_session', connectionId);
  }

  // Backward-compat aliases
  void subscribeToSession(String sessionId) => subscribeToConnection(sessionId);
  void unsubscribeFromSession(String sessionId) => unsubscribeFromConnection(sessionId);

  void subscribeToMentorUpdates() {
    _socket?.emit('subscribe_mentor_updates');
  }

  void unsubscribeFromMentorUpdates() {
    _socket?.emit('unsubscribe_mentor_updates');
  }

  void sendMessage(
    String connectionId,
    String? content,
    String senderRole, {
    String? messageType,
    String? mediaUrl,
    String? clientId,
  }) {
    _socket?.emit('send_message', {
      'sessionId': connectionId,
      'content': content,
      'senderRole': senderRole,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'clientId': clientId,
    });
  }

  void unsendMessage(String connectionId, String messageId) {
    _socket?.emit('delete_message', {
      'sessionId': connectionId,
      'messageId': messageId,
    });
  }

  void sendTypingIndicator(String connectionId, bool isTyping, String senderRole) {
    _socket?.emit('typing_indicator', {
      'sessionId': connectionId,
      'isTyping': isTyping,
      'senderRole': senderRole,
    });
  }

  // Convenience alias — stops typing indicator
  void sendTypingStop(String connectionId, String senderRole) {
    sendTypingIndicator(connectionId, false, senderRole);
  }

  void dispose() {
    _storage.removeListener(_handleStorageChange);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
