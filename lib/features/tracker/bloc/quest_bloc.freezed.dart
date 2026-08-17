// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QuestEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(String id) acceptQuest,
    required TResult Function() refresh,
    required TResult Function() clearCompletedQuest,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(String id)? acceptQuest,
    TResult? Function()? refresh,
    TResult? Function()? clearCompletedQuest,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(String id)? acceptQuest,
    TResult Function()? refresh,
    TResult Function()? clearCompletedQuest,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_AcceptQuest value) acceptQuest,
    required TResult Function(_Refresh value) refresh,
    required TResult Function(_ClearCompletedQuest value) clearCompletedQuest,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_AcceptQuest value)? acceptQuest,
    TResult? Function(_Refresh value)? refresh,
    TResult? Function(_ClearCompletedQuest value)? clearCompletedQuest,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_AcceptQuest value)? acceptQuest,
    TResult Function(_Refresh value)? refresh,
    TResult Function(_ClearCompletedQuest value)? clearCompletedQuest,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestEventCopyWith<$Res> {
  factory $QuestEventCopyWith(
    QuestEvent value,
    $Res Function(QuestEvent) then,
  ) = _$QuestEventCopyWithImpl<$Res, QuestEvent>;
}

/// @nodoc
class _$QuestEventCopyWithImpl<$Res, $Val extends QuestEvent>
    implements $QuestEventCopyWith<$Res> {
  _$QuestEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadImplCopyWith<$Res> {
  factory _$$LoadImplCopyWith(
    _$LoadImpl value,
    $Res Function(_$LoadImpl) then,
  ) = __$$LoadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadImplCopyWithImpl<$Res>
    extends _$QuestEventCopyWithImpl<$Res, _$LoadImpl>
    implements _$$LoadImplCopyWith<$Res> {
  __$$LoadImplCopyWithImpl(_$LoadImpl _value, $Res Function(_$LoadImpl) _then)
    : super(_value, _then);

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadImpl with DiagnosticableTreeMixin implements _Load {
  const _$LoadImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestEvent.load()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'QuestEvent.load'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(String id) acceptQuest,
    required TResult Function() refresh,
    required TResult Function() clearCompletedQuest,
  }) {
    return load();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(String id)? acceptQuest,
    TResult? Function()? refresh,
    TResult? Function()? clearCompletedQuest,
  }) {
    return load?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(String id)? acceptQuest,
    TResult Function()? refresh,
    TResult Function()? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (load != null) {
      return load();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_AcceptQuest value) acceptQuest,
    required TResult Function(_Refresh value) refresh,
    required TResult Function(_ClearCompletedQuest value) clearCompletedQuest,
  }) {
    return load(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_AcceptQuest value)? acceptQuest,
    TResult? Function(_Refresh value)? refresh,
    TResult? Function(_ClearCompletedQuest value)? clearCompletedQuest,
  }) {
    return load?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_AcceptQuest value)? acceptQuest,
    TResult Function(_Refresh value)? refresh,
    TResult Function(_ClearCompletedQuest value)? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (load != null) {
      return load(this);
    }
    return orElse();
  }
}

abstract class _Load implements QuestEvent {
  const factory _Load() = _$LoadImpl;
}

/// @nodoc
abstract class _$$AcceptQuestImplCopyWith<$Res> {
  factory _$$AcceptQuestImplCopyWith(
    _$AcceptQuestImpl value,
    $Res Function(_$AcceptQuestImpl) then,
  ) = __$$AcceptQuestImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$AcceptQuestImplCopyWithImpl<$Res>
    extends _$QuestEventCopyWithImpl<$Res, _$AcceptQuestImpl>
    implements _$$AcceptQuestImplCopyWith<$Res> {
  __$$AcceptQuestImplCopyWithImpl(
    _$AcceptQuestImpl _value,
    $Res Function(_$AcceptQuestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null}) {
    return _then(
      _$AcceptQuestImpl(
        null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AcceptQuestImpl with DiagnosticableTreeMixin implements _AcceptQuest {
  const _$AcceptQuestImpl(this.id);

  @override
  final String id;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestEvent.acceptQuest(id: $id)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'QuestEvent.acceptQuest'))
      ..add(DiagnosticsProperty('id', id));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AcceptQuestImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AcceptQuestImplCopyWith<_$AcceptQuestImpl> get copyWith =>
      __$$AcceptQuestImplCopyWithImpl<_$AcceptQuestImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(String id) acceptQuest,
    required TResult Function() refresh,
    required TResult Function() clearCompletedQuest,
  }) {
    return acceptQuest(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(String id)? acceptQuest,
    TResult? Function()? refresh,
    TResult? Function()? clearCompletedQuest,
  }) {
    return acceptQuest?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(String id)? acceptQuest,
    TResult Function()? refresh,
    TResult Function()? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (acceptQuest != null) {
      return acceptQuest(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_AcceptQuest value) acceptQuest,
    required TResult Function(_Refresh value) refresh,
    required TResult Function(_ClearCompletedQuest value) clearCompletedQuest,
  }) {
    return acceptQuest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_AcceptQuest value)? acceptQuest,
    TResult? Function(_Refresh value)? refresh,
    TResult? Function(_ClearCompletedQuest value)? clearCompletedQuest,
  }) {
    return acceptQuest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_AcceptQuest value)? acceptQuest,
    TResult Function(_Refresh value)? refresh,
    TResult Function(_ClearCompletedQuest value)? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (acceptQuest != null) {
      return acceptQuest(this);
    }
    return orElse();
  }
}

abstract class _AcceptQuest implements QuestEvent {
  const factory _AcceptQuest(final String id) = _$AcceptQuestImpl;

  String get id;

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AcceptQuestImplCopyWith<_$AcceptQuestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RefreshImplCopyWith<$Res> {
  factory _$$RefreshImplCopyWith(
    _$RefreshImpl value,
    $Res Function(_$RefreshImpl) then,
  ) = __$$RefreshImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RefreshImplCopyWithImpl<$Res>
    extends _$QuestEventCopyWithImpl<$Res, _$RefreshImpl>
    implements _$$RefreshImplCopyWith<$Res> {
  __$$RefreshImplCopyWithImpl(
    _$RefreshImpl _value,
    $Res Function(_$RefreshImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$RefreshImpl with DiagnosticableTreeMixin implements _Refresh {
  const _$RefreshImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestEvent.refresh()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'QuestEvent.refresh'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RefreshImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(String id) acceptQuest,
    required TResult Function() refresh,
    required TResult Function() clearCompletedQuest,
  }) {
    return refresh();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(String id)? acceptQuest,
    TResult? Function()? refresh,
    TResult? Function()? clearCompletedQuest,
  }) {
    return refresh?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(String id)? acceptQuest,
    TResult Function()? refresh,
    TResult Function()? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (refresh != null) {
      return refresh();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_AcceptQuest value) acceptQuest,
    required TResult Function(_Refresh value) refresh,
    required TResult Function(_ClearCompletedQuest value) clearCompletedQuest,
  }) {
    return refresh(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_AcceptQuest value)? acceptQuest,
    TResult? Function(_Refresh value)? refresh,
    TResult? Function(_ClearCompletedQuest value)? clearCompletedQuest,
  }) {
    return refresh?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_AcceptQuest value)? acceptQuest,
    TResult Function(_Refresh value)? refresh,
    TResult Function(_ClearCompletedQuest value)? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (refresh != null) {
      return refresh(this);
    }
    return orElse();
  }
}

abstract class _Refresh implements QuestEvent {
  const factory _Refresh() = _$RefreshImpl;
}

/// @nodoc
abstract class _$$ClearCompletedQuestImplCopyWith<$Res> {
  factory _$$ClearCompletedQuestImplCopyWith(
    _$ClearCompletedQuestImpl value,
    $Res Function(_$ClearCompletedQuestImpl) then,
  ) = __$$ClearCompletedQuestImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ClearCompletedQuestImplCopyWithImpl<$Res>
    extends _$QuestEventCopyWithImpl<$Res, _$ClearCompletedQuestImpl>
    implements _$$ClearCompletedQuestImplCopyWith<$Res> {
  __$$ClearCompletedQuestImplCopyWithImpl(
    _$ClearCompletedQuestImpl _value,
    $Res Function(_$ClearCompletedQuestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ClearCompletedQuestImpl
    with DiagnosticableTreeMixin
    implements _ClearCompletedQuest {
  const _$ClearCompletedQuestImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestEvent.clearCompletedQuest()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'QuestEvent.clearCompletedQuest'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClearCompletedQuestImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(String id) acceptQuest,
    required TResult Function() refresh,
    required TResult Function() clearCompletedQuest,
  }) {
    return clearCompletedQuest();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(String id)? acceptQuest,
    TResult? Function()? refresh,
    TResult? Function()? clearCompletedQuest,
  }) {
    return clearCompletedQuest?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(String id)? acceptQuest,
    TResult Function()? refresh,
    TResult Function()? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (clearCompletedQuest != null) {
      return clearCompletedQuest();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_AcceptQuest value) acceptQuest,
    required TResult Function(_Refresh value) refresh,
    required TResult Function(_ClearCompletedQuest value) clearCompletedQuest,
  }) {
    return clearCompletedQuest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_AcceptQuest value)? acceptQuest,
    TResult? Function(_Refresh value)? refresh,
    TResult? Function(_ClearCompletedQuest value)? clearCompletedQuest,
  }) {
    return clearCompletedQuest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_AcceptQuest value)? acceptQuest,
    TResult Function(_Refresh value)? refresh,
    TResult Function(_ClearCompletedQuest value)? clearCompletedQuest,
    required TResult orElse(),
  }) {
    if (clearCompletedQuest != null) {
      return clearCompletedQuest(this);
    }
    return orElse();
  }
}

abstract class _ClearCompletedQuest implements QuestEvent {
  const factory _ClearCompletedQuest() = _$ClearCompletedQuestImpl;
}

/// @nodoc
mixin _$QuestState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )
    loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestStateCopyWith<$Res> {
  factory $QuestStateCopyWith(
    QuestState value,
    $Res Function(QuestState) then,
  ) = _$QuestStateCopyWithImpl<$Res, QuestState>;
}

/// @nodoc
class _$QuestStateCopyWithImpl<$Res, $Val extends QuestState>
    implements $QuestStateCopyWith<$Res> {
  _$QuestStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestState
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
    extends _$QuestStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl with DiagnosticableTreeMixin implements _Initial {
  const _$InitialImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestState.initial()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'QuestState.initial'));
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )
    loaded,
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
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
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements QuestState {
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
    extends _$QuestStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl with DiagnosticableTreeMixin implements _Loading {
  const _$LoadingImpl();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestState.loading()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty('type', 'QuestState.loading'));
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )
    loaded,
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
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
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements QuestState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
    _$LoadedImpl value,
    $Res Function(_$LoadedImpl) then,
  ) = __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<UserQuest> dailyQuests,
    List<WeeklyChallenge> weeklyChallenges,
    UserQuestProgress progress,
    List<Badge> badges,
    bool isRefreshing,
    UserQuest? lastCompletedQuest,
    int? lastLevel,
  });
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$QuestStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
    _$LoadedImpl _value,
    $Res Function(_$LoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyQuests = null,
    Object? weeklyChallenges = null,
    Object? progress = null,
    Object? badges = null,
    Object? isRefreshing = null,
    Object? lastCompletedQuest = freezed,
    Object? lastLevel = freezed,
  }) {
    return _then(
      _$LoadedImpl(
        dailyQuests: null == dailyQuests
            ? _value._dailyQuests
            : dailyQuests // ignore: cast_nullable_to_non_nullable
                  as List<UserQuest>,
        weeklyChallenges: null == weeklyChallenges
            ? _value._weeklyChallenges
            : weeklyChallenges // ignore: cast_nullable_to_non_nullable
                  as List<WeeklyChallenge>,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as UserQuestProgress,
        badges: null == badges
            ? _value._badges
            : badges // ignore: cast_nullable_to_non_nullable
                  as List<Badge>,
        isRefreshing: null == isRefreshing
            ? _value.isRefreshing
            : isRefreshing // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastCompletedQuest: freezed == lastCompletedQuest
            ? _value.lastCompletedQuest
            : lastCompletedQuest // ignore: cast_nullable_to_non_nullable
                  as UserQuest?,
        lastLevel: freezed == lastLevel
            ? _value.lastLevel
            : lastLevel // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$LoadedImpl with DiagnosticableTreeMixin implements _Loaded {
  const _$LoadedImpl({
    required final List<UserQuest> dailyQuests,
    required final List<WeeklyChallenge> weeklyChallenges,
    required this.progress,
    required final List<Badge> badges,
    this.isRefreshing = false,
    this.lastCompletedQuest,
    this.lastLevel,
  }) : _dailyQuests = dailyQuests,
       _weeklyChallenges = weeklyChallenges,
       _badges = badges;

  final List<UserQuest> _dailyQuests;
  @override
  List<UserQuest> get dailyQuests {
    if (_dailyQuests is EqualUnmodifiableListView) return _dailyQuests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dailyQuests);
  }

  final List<WeeklyChallenge> _weeklyChallenges;
  @override
  List<WeeklyChallenge> get weeklyChallenges {
    if (_weeklyChallenges is EqualUnmodifiableListView)
      return _weeklyChallenges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeklyChallenges);
  }

  @override
  final UserQuestProgress progress;
  final List<Badge> _badges;
  @override
  List<Badge> get badges {
    if (_badges is EqualUnmodifiableListView) return _badges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_badges);
  }

  @override
  @JsonKey()
  final bool isRefreshing;
  @override
  final UserQuest? lastCompletedQuest;
  @override
  final int? lastLevel;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestState.loaded(dailyQuests: $dailyQuests, weeklyChallenges: $weeklyChallenges, progress: $progress, badges: $badges, isRefreshing: $isRefreshing, lastCompletedQuest: $lastCompletedQuest, lastLevel: $lastLevel)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'QuestState.loaded'))
      ..add(DiagnosticsProperty('dailyQuests', dailyQuests))
      ..add(DiagnosticsProperty('weeklyChallenges', weeklyChallenges))
      ..add(DiagnosticsProperty('progress', progress))
      ..add(DiagnosticsProperty('badges', badges))
      ..add(DiagnosticsProperty('isRefreshing', isRefreshing))
      ..add(DiagnosticsProperty('lastCompletedQuest', lastCompletedQuest))
      ..add(DiagnosticsProperty('lastLevel', lastLevel));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            const DeepCollectionEquality().equals(
              other._dailyQuests,
              _dailyQuests,
            ) &&
            const DeepCollectionEquality().equals(
              other._weeklyChallenges,
              _weeklyChallenges,
            ) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            const DeepCollectionEquality().equals(other._badges, _badges) &&
            (identical(other.isRefreshing, isRefreshing) ||
                other.isRefreshing == isRefreshing) &&
            (identical(other.lastCompletedQuest, lastCompletedQuest) ||
                other.lastCompletedQuest == lastCompletedQuest) &&
            (identical(other.lastLevel, lastLevel) ||
                other.lastLevel == lastLevel));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_dailyQuests),
    const DeepCollectionEquality().hash(_weeklyChallenges),
    progress,
    const DeepCollectionEquality().hash(_badges),
    isRefreshing,
    lastCompletedQuest,
    lastLevel,
  );

  /// Create a copy of QuestState
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
    required TResult Function(
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )
    loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(
      dailyQuests,
      weeklyChallenges,
      progress,
      badges,
      isRefreshing,
      lastCompletedQuest,
      lastLevel,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(
      dailyQuests,
      weeklyChallenges,
      progress,
      badges,
      isRefreshing,
      lastCompletedQuest,
      lastLevel,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(
        dailyQuests,
        weeklyChallenges,
        progress,
        badges,
        isRefreshing,
        lastCompletedQuest,
        lastLevel,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
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
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements QuestState {
  const factory _Loaded({
    required final List<UserQuest> dailyQuests,
    required final List<WeeklyChallenge> weeklyChallenges,
    required final UserQuestProgress progress,
    required final List<Badge> badges,
    final bool isRefreshing,
    final UserQuest? lastCompletedQuest,
    final int? lastLevel,
  }) = _$LoadedImpl;

  List<UserQuest> get dailyQuests;
  List<WeeklyChallenge> get weeklyChallenges;
  UserQuestProgress get progress;
  List<Badge> get badges;
  bool get isRefreshing;
  UserQuest? get lastCompletedQuest;
  int? get lastLevel;

  /// Create a copy of QuestState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
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
    extends _$QuestStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestState
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

class _$ErrorImpl with DiagnosticableTreeMixin implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'QuestState.error(message: $message)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'QuestState.error'))
      ..add(DiagnosticsProperty('message', message));
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

  /// Create a copy of QuestState
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )
    loaded,
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
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
      List<UserQuest> dailyQuests,
      List<WeeklyChallenge> weeklyChallenges,
      UserQuestProgress progress,
      List<Badge> badges,
      bool isRefreshing,
      UserQuest? lastCompletedQuest,
      int? lastLevel,
    )?
    loaded,
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
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements QuestState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of QuestState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
