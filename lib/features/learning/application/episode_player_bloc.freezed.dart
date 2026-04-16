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
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
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
abstract class _$$LoadEpisodeImplCopyWith<$Res> {
  factory _$$LoadEpisodeImplCopyWith(
    _$LoadEpisodeImpl value,
    $Res Function(_$LoadEpisodeImpl) then,
  ) = __$$LoadEpisodeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String episodeId});
}

/// @nodoc
class __$$LoadEpisodeImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$LoadEpisodeImpl>
    implements _$$LoadEpisodeImplCopyWith<$Res> {
  __$$LoadEpisodeImplCopyWithImpl(
    _$LoadEpisodeImpl _value,
    $Res Function(_$LoadEpisodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? episodeId = null}) {
    return _then(
      _$LoadEpisodeImpl(
        null == episodeId
            ? _value.episodeId
            : episodeId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LoadEpisodeImpl implements _LoadEpisode {
  const _$LoadEpisodeImpl(this.episodeId);

  @override
  final String episodeId;

  @override
  String toString() {
    return 'EpisodePlayerEvent.loadEpisode(episodeId: $episodeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadEpisodeImpl &&
            (identical(other.episodeId, episodeId) ||
                other.episodeId == episodeId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, episodeId);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadEpisodeImplCopyWith<_$LoadEpisodeImpl> get copyWith =>
      __$$LoadEpisodeImplCopyWithImpl<_$LoadEpisodeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return loadEpisode(episodeId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return loadEpisode?.call(episodeId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (loadEpisode != null) {
      return loadEpisode(episodeId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return loadEpisode(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return loadEpisode?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (loadEpisode != null) {
      return loadEpisode(this);
    }
    return orElse();
  }
}

abstract class _LoadEpisode implements EpisodePlayerEvent {
  const factory _LoadEpisode(final String episodeId) = _$LoadEpisodeImpl;

  String get episodeId;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadEpisodeImplCopyWith<_$LoadEpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NextSegmentImplCopyWith<$Res> {
  factory _$$NextSegmentImplCopyWith(
    _$NextSegmentImpl value,
    $Res Function(_$NextSegmentImpl) then,
  ) = __$$NextSegmentImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NextSegmentImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$NextSegmentImpl>
    implements _$$NextSegmentImplCopyWith<$Res> {
  __$$NextSegmentImplCopyWithImpl(
    _$NextSegmentImpl _value,
    $Res Function(_$NextSegmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NextSegmentImpl implements _NextSegment {
  const _$NextSegmentImpl();

  @override
  String toString() {
    return 'EpisodePlayerEvent.nextSegment()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NextSegmentImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return nextSegment();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return nextSegment?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (nextSegment != null) {
      return nextSegment();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return nextSegment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return nextSegment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (nextSegment != null) {
      return nextSegment(this);
    }
    return orElse();
  }
}

abstract class _NextSegment implements EpisodePlayerEvent {
  const factory _NextSegment() = _$NextSegmentImpl;
}

/// @nodoc
abstract class _$$PreviousSegmentImplCopyWith<$Res> {
  factory _$$PreviousSegmentImplCopyWith(
    _$PreviousSegmentImpl value,
    $Res Function(_$PreviousSegmentImpl) then,
  ) = __$$PreviousSegmentImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PreviousSegmentImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$PreviousSegmentImpl>
    implements _$$PreviousSegmentImplCopyWith<$Res> {
  __$$PreviousSegmentImplCopyWithImpl(
    _$PreviousSegmentImpl _value,
    $Res Function(_$PreviousSegmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PreviousSegmentImpl implements _PreviousSegment {
  const _$PreviousSegmentImpl();

  @override
  String toString() {
    return 'EpisodePlayerEvent.previousSegment()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PreviousSegmentImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return previousSegment();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return previousSegment?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (previousSegment != null) {
      return previousSegment();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return previousSegment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return previousSegment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (previousSegment != null) {
      return previousSegment(this);
    }
    return orElse();
  }
}

abstract class _PreviousSegment implements EpisodePlayerEvent {
  const factory _PreviousSegment() = _$PreviousSegmentImpl;
}

/// @nodoc
abstract class _$$JumpToSegmentImplCopyWith<$Res> {
  factory _$$JumpToSegmentImplCopyWith(
    _$JumpToSegmentImpl value,
    $Res Function(_$JumpToSegmentImpl) then,
  ) = __$$JumpToSegmentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int index});
}

/// @nodoc
class __$$JumpToSegmentImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$JumpToSegmentImpl>
    implements _$$JumpToSegmentImplCopyWith<$Res> {
  __$$JumpToSegmentImplCopyWithImpl(
    _$JumpToSegmentImpl _value,
    $Res Function(_$JumpToSegmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? index = null}) {
    return _then(
      _$JumpToSegmentImpl(
        null == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$JumpToSegmentImpl implements _JumpToSegment {
  const _$JumpToSegmentImpl(this.index);

  @override
  final int index;

  @override
  String toString() {
    return 'EpisodePlayerEvent.jumpToSegment(index: $index)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JumpToSegmentImpl &&
            (identical(other.index, index) || other.index == index));
  }

  @override
  int get hashCode => Object.hash(runtimeType, index);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JumpToSegmentImplCopyWith<_$JumpToSegmentImpl> get copyWith =>
      __$$JumpToSegmentImplCopyWithImpl<_$JumpToSegmentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return jumpToSegment(index);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return jumpToSegment?.call(index);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (jumpToSegment != null) {
      return jumpToSegment(index);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return jumpToSegment(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return jumpToSegment?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (jumpToSegment != null) {
      return jumpToSegment(this);
    }
    return orElse();
  }
}

abstract class _JumpToSegment implements EpisodePlayerEvent {
  const factory _JumpToSegment(final int index) = _$JumpToSegmentImpl;

  int get index;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JumpToSegmentImplCopyWith<_$JumpToSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AnswerQuestionImplCopyWith<$Res> {
  factory _$$AnswerQuestionImplCopyWith(
    _$AnswerQuestionImpl value,
    $Res Function(_$AnswerQuestionImpl) then,
  ) = __$$AnswerQuestionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isCorrect, int questionIndex, int answerIndex});
}

/// @nodoc
class __$$AnswerQuestionImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$AnswerQuestionImpl>
    implements _$$AnswerQuestionImplCopyWith<$Res> {
  __$$AnswerQuestionImplCopyWithImpl(
    _$AnswerQuestionImpl _value,
    $Res Function(_$AnswerQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isCorrect = null,
    Object? questionIndex = null,
    Object? answerIndex = null,
  }) {
    return _then(
      _$AnswerQuestionImpl(
        isCorrect: null == isCorrect
            ? _value.isCorrect
            : isCorrect // ignore: cast_nullable_to_non_nullable
                  as bool,
        questionIndex: null == questionIndex
            ? _value.questionIndex
            : questionIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        answerIndex: null == answerIndex
            ? _value.answerIndex
            : answerIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$AnswerQuestionImpl implements _AnswerQuestion {
  const _$AnswerQuestionImpl({
    required this.isCorrect,
    required this.questionIndex,
    required this.answerIndex,
  });

  @override
  final bool isCorrect;
  @override
  final int questionIndex;
  @override
  final int answerIndex;

  @override
  String toString() {
    return 'EpisodePlayerEvent.answerQuestion(isCorrect: $isCorrect, questionIndex: $questionIndex, answerIndex: $answerIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnswerQuestionImpl &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect) &&
            (identical(other.questionIndex, questionIndex) ||
                other.questionIndex == questionIndex) &&
            (identical(other.answerIndex, answerIndex) ||
                other.answerIndex == answerIndex));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isCorrect, questionIndex, answerIndex);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnswerQuestionImplCopyWith<_$AnswerQuestionImpl> get copyWith =>
      __$$AnswerQuestionImplCopyWithImpl<_$AnswerQuestionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return answerQuestion(isCorrect, questionIndex, answerIndex);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return answerQuestion?.call(isCorrect, questionIndex, answerIndex);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (answerQuestion != null) {
      return answerQuestion(isCorrect, questionIndex, answerIndex);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return answerQuestion(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return answerQuestion?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (answerQuestion != null) {
      return answerQuestion(this);
    }
    return orElse();
  }
}

abstract class _AnswerQuestion implements EpisodePlayerEvent {
  const factory _AnswerQuestion({
    required final bool isCorrect,
    required final int questionIndex,
    required final int answerIndex,
  }) = _$AnswerQuestionImpl;

  bool get isCorrect;
  int get questionIndex;
  int get answerIndex;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnswerQuestionImplCopyWith<_$AnswerQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdateReflectionImplCopyWith<$Res> {
  factory _$$UpdateReflectionImplCopyWith(
    _$UpdateReflectionImpl value,
    $Res Function(_$UpdateReflectionImpl) then,
  ) = __$$UpdateReflectionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String mode, String? content});
}

/// @nodoc
class __$$UpdateReflectionImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$UpdateReflectionImpl>
    implements _$$UpdateReflectionImplCopyWith<$Res> {
  __$$UpdateReflectionImplCopyWithImpl(
    _$UpdateReflectionImpl _value,
    $Res Function(_$UpdateReflectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? mode = null, Object? content = freezed}) {
    return _then(
      _$UpdateReflectionImpl(
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as String,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$UpdateReflectionImpl implements _UpdateReflection {
  const _$UpdateReflectionImpl({required this.mode, this.content});

  @override
  final String mode;
  @override
  final String? content;

  @override
  String toString() {
    return 'EpisodePlayerEvent.updateReflection(mode: $mode, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateReflectionImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mode, content);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateReflectionImplCopyWith<_$UpdateReflectionImpl> get copyWith =>
      __$$UpdateReflectionImplCopyWithImpl<_$UpdateReflectionImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return updateReflection(mode, content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return updateReflection?.call(mode, content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (updateReflection != null) {
      return updateReflection(mode, content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return updateReflection(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return updateReflection?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (updateReflection != null) {
      return updateReflection(this);
    }
    return orElse();
  }
}

abstract class _UpdateReflection implements EpisodePlayerEvent {
  const factory _UpdateReflection({
    required final String mode,
    final String? content,
  }) = _$UpdateReflectionImpl;

  String get mode;
  String? get content;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateReflectionImplCopyWith<_$UpdateReflectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompleteEpisodeImplCopyWith<$Res> {
  factory _$$CompleteEpisodeImplCopyWith(
    _$CompleteEpisodeImpl value,
    $Res Function(_$CompleteEpisodeImpl) then,
  ) = __$$CompleteEpisodeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isBingeBonus});
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
  $Res call({Object? isBingeBonus = null}) {
    return _then(
      _$CompleteEpisodeImpl(
        isBingeBonus: null == isBingeBonus
            ? _value.isBingeBonus
            : isBingeBonus // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$CompleteEpisodeImpl implements _CompleteEpisode {
  const _$CompleteEpisodeImpl({this.isBingeBonus = false});

  @override
  @JsonKey()
  final bool isBingeBonus;

  @override
  String toString() {
    return 'EpisodePlayerEvent.completeEpisode(isBingeBonus: $isBingeBonus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompleteEpisodeImpl &&
            (identical(other.isBingeBonus, isBingeBonus) ||
                other.isBingeBonus == isBingeBonus));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isBingeBonus);

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
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return completeEpisode(isBingeBonus);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return completeEpisode?.call(isBingeBonus);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (completeEpisode != null) {
      return completeEpisode(isBingeBonus);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return completeEpisode(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return completeEpisode?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (completeEpisode != null) {
      return completeEpisode(this);
    }
    return orElse();
  }
}

abstract class _CompleteEpisode implements EpisodePlayerEvent {
  const factory _CompleteEpisode({final bool isBingeBonus}) =
      _$CompleteEpisodeImpl;

  bool get isBingeBonus;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompleteEpisodeImplCopyWith<_$CompleteEpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncHistoryImplCopyWith<$Res> {
  factory _$$SyncHistoryImplCopyWith(
    _$SyncHistoryImpl value,
    $Res Function(_$SyncHistoryImpl) then,
  ) = __$$SyncHistoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> history});
}

/// @nodoc
class __$$SyncHistoryImplCopyWithImpl<$Res>
    extends _$EpisodePlayerEventCopyWithImpl<$Res, _$SyncHistoryImpl>
    implements _$$SyncHistoryImplCopyWith<$Res> {
  __$$SyncHistoryImplCopyWithImpl(
    _$SyncHistoryImpl _value,
    $Res Function(_$SyncHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? history = null}) {
    return _then(
      _$SyncHistoryImpl(
        null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$SyncHistoryImpl implements _SyncHistory {
  const _$SyncHistoryImpl(final Map<String, dynamic> history)
    : _history = history;

  final Map<String, dynamic> _history;
  @override
  Map<String, dynamic> get history {
    if (_history is EqualUnmodifiableMapView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_history);
  }

  @override
  String toString() {
    return 'EpisodePlayerEvent.syncHistory(history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncHistoryImpl &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_history));

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncHistoryImplCopyWith<_$SyncHistoryImpl> get copyWith =>
      __$$SyncHistoryImplCopyWithImpl<_$SyncHistoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String episodeId) loadEpisode,
    required TResult Function() nextSegment,
    required TResult Function() previousSegment,
    required TResult Function(int index) jumpToSegment,
    required TResult Function(
      bool isCorrect,
      int questionIndex,
      int answerIndex,
    )
    answerQuestion,
    required TResult Function(String mode, String? content) updateReflection,
    required TResult Function(bool isBingeBonus) completeEpisode,
    required TResult Function(Map<String, dynamic> history) syncHistory,
  }) {
    return syncHistory(history);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String episodeId)? loadEpisode,
    TResult? Function()? nextSegment,
    TResult? Function()? previousSegment,
    TResult? Function(int index)? jumpToSegment,
    TResult? Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult? Function(String mode, String? content)? updateReflection,
    TResult? Function(bool isBingeBonus)? completeEpisode,
    TResult? Function(Map<String, dynamic> history)? syncHistory,
  }) {
    return syncHistory?.call(history);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String episodeId)? loadEpisode,
    TResult Function()? nextSegment,
    TResult Function()? previousSegment,
    TResult Function(int index)? jumpToSegment,
    TResult Function(bool isCorrect, int questionIndex, int answerIndex)?
    answerQuestion,
    TResult Function(String mode, String? content)? updateReflection,
    TResult Function(bool isBingeBonus)? completeEpisode,
    TResult Function(Map<String, dynamic> history)? syncHistory,
    required TResult orElse(),
  }) {
    if (syncHistory != null) {
      return syncHistory(history);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadEpisode value) loadEpisode,
    required TResult Function(_NextSegment value) nextSegment,
    required TResult Function(_PreviousSegment value) previousSegment,
    required TResult Function(_JumpToSegment value) jumpToSegment,
    required TResult Function(_AnswerQuestion value) answerQuestion,
    required TResult Function(_UpdateReflection value) updateReflection,
    required TResult Function(_CompleteEpisode value) completeEpisode,
    required TResult Function(_SyncHistory value) syncHistory,
  }) {
    return syncHistory(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadEpisode value)? loadEpisode,
    TResult? Function(_NextSegment value)? nextSegment,
    TResult? Function(_PreviousSegment value)? previousSegment,
    TResult? Function(_JumpToSegment value)? jumpToSegment,
    TResult? Function(_AnswerQuestion value)? answerQuestion,
    TResult? Function(_UpdateReflection value)? updateReflection,
    TResult? Function(_CompleteEpisode value)? completeEpisode,
    TResult? Function(_SyncHistory value)? syncHistory,
  }) {
    return syncHistory?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadEpisode value)? loadEpisode,
    TResult Function(_NextSegment value)? nextSegment,
    TResult Function(_PreviousSegment value)? previousSegment,
    TResult Function(_JumpToSegment value)? jumpToSegment,
    TResult Function(_AnswerQuestion value)? answerQuestion,
    TResult Function(_UpdateReflection value)? updateReflection,
    TResult Function(_CompleteEpisode value)? completeEpisode,
    TResult Function(_SyncHistory value)? syncHistory,
    required TResult orElse(),
  }) {
    if (syncHistory != null) {
      return syncHistory(this);
    }
    return orElse();
  }
}

abstract class _SyncHistory implements EpisodePlayerEvent {
  const factory _SyncHistory(final Map<String, dynamic> history) =
      _$SyncHistoryImpl;

  Map<String, dynamic> get history;

  /// Create a copy of EpisodePlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncHistoryImplCopyWith<_$SyncHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EpisodePlayerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )
    loaded,
    required TResult Function(
      int pointsEarned,
      Map<String, int> pointsBreakdown,
    )
    completed,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult? Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_EpisodePlayerLoaded value) loaded,
    required TResult Function(_Completed value) completed,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_EpisodePlayerLoaded value)? loaded,
    TResult? Function(_Completed value)? completed,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_EpisodePlayerLoaded value)? loaded,
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
    required TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )
    loaded,
    required TResult Function(
      int pointsEarned,
      Map<String, int> pointsBreakdown,
    )
    completed,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult? Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
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
    required TResult Function(_EpisodePlayerLoaded value) loaded,
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
    TResult? Function(_EpisodePlayerLoaded value)? loaded,
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
    TResult Function(_EpisodePlayerLoaded value)? loaded,
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
    required TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )
    loaded,
    required TResult Function(
      int pointsEarned,
      Map<String, int> pointsBreakdown,
    )
    completed,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult? Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
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
    required TResult Function(_EpisodePlayerLoaded value) loaded,
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
    TResult? Function(_EpisodePlayerLoaded value)? loaded,
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
    TResult Function(_EpisodePlayerLoaded value)? loaded,
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
abstract class _$$EpisodePlayerLoadedImplCopyWith<$Res> {
  factory _$$EpisodePlayerLoadedImplCopyWith(
    _$EpisodePlayerLoadedImpl value,
    $Res Function(_$EpisodePlayerLoadedImpl) then,
  ) = __$$EpisodePlayerLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    Episode episode,
    int currentSegmentIndex,
    int correctAnswers,
    int questionsAnswered,
    String reflectionMode,
    String? reflectionContent,
    bool isCompleting,
    List<int> completedSegmentIndices,
    Map<String, dynamic> history,
    Map<String, int> segmentPoints,
  });

  $EpisodeCopyWith<$Res> get episode;
}

/// @nodoc
class __$$EpisodePlayerLoadedImplCopyWithImpl<$Res>
    extends _$EpisodePlayerStateCopyWithImpl<$Res, _$EpisodePlayerLoadedImpl>
    implements _$$EpisodePlayerLoadedImplCopyWith<$Res> {
  __$$EpisodePlayerLoadedImplCopyWithImpl(
    _$EpisodePlayerLoadedImpl _value,
    $Res Function(_$EpisodePlayerLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? episode = null,
    Object? currentSegmentIndex = null,
    Object? correctAnswers = null,
    Object? questionsAnswered = null,
    Object? reflectionMode = null,
    Object? reflectionContent = freezed,
    Object? isCompleting = null,
    Object? completedSegmentIndices = null,
    Object? history = null,
    Object? segmentPoints = null,
  }) {
    return _then(
      _$EpisodePlayerLoadedImpl(
        episode: null == episode
            ? _value.episode
            : episode // ignore: cast_nullable_to_non_nullable
                  as Episode,
        currentSegmentIndex: null == currentSegmentIndex
            ? _value.currentSegmentIndex
            : currentSegmentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        correctAnswers: null == correctAnswers
            ? _value.correctAnswers
            : correctAnswers // ignore: cast_nullable_to_non_nullable
                  as int,
        questionsAnswered: null == questionsAnswered
            ? _value.questionsAnswered
            : questionsAnswered // ignore: cast_nullable_to_non_nullable
                  as int,
        reflectionMode: null == reflectionMode
            ? _value.reflectionMode
            : reflectionMode // ignore: cast_nullable_to_non_nullable
                  as String,
        reflectionContent: freezed == reflectionContent
            ? _value.reflectionContent
            : reflectionContent // ignore: cast_nullable_to_non_nullable
                  as String?,
        isCompleting: null == isCompleting
            ? _value.isCompleting
            : isCompleting // ignore: cast_nullable_to_non_nullable
                  as bool,
        completedSegmentIndices: null == completedSegmentIndices
            ? _value._completedSegmentIndices
            : completedSegmentIndices // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        segmentPoints: null == segmentPoints
            ? _value._segmentPoints
            : segmentPoints // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EpisodeCopyWith<$Res> get episode {
    return $EpisodeCopyWith<$Res>(_value.episode, (value) {
      return _then(_value.copyWith(episode: value));
    });
  }
}

/// @nodoc

class _$EpisodePlayerLoadedImpl implements _EpisodePlayerLoaded {
  const _$EpisodePlayerLoadedImpl({
    required this.episode,
    this.currentSegmentIndex = 0,
    this.correctAnswers = 0,
    this.questionsAnswered = 0,
    this.reflectionMode = 'private',
    this.reflectionContent,
    this.isCompleting = false,
    final List<int> completedSegmentIndices = const [],
    final Map<String, dynamic> history = const {},
    final Map<String, int> segmentPoints = const {},
  }) : _completedSegmentIndices = completedSegmentIndices,
       _history = history,
       _segmentPoints = segmentPoints;

  @override
  final Episode episode;
  @override
  @JsonKey()
  final int currentSegmentIndex;
  @override
  @JsonKey()
  final int correctAnswers;
  @override
  @JsonKey()
  final int questionsAnswered;
  @override
  @JsonKey()
  final String reflectionMode;
  @override
  final String? reflectionContent;
  @override
  @JsonKey()
  final bool isCompleting;

  /// Backend-reported completed segment indices (0-4).
  final List<int> _completedSegmentIndices;

  /// Backend-reported completed segment indices (0-4).
  @override
  @JsonKey()
  List<int> get completedSegmentIndices {
    if (_completedSegmentIndices is EqualUnmodifiableListView)
      return _completedSegmentIndices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedSegmentIndices);
  }

  final Map<String, dynamic> _history;
  @override
  @JsonKey()
  Map<String, dynamic> get history {
    if (_history is EqualUnmodifiableMapView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_history);
  }

  /// Points breakdown from backend episode content, e.g.
  /// {'hook': 0, 'story': 30, 'knowledgeCheck': 20, 'reflection': 10, 'summary': 25}
  final Map<String, int> _segmentPoints;

  /// Points breakdown from backend episode content, e.g.
  /// {'hook': 0, 'story': 30, 'knowledgeCheck': 20, 'reflection': 10, 'summary': 25}
  @override
  @JsonKey()
  Map<String, int> get segmentPoints {
    if (_segmentPoints is EqualUnmodifiableMapView) return _segmentPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_segmentPoints);
  }

  @override
  String toString() {
    return 'EpisodePlayerState.loaded(episode: $episode, currentSegmentIndex: $currentSegmentIndex, correctAnswers: $correctAnswers, questionsAnswered: $questionsAnswered, reflectionMode: $reflectionMode, reflectionContent: $reflectionContent, isCompleting: $isCompleting, completedSegmentIndices: $completedSegmentIndices, history: $history, segmentPoints: $segmentPoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodePlayerLoadedImpl &&
            (identical(other.episode, episode) || other.episode == episode) &&
            (identical(other.currentSegmentIndex, currentSegmentIndex) ||
                other.currentSegmentIndex == currentSegmentIndex) &&
            (identical(other.correctAnswers, correctAnswers) ||
                other.correctAnswers == correctAnswers) &&
            (identical(other.questionsAnswered, questionsAnswered) ||
                other.questionsAnswered == questionsAnswered) &&
            (identical(other.reflectionMode, reflectionMode) ||
                other.reflectionMode == reflectionMode) &&
            (identical(other.reflectionContent, reflectionContent) ||
                other.reflectionContent == reflectionContent) &&
            (identical(other.isCompleting, isCompleting) ||
                other.isCompleting == isCompleting) &&
            const DeepCollectionEquality().equals(
              other._completedSegmentIndices,
              _completedSegmentIndices,
            ) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            const DeepCollectionEquality().equals(
              other._segmentPoints,
              _segmentPoints,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    episode,
    currentSegmentIndex,
    correctAnswers,
    questionsAnswered,
    reflectionMode,
    reflectionContent,
    isCompleting,
    const DeepCollectionEquality().hash(_completedSegmentIndices),
    const DeepCollectionEquality().hash(_history),
    const DeepCollectionEquality().hash(_segmentPoints),
  );

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodePlayerLoadedImplCopyWith<_$EpisodePlayerLoadedImpl> get copyWith =>
      __$$EpisodePlayerLoadedImplCopyWithImpl<_$EpisodePlayerLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )
    loaded,
    required TResult Function(
      int pointsEarned,
      Map<String, int> pointsBreakdown,
    )
    completed,
    required TResult Function(String message) error,
  }) {
    return loaded(
      episode,
      currentSegmentIndex,
      correctAnswers,
      questionsAnswered,
      reflectionMode,
      reflectionContent,
      isCompleting,
      completedSegmentIndices,
      history,
      segmentPoints,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult? Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(
      episode,
      currentSegmentIndex,
      correctAnswers,
      questionsAnswered,
      reflectionMode,
      reflectionContent,
      isCompleting,
      completedSegmentIndices,
      history,
      segmentPoints,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(
        episode,
        currentSegmentIndex,
        correctAnswers,
        questionsAnswered,
        reflectionMode,
        reflectionContent,
        isCompleting,
        completedSegmentIndices,
        history,
        segmentPoints,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_EpisodePlayerLoaded value) loaded,
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
    TResult? Function(_EpisodePlayerLoaded value)? loaded,
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
    TResult Function(_EpisodePlayerLoaded value)? loaded,
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

abstract class _EpisodePlayerLoaded implements EpisodePlayerState {
  const factory _EpisodePlayerLoaded({
    required final Episode episode,
    final int currentSegmentIndex,
    final int correctAnswers,
    final int questionsAnswered,
    final String reflectionMode,
    final String? reflectionContent,
    final bool isCompleting,
    final List<int> completedSegmentIndices,
    final Map<String, dynamic> history,
    final Map<String, int> segmentPoints,
  }) = _$EpisodePlayerLoadedImpl;

  Episode get episode;
  int get currentSegmentIndex;
  int get correctAnswers;
  int get questionsAnswered;
  String get reflectionMode;
  String? get reflectionContent;
  bool get isCompleting;

  /// Backend-reported completed segment indices (0-4).
  List<int> get completedSegmentIndices;
  Map<String, dynamic> get history;

  /// Points breakdown from backend episode content, e.g.
  /// {'hook': 0, 'story': 30, 'knowledgeCheck': 20, 'reflection': 10, 'summary': 25}
  Map<String, int> get segmentPoints;

  /// Create a copy of EpisodePlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodePlayerLoadedImplCopyWith<_$EpisodePlayerLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompletedImplCopyWith<$Res> {
  factory _$$CompletedImplCopyWith(
    _$CompletedImpl value,
    $Res Function(_$CompletedImpl) then,
  ) = __$$CompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int pointsEarned, Map<String, int> pointsBreakdown});
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
  $Res call({Object? pointsEarned = null, Object? pointsBreakdown = null}) {
    return _then(
      _$CompletedImpl(
        pointsEarned: null == pointsEarned
            ? _value.pointsEarned
            : pointsEarned // ignore: cast_nullable_to_non_nullable
                  as int,
        pointsBreakdown: null == pointsBreakdown
            ? _value._pointsBreakdown
            : pointsBreakdown // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc

class _$CompletedImpl implements _Completed {
  const _$CompletedImpl({
    required this.pointsEarned,
    final Map<String, int> pointsBreakdown = const {},
  }) : _pointsBreakdown = pointsBreakdown;

  @override
  final int pointsEarned;

  /// Full breakdown map returned by backend (may be empty).
  final Map<String, int> _pointsBreakdown;

  /// Full breakdown map returned by backend (may be empty).
  @override
  @JsonKey()
  Map<String, int> get pointsBreakdown {
    if (_pointsBreakdown is EqualUnmodifiableMapView) return _pointsBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_pointsBreakdown);
  }

  @override
  String toString() {
    return 'EpisodePlayerState.completed(pointsEarned: $pointsEarned, pointsBreakdown: $pointsBreakdown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletedImpl &&
            (identical(other.pointsEarned, pointsEarned) ||
                other.pointsEarned == pointsEarned) &&
            const DeepCollectionEquality().equals(
              other._pointsBreakdown,
              _pointsBreakdown,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pointsEarned,
    const DeepCollectionEquality().hash(_pointsBreakdown),
  );

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
    required TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )
    loaded,
    required TResult Function(
      int pointsEarned,
      Map<String, int> pointsBreakdown,
    )
    completed,
    required TResult Function(String message) error,
  }) {
    return completed(pointsEarned, pointsBreakdown);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult? Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult? Function(String message)? error,
  }) {
    return completed?.call(pointsEarned, pointsBreakdown);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(pointsEarned, pointsBreakdown);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_EpisodePlayerLoaded value) loaded,
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
    TResult? Function(_EpisodePlayerLoaded value)? loaded,
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
    TResult Function(_EpisodePlayerLoaded value)? loaded,
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
  const factory _Completed({
    required final int pointsEarned,
    final Map<String, int> pointsBreakdown,
  }) = _$CompletedImpl;

  int get pointsEarned;

  /// Full breakdown map returned by backend (may be empty).
  Map<String, int> get pointsBreakdown;

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
    required TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )
    loaded,
    required TResult Function(
      int pointsEarned,
      Map<String, int> pointsBreakdown,
    )
    completed,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult? Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      Episode episode,
      int currentSegmentIndex,
      int correctAnswers,
      int questionsAnswered,
      String reflectionMode,
      String? reflectionContent,
      bool isCompleting,
      List<int> completedSegmentIndices,
      Map<String, dynamic> history,
      Map<String, int> segmentPoints,
    )?
    loaded,
    TResult Function(int pointsEarned, Map<String, int> pointsBreakdown)?
    completed,
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
    required TResult Function(_EpisodePlayerLoaded value) loaded,
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
    TResult? Function(_EpisodePlayerLoaded value)? loaded,
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
    TResult Function(_EpisodePlayerLoaded value)? loaded,
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
