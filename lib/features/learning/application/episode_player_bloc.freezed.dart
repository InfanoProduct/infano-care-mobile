// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode_player_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$EpisodePlayerEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadJourney,
    required TResult Function(String itemId, dynamic data) updateProgress,
    required TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )
    completeEpisode,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadJourney,
    TResult? Function(String itemId, dynamic data)? updateProgress,
    TResult? Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadJourney,
    TResult Function(String itemId, dynamic data)? updateProgress,
    TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadJourney value) loadJourney,
    required TResult Function(_UpdateProgress value) updateProgress,
    required TResult Function(_CompleteEpisode value) completeEpisode,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadJourney value)? loadJourney,
    TResult? Function(_UpdateProgress value)? updateProgress,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadJourney value)? loadJourney,
    TResult Function(_UpdateProgress value)? updateProgress,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodePlayerEventCopyWith<$Res> {
  factory $EpisodePlayerEventCopyWith(
    EpisodePlayerEvent value,
    $Res Function(EpisodePlayerEvent) then,
  ) = _$EpisodePlayerEventCopyWithImpl<$Res, EpisodePlayerEvent>;
}

/// @nodoc
class _$EpisodePlayerEventCopyWithImpl<$Res, $Val extends EpisodePlayerEvent>
    implements $EpisodePlayerEventCopyWith<$Res> {
  _$EpisodePlayerEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadJourneyImplCopyWith<$Res> {
  factory _$$LoadJourneyImplCopyWith(
    _$LoadJourneyImpl value,
    $Res Function(_$LoadJourneyImpl) then,
  ) = __$$LoadJourneyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String journeyId});
}

/// @nodoc
class __$$LoadJourneyImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$LoadJourneyImpl>
    implements _$$LoadJourneyImplCopyWith<$Res> {
  __$$LoadJourneyImplCopyWithImpl(
    _$LoadJourneyImpl _value,
    $Res Function(_$LoadJourneyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? journeyId = null}) {
    return _then(
      _$LoadJourneyImpl(
        null == journeyId
            ? _value.journeyId
            : journeyId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LoadJourneyImpl implements _LoadJourney {
  const _$LoadJourneyImpl(this.journeyId);

  @override
  final String journeyId;

  @override
  String toString() {
    return 'EpisodePlayerEvent.loadJourney(journeyId: $journeyId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadJourneyImpl &&
            (identical(other.journeyId, journeyId) ||
                other.journeyId == journeyId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, journeyId);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadJourneyImplCopyWith<_$LoadJourneyImpl> get copyWith =>
      __$$LoadJourneyImplCopyWithImpl<_$LoadJourneyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadJourney,
    required TResult Function(String itemId, dynamic data) updateProgress,
    required TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )
    completeEpisode,
  }) {
    return loadJourney(journeyId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadJourney,
    TResult? Function(String itemId, dynamic data)? updateProgress,
    TResult? Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
  }) {
    return loadJourney?.call(journeyId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadJourney,
    TResult Function(String itemId, dynamic data)? updateProgress,
    TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
    required TResult orElse(),
  }) {
    if (loadJourney != null) {
      return loadJourney(journeyId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadJourney value) loadJourney,
    required TResult Function(_UpdateProgress value) updateProgress,
    required TResult Function(_CompleteEpisode value) completeEpisode,
  }) {
    return loadJourney(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadJourney value)? loadJourney,
    TResult? Function(_UpdateProgress value)? updateProgress,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
  }) {
    return loadJourney?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadJourney value)? loadJourney,
    TResult Function(_UpdateProgress value)? updateProgress,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    required TResult orElse(),
  }) {
    if (loadJourney != null) {
      return loadJourney(this);
    }
    return orElse();
  }
}

abstract class _LoadJourney implements EpisodePlayerEvent {
  const factory _LoadJourney(final String journeyId) = _$LoadJourneyImpl;

  String get journeyId;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadJourneyImplCopyWith<_$LoadJourneyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateProgressImplCopyWith<$Res> {
  factory _$$UpdateProgressImplCopyWith(
    _$UpdateProgressImpl value,
    $Res Function(_$UpdateProgressImpl) then,
  ) = __$$UpdateProgressImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String itemId, dynamic data});
}

/// @nodoc
class __$$UpdateProgressImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$UpdateProgressImpl>
    implements _$$UpdateProgressImplCopyWith<$Res> {
  __$$UpdateProgressImplCopyWithImpl(
    _$UpdateProgressImpl _value,
    $Res Function(_$UpdateProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? itemId = null, Object? data = freezed}) {
    return _then(
      _$UpdateProgressImpl(
        null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc

class _$UpdateProgressImpl implements _UpdateProgress {
  const _$UpdateProgressImpl(this.itemId, this.data);

  @override
  final String itemId;
  @override
  final dynamic data;

  @override
  String toString() {
    return 'EpisodePlayerEvent.updateProgress(itemId: $itemId, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateProgressImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    const DeepCollectionEquality().hash(data),
  );

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateProgressImplCopyWith<_$UpdateProgressImpl> get copyWith =>
      __$$UpdateProgressImplCopyWithImpl<_$UpdateProgressImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadJourney,
    required TResult Function(String itemId, dynamic data) updateProgress,
    required TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )
    completeEpisode,
  }) {
    return updateProgress(itemId, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadJourney,
    TResult? Function(String itemId, dynamic data)? updateProgress,
    TResult? Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
  }) {
    return updateProgress?.call(itemId, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadJourney,
    TResult Function(String itemId, dynamic data)? updateProgress,
    TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
    required TResult orElse(),
  }) {
    if (updateProgress != null) {
      return updateProgress(itemId, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadJourney value) loadJourney,
    required TResult Function(_UpdateProgress value) updateProgress,
    required TResult Function(_CompleteEpisode value) completeEpisode,
  }) {
    return updateProgress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadJourney value)? loadJourney,
    TResult? Function(_UpdateProgress value)? updateProgress,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
  }) {
    return updateProgress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadJourney value)? loadJourney,
    TResult Function(_UpdateProgress value)? updateProgress,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    required TResult orElse(),
  }) {
    if (updateProgress != null) {
      return updateProgress(this);
    }
    return orElse();
  }
}

abstract class _UpdateProgress implements EpisodePlayerEvent {
  const factory _UpdateProgress(final String itemId, final dynamic data) =
      _$UpdateProgressImpl;

  String get itemId;
  dynamic get data;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateProgressImplCopyWith<_$UpdateProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompleteEpisodeImplCopyWith<$Res> {
  factory _$$CompleteEpisodeImplCopyWith(
    _$CompleteEpisodeImpl value,
    $Res Function(_$CompleteEpisodeImpl) then,
  ) = __$$CompleteEpisodeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String episodeId,
    int knowledgeCheckAccuracy,
    String reflectionMode,
    String? reflectionContent,
    String? voiceUrl,
  });
}

/// @nodoc
class __$$CompleteEpisodeImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$CompleteEpisodeImpl>
    implements _$$CompleteEpisodeImplCopyWith<$Res> {
  __$$CompleteEpisodeImplCopyWithImpl(
    _$CompleteEpisodeImpl _value,
    $Res Function(_$CompleteEpisodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? episodeId = null,
    Object? knowledgeCheckAccuracy = null,
    Object? reflectionMode = null,
    Object? reflectionContent = freezed,
    Object? voiceUrl = freezed,
  }) {
    return _then(
      _$CompleteEpisodeImpl(
        episodeId: null == episodeId
            ? _value.episodeId
            : episodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        knowledgeCheckAccuracy: null == knowledgeCheckAccuracy
            ? _value.knowledgeCheckAccuracy
            : knowledgeCheckAccuracy // ignore: cast_nullable_to_non_nullable
                  as int,
        reflectionMode: null == reflectionMode
            ? _value.reflectionMode
            : reflectionMode // ignore: cast_nullable_to_non_nullable
                  as String,
        reflectionContent: freezed == reflectionContent
            ? _value.reflectionContent
            : reflectionContent // ignore: cast_nullable_to_non_nullable
                  as String?,
        voiceUrl: freezed == voiceUrl
            ? _value.voiceUrl
            : voiceUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$CompleteEpisodeImpl implements _CompleteEpisode {
  const _$CompleteEpisodeImpl({
    required this.episodeId,
    required this.knowledgeCheckAccuracy,
    required this.reflectionMode,
    this.reflectionContent,
    this.voiceUrl,
  });

  @override
  final String episodeId;
  @override
  final int knowledgeCheckAccuracy;
  @override
  final String reflectionMode;
  @override
  final String? reflectionContent;
  @override
  final String? voiceUrl;

  @override
  String toString() {
    return 'EpisodePlayerEvent.completeEpisode(episodeId: $episodeId, knowledgeCheckAccuracy: $knowledgeCheckAccuracy, reflectionMode: $reflectionMode, reflectionContent: $reflectionContent, voiceUrl: $voiceUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompleteEpisodeImpl &&
            (identical(other.episodeId, episodeId) ||
                other.episodeId == episodeId) &&
            (identical(other.knowledgeCheckAccuracy, knowledgeCheckAccuracy) ||
                other.knowledgeCheckAccuracy == knowledgeCheckAccuracy) &&
            (identical(other.reflectionMode, reflectionMode) ||
                other.reflectionMode == reflectionMode) &&
            (identical(other.reflectionContent, reflectionContent) ||
                other.reflectionContent == reflectionContent) &&
            (identical(other.voiceUrl, voiceUrl) ||
                other.voiceUrl == voiceUrl));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    episodeId,
    knowledgeCheckAccuracy,
    reflectionMode,
    reflectionContent,
    voiceUrl,
  );

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompleteEpisodeImplCopyWith<_$CompleteEpisodeImpl> get copyWith =>
      __$$CompleteEpisodeImplCopyWithImpl<_$CompleteEpisodeImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadJourney,
    required TResult Function(String itemId, dynamic data) updateProgress,
    required TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )
    completeEpisode,
  }) {
    return completeEpisode(
      episodeId,
      knowledgeCheckAccuracy,
      reflectionMode,
      reflectionContent,
      voiceUrl,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadJourney,
    TResult? Function(String itemId, dynamic data)? updateProgress,
    TResult? Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
  }) {
    return completeEpisode?.call(
      episodeId,
      knowledgeCheckAccuracy,
      reflectionMode,
      reflectionContent,
      voiceUrl,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadJourney,
    TResult Function(String itemId, dynamic data)? updateProgress,
    TResult Function(
      String episodeId,
      int knowledgeCheckAccuracy,
      String reflectionMode,
      String? reflectionContent,
      String? voiceUrl,
    )?
    completeEpisode,
    required TResult orElse(),
  }) {
    if (completeEpisode != null) {
      return completeEpisode(
        episodeId,
        knowledgeCheckAccuracy,
        reflectionMode,
        reflectionContent,
        voiceUrl,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadJourney value) loadJourney,
    required TResult Function(_UpdateProgress value) updateProgress,
    required TResult Function(_CompleteEpisode value) completeEpisode,
  }) {
    return completeEpisode(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadJourney value)? loadJourney,
    TResult? Function(_UpdateProgress value)? updateProgress,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
  }) {
    return completeEpisode?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadJourney value)? loadJourney,
    TResult Function(_UpdateProgress value)? updateProgress,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    required TResult orElse(),
  }) {
    if (completeEpisode != null) {
      return completeEpisode(this);
    }
    return orElse();
  }
}

abstract class _CompleteEpisode implements EpisodePlayerEvent {
  const factory _CompleteEpisode({
    required final String episodeId,
    required final int knowledgeCheckAccuracy,
    required final String reflectionMode,
    final String? reflectionContent,
    final String? voiceUrl,
  }) = _$CompleteEpisodeImpl;

  String get episodeId;
  int get knowledgeCheckAccuracy;
  String get reflectionMode;
  String? get reflectionContent;
  String? get voiceUrl;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompleteEpisodeImplCopyWith<_$CompleteEpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EpisodePlayerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodePlayerStateCopyWith<$Res> {
  factory $EpisodePlayerStateCopyWith(
    EpisodePlayerState value,
    $Res Function(EpisodePlayerState) then,
  ) = _$EpisodePlayerStateCopyWithImpl<$Res, EpisodePlayerState>;
}

/// @nodoc
class _$EpisodePlayerStateCopyWithImpl<$Res, $Val extends EpisodePlayerState>
    implements $EpisodePlayerStateCopyWith<$Res> {
  _$EpisodePlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'EpisodePlayerState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements EpisodePlayerState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
    _$LoadingImpl value,
    $Res Function(_$LoadingImpl) then,
  ) = __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'EpisodePlayerState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements EpisodePlayerState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
    _$LoadedImpl value,
    $Res Function(_$LoadedImpl) then,
  ) = __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({LearningJourney journey});

  $LearningJourneyCopyWith<$Res> get journey;
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
    _$LoadedImpl _value,
    $Res Function(_$LoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? journey = null}) {
    return _then(
      _$LoadedImpl(
        null == journey
            ? _value.journey
            : journey // ignore: cast_nullable_to_non_nullable
                  as LearningJourney,
      ),
    );
  }

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LearningJourneyCopyWith<$Res> get journey {
    return $LearningJourneyCopyWith<$Res>(_value.journey, (value) {
      return _then(_value.copyWith(journey: value));
    });
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl(this.journey);

  @override
  final LearningJourney journey;

  @override
  String toString() {
    return 'EpisodePlayerState.loaded(journey: $journey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            (identical(other.journey, journey) || other.journey == journey));
  }

  @override
  int get hashCode => Object.hash(runtimeType, journey);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) {
    return loaded(journey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(journey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(journey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements EpisodePlayerState {
  const factory _Loaded(final LearningJourney journey) = _$LoadedImpl;

  LearningJourney get journey;

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SubmittingImplCopyWith<$Res> {
  factory _$$SubmittingImplCopyWith(
    _$SubmittingImpl value,
    $Res Function(_$SubmittingImpl) then,
  ) = __$$SubmittingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SubmittingImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$SubmittingImpl>
    implements _$$SubmittingImplCopyWith<$Res> {
  __$$SubmittingImplCopyWithImpl(
    _$SubmittingImpl _value,
    $Res Function(_$SubmittingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SubmittingImpl implements _Submitting {
  const _$SubmittingImpl();

  @override
  String toString() {
    return 'EpisodePlayerState.submitting()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SubmittingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) {
    return submitting();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) {
    return submitting?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (submitting != null) {
      return submitting();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) {
    return submitting(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) {
    return submitting?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (submitting != null) {
      return submitting(this);
    }
    return orElse();
  }
}

abstract class _Submitting implements EpisodePlayerState {
  const factory _Submitting() = _$SubmittingImpl;
}

/// @nodoc
abstract class _$$CompletedImplCopyWith<$Res> {
  factory _$$CompletedImplCopyWith(
    _$CompletedImpl value,
    $Res Function(_$CompletedImpl) then,
  ) = __$$CompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int pointsEarned});
}

/// @nodoc
class __$$CompletedImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$CompletedImpl>
    implements _$$CompletedImplCopyWith<$Res> {
  __$$CompletedImplCopyWithImpl(
    _$CompletedImpl _value,
    $Res Function(_$CompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? pointsEarned = null}) {
    return _then(
      _$CompletedImpl(
        pointsEarned: null == pointsEarned
            ? _value.pointsEarned
            : pointsEarned // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$CompletedImpl implements _Completed {
  const _$CompletedImpl({required this.pointsEarned});

  @override
  final int pointsEarned;

  @override
  String toString() {
    return 'EpisodePlayerState.completed(pointsEarned: $pointsEarned)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedImpl &&
            (identical(other.pointsEarned, pointsEarned) ||
                other.pointsEarned == pointsEarned));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pointsEarned);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletedImplCopyWith<_$CompletedImpl> get copyWith =>
      __$$CompletedImplCopyWithImpl<_$CompletedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) {
    return completed(pointsEarned);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) {
    return completed?.call(pointsEarned);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(pointsEarned);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class _Completed implements EpisodePlayerState {
  const factory _Completed({required final int pointsEarned}) = _$CompletedImpl;

  int get pointsEarned;

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletedImplCopyWith<_$CompletedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'EpisodePlayerState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function(int pointsEarned) completed,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function(int pointsEarned)? completed,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function(int pointsEarned)? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Submitting value) submitting,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Submitting value)? submitting,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Submitting value)? submitting,
    TResult Function(_Completed value)? completed,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements EpisodePlayerState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
