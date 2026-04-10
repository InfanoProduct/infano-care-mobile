// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TrackerEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(Map<String, dynamic> data) logDaily,
    required TResult Function(Map<String, dynamic> data) setup,
    required TResult Function(DateTime start, DateTime end) updatePeriodRange,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(Map<String, dynamic> data)? logDaily,
    TResult? Function(Map<String, dynamic> data)? setup,
    TResult? Function(DateTime start, DateTime end)? updatePeriodRange,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(Map<String, dynamic> data)? logDaily,
    TResult Function(Map<String, dynamic> data)? setup,
    TResult Function(DateTime start, DateTime end)? updatePeriodRange,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_LogDaily value) logDaily,
    required TResult Function(_Setup value) setup,
    required TResult Function(_UpdatePeriodRange value) updatePeriodRange,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_LogDaily value)? logDaily,
    TResult? Function(_Setup value)? setup,
    TResult? Function(_UpdatePeriodRange value)? updatePeriodRange,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_LogDaily value)? logDaily,
    TResult Function(_Setup value)? setup,
    TResult Function(_UpdatePeriodRange value)? updatePeriodRange,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackerEventCopyWith<$Res> {
  factory $TrackerEventCopyWith(
    TrackerEvent value,
    $Res Function(TrackerEvent) then,
  ) = _$TrackerEventCopyWithImpl<$Res, TrackerEvent>;
}

/// @nodoc
class _$TrackerEventCopyWithImpl<$Res, $Val extends TrackerEvent>
    implements $TrackerEventCopyWith<$Res> {
  _$TrackerEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackerEvent
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
    extends _$TrackerEventCopyWithImpl<$Res, _$LoadImpl>
    implements _$$LoadImplCopyWith<$Res> {
  __$$LoadImplCopyWithImpl(_$LoadImpl _value, $Res Function(_$LoadImpl) _then)
    : super(_value, _then);

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadImpl implements _Load {
  const _$LoadImpl();

  @override
  String toString() {
    return 'TrackerEvent.load()';
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
    required TResult Function(Map<String, dynamic> data) logDaily,
    required TResult Function(Map<String, dynamic> data) setup,
    required TResult Function(DateTime start, DateTime end) updatePeriodRange,
  }) {
    return load();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(Map<String, dynamic> data)? logDaily,
    TResult? Function(Map<String, dynamic> data)? setup,
    TResult? Function(DateTime start, DateTime end)? updatePeriodRange,
  }) {
    return load?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(Map<String, dynamic> data)? logDaily,
    TResult Function(Map<String, dynamic> data)? setup,
    TResult Function(DateTime start, DateTime end)? updatePeriodRange,
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
    required TResult Function(_LogDaily value) logDaily,
    required TResult Function(_Setup value) setup,
    required TResult Function(_UpdatePeriodRange value) updatePeriodRange,
  }) {
    return load(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_LogDaily value)? logDaily,
    TResult? Function(_Setup value)? setup,
    TResult? Function(_UpdatePeriodRange value)? updatePeriodRange,
  }) {
    return load?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_LogDaily value)? logDaily,
    TResult Function(_Setup value)? setup,
    TResult Function(_UpdatePeriodRange value)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (load != null) {
      return load(this);
    }
    return orElse();
  }
}

abstract class _Load implements TrackerEvent {
  const factory _Load() = _$LoadImpl;
}

/// @nodoc
abstract class _$$LogDailyImplCopyWith<$Res> {
  factory _$$LogDailyImplCopyWith(
    _$LogDailyImpl value,
    $Res Function(_$LogDailyImpl) then,
  ) = __$$LogDailyImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> data});
}

/// @nodoc
class __$$LogDailyImplCopyWithImpl<$Res>
    extends _$TrackerEventCopyWithImpl<$Res, _$LogDailyImpl>
    implements _$$LogDailyImplCopyWith<$Res> {
  __$$LogDailyImplCopyWithImpl(
    _$LogDailyImpl _value,
    $Res Function(_$LogDailyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$LogDailyImpl(
        null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$LogDailyImpl implements _LogDaily {
  const _$LogDailyImpl(final Map<String, dynamic> data) : _data = data;

  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  String toString() {
    return 'TrackerEvent.logDaily(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LogDailyImpl &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_data));

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LogDailyImplCopyWith<_$LogDailyImpl> get copyWith =>
      __$$LogDailyImplCopyWithImpl<_$LogDailyImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(Map<String, dynamic> data) logDaily,
    required TResult Function(Map<String, dynamic> data) setup,
    required TResult Function(DateTime start, DateTime end) updatePeriodRange,
  }) {
    return logDaily(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(Map<String, dynamic> data)? logDaily,
    TResult? Function(Map<String, dynamic> data)? setup,
    TResult? Function(DateTime start, DateTime end)? updatePeriodRange,
  }) {
    return logDaily?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(Map<String, dynamic> data)? logDaily,
    TResult Function(Map<String, dynamic> data)? setup,
    TResult Function(DateTime start, DateTime end)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (logDaily != null) {
      return logDaily(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_LogDaily value) logDaily,
    required TResult Function(_Setup value) setup,
    required TResult Function(_UpdatePeriodRange value) updatePeriodRange,
  }) {
    return logDaily(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_LogDaily value)? logDaily,
    TResult? Function(_Setup value)? setup,
    TResult? Function(_UpdatePeriodRange value)? updatePeriodRange,
  }) {
    return logDaily?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_LogDaily value)? logDaily,
    TResult Function(_Setup value)? setup,
    TResult Function(_UpdatePeriodRange value)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (logDaily != null) {
      return logDaily(this);
    }
    return orElse();
  }
}

abstract class _LogDaily implements TrackerEvent {
  const factory _LogDaily(final Map<String, dynamic> data) = _$LogDailyImpl;

  Map<String, dynamic> get data;

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LogDailyImplCopyWith<_$LogDailyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SetupImplCopyWith<$Res> {
  factory _$$SetupImplCopyWith(
    _$SetupImpl value,
    $Res Function(_$SetupImpl) then,
  ) = __$$SetupImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Map<String, dynamic> data});
}

/// @nodoc
class __$$SetupImplCopyWithImpl<$Res>
    extends _$TrackerEventCopyWithImpl<$Res, _$SetupImpl>
    implements _$$SetupImplCopyWith<$Res> {
  __$$SetupImplCopyWithImpl(
    _$SetupImpl _value,
    $Res Function(_$SetupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? data = null}) {
    return _then(
      _$SetupImpl(
        null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$SetupImpl implements _Setup {
  const _$SetupImpl(final Map<String, dynamic> data) : _data = data;

  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  String toString() {
    return 'TrackerEvent.setup(data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetupImpl &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_data));

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetupImplCopyWith<_$SetupImpl> get copyWith =>
      __$$SetupImplCopyWithImpl<_$SetupImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(Map<String, dynamic> data) logDaily,
    required TResult Function(Map<String, dynamic> data) setup,
    required TResult Function(DateTime start, DateTime end) updatePeriodRange,
  }) {
    return setup(data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(Map<String, dynamic> data)? logDaily,
    TResult? Function(Map<String, dynamic> data)? setup,
    TResult? Function(DateTime start, DateTime end)? updatePeriodRange,
  }) {
    return setup?.call(data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(Map<String, dynamic> data)? logDaily,
    TResult Function(Map<String, dynamic> data)? setup,
    TResult Function(DateTime start, DateTime end)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (setup != null) {
      return setup(data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_LogDaily value) logDaily,
    required TResult Function(_Setup value) setup,
    required TResult Function(_UpdatePeriodRange value) updatePeriodRange,
  }) {
    return setup(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_LogDaily value)? logDaily,
    TResult? Function(_Setup value)? setup,
    TResult? Function(_UpdatePeriodRange value)? updatePeriodRange,
  }) {
    return setup?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_LogDaily value)? logDaily,
    TResult Function(_Setup value)? setup,
    TResult Function(_UpdatePeriodRange value)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (setup != null) {
      return setup(this);
    }
    return orElse();
  }
}

abstract class _Setup implements TrackerEvent {
  const factory _Setup(final Map<String, dynamic> data) = _$SetupImpl;

  Map<String, dynamic> get data;

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetupImplCopyWith<_$SetupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UpdatePeriodRangeImplCopyWith<$Res> {
  factory _$$UpdatePeriodRangeImplCopyWith(
    _$UpdatePeriodRangeImpl value,
    $Res Function(_$UpdatePeriodRangeImpl) then,
  ) = __$$UpdatePeriodRangeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class __$$UpdatePeriodRangeImplCopyWithImpl<$Res>
    extends _$TrackerEventCopyWithImpl<$Res, _$UpdatePeriodRangeImpl>
    implements _$$UpdatePeriodRangeImplCopyWith<$Res> {
  __$$UpdatePeriodRangeImplCopyWithImpl(
    _$UpdatePeriodRangeImpl _value,
    $Res Function(_$UpdatePeriodRangeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? start = null, Object? end = null}) {
    return _then(
      _$UpdatePeriodRangeImpl(
        null == start
            ? _value.start
            : start // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        null == end
            ? _value.end
            : end // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$UpdatePeriodRangeImpl implements _UpdatePeriodRange {
  const _$UpdatePeriodRangeImpl(this.start, this.end);

  @override
  final DateTime start;
  @override
  final DateTime end;

  @override
  String toString() {
    return 'TrackerEvent.updatePeriodRange(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdatePeriodRangeImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @override
  int get hashCode => Object.hash(runtimeType, start, end);

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdatePeriodRangeImplCopyWith<_$UpdatePeriodRangeImpl> get copyWith =>
      __$$UpdatePeriodRangeImplCopyWithImpl<_$UpdatePeriodRangeImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() load,
    required TResult Function(Map<String, dynamic> data) logDaily,
    required TResult Function(Map<String, dynamic> data) setup,
    required TResult Function(DateTime start, DateTime end) updatePeriodRange,
  }) {
    return updatePeriodRange(start, end);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? load,
    TResult? Function(Map<String, dynamic> data)? logDaily,
    TResult? Function(Map<String, dynamic> data)? setup,
    TResult? Function(DateTime start, DateTime end)? updatePeriodRange,
  }) {
    return updatePeriodRange?.call(start, end);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? load,
    TResult Function(Map<String, dynamic> data)? logDaily,
    TResult Function(Map<String, dynamic> data)? setup,
    TResult Function(DateTime start, DateTime end)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (updatePeriodRange != null) {
      return updatePeriodRange(start, end);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Load value) load,
    required TResult Function(_LogDaily value) logDaily,
    required TResult Function(_Setup value) setup,
    required TResult Function(_UpdatePeriodRange value) updatePeriodRange,
  }) {
    return updatePeriodRange(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Load value)? load,
    TResult? Function(_LogDaily value)? logDaily,
    TResult? Function(_Setup value)? setup,
    TResult? Function(_UpdatePeriodRange value)? updatePeriodRange,
  }) {
    return updatePeriodRange?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Load value)? load,
    TResult Function(_LogDaily value)? logDaily,
    TResult Function(_Setup value)? setup,
    TResult Function(_UpdatePeriodRange value)? updatePeriodRange,
    required TResult orElse(),
  }) {
    if (updatePeriodRange != null) {
      return updatePeriodRange(this);
    }
    return orElse();
  }
}

abstract class _UpdatePeriodRange implements TrackerEvent {
  const factory _UpdatePeriodRange(final DateTime start, final DateTime end) =
      _$UpdatePeriodRangeImpl;

  DateTime get start;
  DateTime get end;

  /// Create a copy of TrackerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdatePeriodRangeImplCopyWith<_$UpdatePeriodRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TrackerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )
    loaded,
    required TResult Function() notStarted,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult? Function()? notStarted,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult Function()? notStarted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_NotStarted value) notStarted,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_NotStarted value)? notStarted,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_NotStarted value)? notStarted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackerStateCopyWith<$Res> {
  factory $TrackerStateCopyWith(
    TrackerState value,
    $Res Function(TrackerState) then,
  ) = _$TrackerStateCopyWithImpl<$Res, TrackerState>;
}

/// @nodoc
class _$TrackerStateCopyWithImpl<$Res, $Val extends TrackerState>
    implements $TrackerStateCopyWith<$Res> {
  _$TrackerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackerState
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
    extends _$TrackerStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'TrackerState.initial()';
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )
    loaded,
    required TResult Function() notStarted,
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult? Function()? notStarted,
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult Function()? notStarted,
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
    required TResult Function(_NotStarted value) notStarted,
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
    TResult? Function(_NotStarted value)? notStarted,
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
    TResult Function(_NotStarted value)? notStarted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements TrackerState {
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
    extends _$TrackerStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'TrackerState.loading()';
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )
    loaded,
    required TResult Function() notStarted,
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult? Function()? notStarted,
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult Function()? notStarted,
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
    required TResult Function(_NotStarted value) notStarted,
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
    TResult? Function(_NotStarted value)? notStarted,
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
    TResult Function(_NotStarted value)? notStarted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements TrackerState {
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
    CycleProfileModel profile,
    PredictionResultModel? prediction,
    List<CycleLogModel> recentLogs,
    List<CycleRecordModel> history,
    String? milestone,
  });

  $CycleProfileModelCopyWith<$Res> get profile;
  $PredictionResultModelCopyWith<$Res>? get prediction;
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$TrackerStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
    _$LoadedImpl _value,
    $Res Function(_$LoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? prediction = freezed,
    Object? recentLogs = null,
    Object? history = null,
    Object? milestone = freezed,
  }) {
    return _then(
      _$LoadedImpl(
        profile: null == profile
            ? _value.profile
            : profile // ignore: cast_nullable_to_non_nullable
                  as CycleProfileModel,
        prediction: freezed == prediction
            ? _value.prediction
            : prediction // ignore: cast_nullable_to_non_nullable
                  as PredictionResultModel?,
        recentLogs: null == recentLogs
            ? _value._recentLogs
            : recentLogs // ignore: cast_nullable_to_non_nullable
                  as List<CycleLogModel>,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<CycleRecordModel>,
        milestone: freezed == milestone
            ? _value.milestone
            : milestone // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CycleProfileModelCopyWith<$Res> get profile {
    return $CycleProfileModelCopyWith<$Res>(_value.profile, (value) {
      return _then(_value.copyWith(profile: value));
    });
  }

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PredictionResultModelCopyWith<$Res>? get prediction {
    if (_value.prediction == null) {
      return null;
    }

    return $PredictionResultModelCopyWith<$Res>(_value.prediction!, (value) {
      return _then(_value.copyWith(prediction: value));
    });
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl({
    required this.profile,
    this.prediction,
    final List<CycleLogModel> recentLogs = const [],
    final List<CycleRecordModel> history = const [],
    this.milestone,
  }) : _recentLogs = recentLogs,
       _history = history;

  @override
  final CycleProfileModel profile;
  @override
  final PredictionResultModel? prediction;
  final List<CycleLogModel> _recentLogs;
  @override
  @JsonKey()
  List<CycleLogModel> get recentLogs {
    if (_recentLogs is EqualUnmodifiableListView) return _recentLogs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentLogs);
  }

  final List<CycleRecordModel> _history;
  @override
  @JsonKey()
  List<CycleRecordModel> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  final String? milestone;

  @override
  String toString() {
    return 'TrackerState.loaded(profile: $profile, prediction: $prediction, recentLogs: $recentLogs, history: $history, milestone: $milestone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.prediction, prediction) ||
                other.prediction == prediction) &&
            const DeepCollectionEquality().equals(
              other._recentLogs,
              _recentLogs,
            ) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.milestone, milestone) ||
                other.milestone == milestone));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    profile,
    prediction,
    const DeepCollectionEquality().hash(_recentLogs),
    const DeepCollectionEquality().hash(_history),
    milestone,
  );

  /// Create a copy of TrackerState
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )
    loaded,
    required TResult Function() notStarted,
    required TResult Function(String message) error,
  }) {
    return loaded(profile, prediction, recentLogs, history, milestone);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult? Function()? notStarted,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(profile, prediction, recentLogs, history, milestone);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult Function()? notStarted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(profile, prediction, recentLogs, history, milestone);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_NotStarted value) notStarted,
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
    TResult? Function(_NotStarted value)? notStarted,
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
    TResult Function(_NotStarted value)? notStarted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements TrackerState {
  const factory _Loaded({
    required final CycleProfileModel profile,
    final PredictionResultModel? prediction,
    final List<CycleLogModel> recentLogs,
    final List<CycleRecordModel> history,
    final String? milestone,
  }) = _$LoadedImpl;

  CycleProfileModel get profile;
  PredictionResultModel? get prediction;
  List<CycleLogModel> get recentLogs;
  List<CycleRecordModel> get history;
  String? get milestone;

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotStartedImplCopyWith<$Res> {
  factory _$$NotStartedImplCopyWith(
    _$NotStartedImpl value,
    $Res Function(_$NotStartedImpl) then,
  ) = __$$NotStartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NotStartedImplCopyWithImpl<$Res>
    extends _$TrackerStateCopyWithImpl<$Res, _$NotStartedImpl>
    implements _$$NotStartedImplCopyWith<$Res> {
  __$$NotStartedImplCopyWithImpl(
    _$NotStartedImpl _value,
    $Res Function(_$NotStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NotStartedImpl implements _NotStarted {
  const _$NotStartedImpl();

  @override
  String toString() {
    return 'TrackerState.notStarted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NotStartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )
    loaded,
    required TResult Function() notStarted,
    required TResult Function(String message) error,
  }) {
    return notStarted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult? Function()? notStarted,
    TResult? Function(String message)? error,
  }) {
    return notStarted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult Function()? notStarted,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (notStarted != null) {
      return notStarted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_NotStarted value) notStarted,
    required TResult Function(_Error value) error,
  }) {
    return notStarted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_NotStarted value)? notStarted,
    TResult? Function(_Error value)? error,
  }) {
    return notStarted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_NotStarted value)? notStarted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (notStarted != null) {
      return notStarted(this);
    }
    return orElse();
  }
}

abstract class _NotStarted implements TrackerState {
  const factory _NotStarted() = _$NotStartedImpl;
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
    extends _$TrackerStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrackerState
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
    return 'TrackerState.error(message: $message)';
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

  /// Create a copy of TrackerState
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )
    loaded,
    required TResult Function() notStarted,
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult? Function()? notStarted,
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
      CycleProfileModel profile,
      PredictionResultModel? prediction,
      List<CycleLogModel> recentLogs,
      List<CycleRecordModel> history,
      String? milestone,
    )?
    loaded,
    TResult Function()? notStarted,
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
    required TResult Function(_NotStarted value) notStarted,
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
    TResult? Function(_NotStarted value)? notStarted,
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
    TResult Function(_NotStarted value)? notStarted,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements TrackerState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of TrackerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
