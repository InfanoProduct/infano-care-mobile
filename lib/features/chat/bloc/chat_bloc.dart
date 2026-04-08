import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
    emit(ChatLoading());
    try {
      final sessions = await _repo.getSessions();
      emit(ChatSuccess(messages: const [], sessions: sessions));
    } catch (e) {
      emit(ChatError(e.toString()));
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
    emit(ChatLoading());
    try {
      final history = await _repo.getHistory(event.sessionId);
      emit(ChatSuccess(
        messages: history,
        sessionId: event.sessionId,
        sessions: sessions,
        hasReachedMax: history.length < 20, // Check if we fetched less than limit
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onCreateSession(CreateSession event, Emitter<ChatState> emit) async {
    final sessions =
        state is ChatSuccess ? (state as ChatSuccess).sessions : const <dynamic>[];
    emit(ChatLoading());
    try {
      final result = await _repo.sendMessage(event.initialMessage, moodCode: event.moodCode);

      final optimisticMsg = {
        'id': 'temp-id-${DateTime.now().millisecondsSinceEpoch}',
        'content': event.initialMessage,
        'sender': 'USER',
        'createdAt': DateTime.now().toIso8601String(),
      };

      emit(ChatSuccess(
        messages: [optimisticMsg, result['message']],
        sessionId: result['sessionId'],
        sessions: sessions,
        hasReachedMax: true, // It’s a brand new session, so no older history exists yet
      ));

      _refreshSessions(result['sessionId'] as String);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<ChatState> emit) async {
    final sessions =
        state is ChatSuccess ? (state as ChatSuccess).sessions : const <dynamic>[];
    emit(ChatLoading());
    try {
      final history = await _repo.getHistory(event.sessionId);
      emit(ChatSuccess(
        messages: history,
        sessionId: event.sessionId,
        sessions: sessions,
        hasReachedMax: history.length < 20,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
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
      // Find the oldest cursor (the first one chronologically)
      final earliestMessage = currentState.messages.first;
      final cursorId = earliestMessage['id'] as String?;
      
      if (cursorId == null) {
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      final olderMessages = await _repo.getHistory(currentState.sessionId!, cursor: cursorId);
      
      emit(currentState.copyWith(
        messages: [...olderMessages, ...currentState.messages],
        isLoadingMore: false,
        hasReachedMax: olderMessages.length < 20,
      ));
    } catch (e) {
      // Just drop loading state if it fails, let them retry by scrolling again
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

      emit(latestState.copyWith(
        messages: [...latestState.messages, result['message']],
        isSending: false,
      ));
    } catch (e) {
      // Note: Ideally we'd remove the optimistic message on failure, but for simplicity
      // we'll just emit an error or silently catch.
      final latestState = state as ChatSuccess;
      emit(latestState.copyWith(isSending: false));
    }
  }

  Future<void> _onDeleteSession(DeleteSessionEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccess) return;
    final currentState = state as ChatSuccess;
    
    try {
      await _repo.deleteSession(event.sessionId);
      
      // Refresh local state without network call where possible
      final newSessions = currentState.sessions.where((s) => s['id'] != event.sessionId).toList();
      
      if (currentState.sessionId == event.sessionId) {
        // We deleted the active session, switch to new chat
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
      // Silently fail or show toast
    }
  }

  Future<void> _onDeleteAllSessions(DeleteAllSessionsEvent event, Emitter<ChatState> emit) async {
    if (state is! ChatSuccess) return;
    final currentState = state as ChatSuccess;
    
    try {
      await _repo.deleteAllSessions();
      
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

  void _refreshSessions(String currentSessionId) {
    _repo.getSessions().then((sessions) {
      if (state is ChatSuccess) {
        final s = state as ChatSuccess;
        emit(s.copyWith(sessions: sessions));
      }
    }).catchError((_) {});
  }
}
