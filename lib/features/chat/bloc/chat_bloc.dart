import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:infano_care_mobile/core/services/app_cache_manager.dart';
import '../data/chat_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadSessions extends ChatEvent {}

class StartNewSession extends ChatEvent {}

class SelectSession extends ChatEvent {
  final String sessionId;
  const SelectSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class CreateSession extends ChatEvent {
  final String initialMessage;
  final String? moodCode;
  const CreateSession(this.initialMessage, {this.moodCode});
  @override
  List<Object?> get props => [initialMessage, moodCode];
}

class SendChatMessage extends ChatEvent {
  final String content;
  final String sessionId;
  final String? moodCode;
  const SendChatMessage(this.content, this.sessionId, {this.moodCode});
  @override
  List<Object?> get props => [content, sessionId, moodCode];
}

class LoadHistory extends ChatEvent {
  final String sessionId;
  const LoadHistory(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class LoadMoreHistory extends ChatEvent {}

class DeleteSessionEvent extends ChatEvent {
  final String sessionId;
  const DeleteSessionEvent(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class DeleteAllSessionsEvent extends ChatEvent {}

// ─── State ────────────────────────────────────────────────────────────────────
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}

class ChatSuccess extends ChatState {
  final List<dynamic> messages;
  final String? sessionId;
  final bool isSending;
  /// All sessions available for this user — drives the history drawer.
  final List<dynamic> sessions;
  
  // Pagination
  final bool isLoadingMore;
  final bool hasReachedMax;

  const ChatSuccess({
    required this.messages,
    this.sessionId,
    this.isSending = false,
    this.sessions = const [],
    this.isLoadingMore = false,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [messages, sessionId, isSending, sessions, isLoadingMore, hasReachedMax];

  ChatSuccess copyWith({
    List<dynamic>? messages,
    String? sessionId,
    bool? isSending,
    List<dynamic>? sessions,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return ChatSuccess(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isSending: isSending ?? this.isSending,
      sessions: sessions ?? this.sessions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repo;

  ChatBloc(this._repo) : super(ChatInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<StartNewSession>(_onStartNewSession);
    on<SelectSession>(_onSelectSession);
    on<CreateSession>(_onCreateSession);
    on<SendChatMessage>(_onSendMessage);
    on<LoadHistory>(_onLoadHistory);
    on<LoadMoreHistory>(_onLoadMoreHistory);
    on<DeleteSessionEvent>(_onDeleteSession);
    on<DeleteAllSessionsEvent>(_onDeleteAllSessions);
  }

  Future<void> _onLoadSessions(LoadSessions event, Emitter<ChatState> emit) async {
    final cachedSessions = AppCacheManager.instance.getGigiSessions();
    if (cachedSessions != null && cachedSessions.isNotEmpty) {
      final latestSessionId = cachedSessions.first['id'] as String;
      final cachedHistory = AppCacheManager.instance.getGigiHistory(latestSessionId);
      emit(ChatSuccess(
        messages: cachedHistory ?? const [],
        sessionId: latestSessionId,
        sessions: cachedSessions,
        hasReachedMax: (cachedHistory?.length ?? 0) < 20,
      ));
    } else {
      emit(ChatLoading());
    }

    try {
      final sessions = await _repo.getSessions();
      AppCacheManager.instance.setGigiSessions(sessions);
      if (sessions.isNotEmpty) {
        final latestSessionId = sessions.first['id'] as String;
        final history = await _repo.getHistory(latestSessionId);
        AppCacheManager.instance.setGigiHistory(latestSessionId, history);
        emit(ChatSuccess(
          messages: history,
          sessionId: latestSessionId,
          sessions: sessions,
          hasReachedMax: history.length < 20,
        ));
      } else {
        emit(ChatSuccess(messages: const [], sessions: sessions));
      }
    } catch (e) {
      if (cachedSessions == null || cachedSessions.isEmpty) {
        emit(ChatError(e.toString()));
      }
    }
  }

  void _onStartNewSession(StartNewSession event, Emitter<ChatState> emit) {
    if (state is ChatSuccess) {
      final currentState = state as ChatSuccess;
      emit(currentState.copyWith(
        messages: const [],
        sessionId: null,
        hasReachedMax: false,
        isLoadingMore: false,
      ));
    } else {
      emit(const ChatSuccess(messages: []));
    }
  }

  Future<void> _onSelectSession(SelectSession event, Emitter<ChatState> emit) async {
    final sessions =
        state is ChatSuccess ? (state as ChatSuccess).sessions : const <dynamic>[];
    final cachedHistory = AppCacheManager.instance.getGigiHistory(event.sessionId);
    if (cachedHistory != null && cachedHistory.isNotEmpty) {
      emit(ChatSuccess(
        messages: cachedHistory,
        sessionId: event.sessionId,
        sessions: sessions,
        hasReachedMax: cachedHistory.length < 20,
      ));
    } else {
      emit(ChatLoading());
    }

    try {
      final history = await _repo.getHistory(event.sessionId);
      AppCacheManager.instance.setGigiHistory(event.sessionId, history);
      final allSessions = sessions.isNotEmpty ? sessions : await _repo.getSessions();
      emit(ChatSuccess(
        messages: history,
        sessionId: event.sessionId,
        sessions: allSessions,
        hasReachedMax: history.length < 20,
      ));
    } catch (e) {
      if (cachedHistory == null) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onCreateSession(CreateSession event, Emitter<ChatState> emit) async {
    final sessions = state is ChatSuccess ? (state as ChatSuccess).sessions : const <dynamic>[];

    final optimisticMsg = {
      'id': 'temp-id-${DateTime.now().millisecondsSinceEpoch}',
      'content': event.initialMessage,
      'sender': 'USER',
      'createdAt': DateTime.now().toIso8601String(),
    };

    emit(ChatSuccess(
      messages: [optimisticMsg],
      isSending: true,
      sessions: sessions,
      hasReachedMax: true,
    ));

    try {
      final result = await _repo.sendMessage(event.initialMessage, moodCode: event.moodCode);
      final updatedSessions = await _repo.getSessions();
      final newSessionId = result['sessionId'] as String;
      final newMessages = [optimisticMsg, result['message']];

      AppCacheManager.instance.setGigiSessions(updatedSessions);
      AppCacheManager.instance.setGigiHistory(newSessionId, newMessages);

      emit(ChatSuccess(
        messages: newMessages,
        sessionId: newSessionId,
        sessions: updatedSessions,
        hasReachedMax: true,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<ChatState> emit) async {
    final sessions =
        state is ChatSuccess ? (state as ChatSuccess).sessions : const <dynamic>[];
    final cachedHistory = AppCacheManager.instance.getGigiHistory(event.sessionId);
    if (cachedHistory != null && cachedHistory.isNotEmpty) {
      emit(ChatSuccess(
        messages: cachedHistory,
        sessionId: event.sessionId,
        sessions: sessions,
        hasReachedMax: cachedHistory.length < 20,
      ));
    } else {
      emit(ChatLoading());
    }

    try {
      final history = await _repo.getHistory(event.sessionId);
      AppCacheManager.instance.setGigiHistory(event.sessionId, history);
      emit(ChatSuccess(
        messages: history,
        sessionId: event.sessionId,
        sessions: sessions,
        hasReachedMax: history.length < 20,
      ));
    } catch (e) {
      if (cachedHistory == null) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMoreHistory(LoadMoreHistory event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccess) return;
    final currentState = state as ChatSuccess;
    
    if (currentState.hasReachedMax || currentState.isLoadingMore || currentState.sessionId == null || currentState.messages.isEmpty) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final earliestMessage = currentState.messages.first;
      final cursorId = earliestMessage['id'] as String?;
      
      if (cursorId == null) {
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      final olderMessages = await _repo.getHistory(currentState.sessionId!, cursor: cursorId);
      final combined = [...olderMessages, ...currentState.messages];
      AppCacheManager.instance.setGigiHistory(currentState.sessionId!, combined);
      
      emit(currentState.copyWith(
        messages: combined,
        isLoadingMore: false,
        hasReachedMax: olderMessages.length < 20,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSendMessage(SendChatMessage event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccess) return;
    final currentState = state as ChatSuccess;

    final optimisticMsg = {
      'id': 'temp-id-${DateTime.now().millisecondsSinceEpoch}',
      'content': event.content,
      'sender': 'USER',
      'createdAt': DateTime.now().toIso8601String(),
    };

    emit(currentState.copyWith(
      messages: [...currentState.messages, optimisticMsg],
      isSending: true,
    ));

    try {
      final result = await _repo.sendMessage(event.content, sessionId: event.sessionId, moodCode: event.moodCode);
      final latestState = state as ChatSuccess;
      final newMessages = [...latestState.messages, result['message']];
      AppCacheManager.instance.setGigiHistory(event.sessionId, newMessages);

      emit(latestState.copyWith(
        messages: newMessages,
        isSending: false,
      ));
    } catch (e) {
      final latestState = state as ChatSuccess;
      emit(latestState.copyWith(isSending: false));
    }
  }

  Future<void> _onDeleteSession(DeleteSessionEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccess) return;
    final currentState = state as ChatSuccess;
    
    try {
      await _repo.deleteSession(event.sessionId);
      AppCacheManager.instance.clearGigiCache();
      
      final newSessions = currentState.sessions.where((s) => s['id'] != event.sessionId).toList();
      
      if (currentState.sessionId == event.sessionId) {
        emit(currentState.copyWith(
          messages: const [],
          sessionId: null,
          sessions: newSessions,
          hasReachedMax: false,
        ));
      } else {
        emit(currentState.copyWith(sessions: newSessions));
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _onDeleteAllSessions(DeleteAllSessionsEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccess) return;
    final currentState = state as ChatSuccess;
    
    try {
      await _repo.deleteAllSessions();
      AppCacheManager.instance.clearGigiCache();
      
      emit(currentState.copyWith(
        messages: const [],
        sessionId: null,
        sessions: const [],
        hasReachedMax: false,
      ));
    } catch (e) {
      // Silently fail
    }
  }
}
