// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_player_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SummaryPlayerEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadSummary,
    required TResult Function(String itemId, dynamic data) completeItem,
    required TResult Function(String summaryId) submitSummary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadSummary,
    TResult? Function(String itemId, dynamic data)? completeItem,
    TResult? Function(String summaryId)? submitSummary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadSummary,
    TResult Function(String itemId, dynamic data)? completeItem,
    TResult Function(String summaryId)? submitSummary,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadSummary value) loadSummary,
    required TResult Function(_CompleteItem value) completeItem,
    required TResult Function(_SubmitSummary value) submitSummary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadSummary value)? loadSummary,
    TResult? Function(_CompleteItem value)? completeItem,
    TResult? Function(_SubmitSummary value)? submitSummary,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadSummary value)? loadSummary,
    TResult Function(_CompleteItem value)? completeItem,
    TResult Function(_SubmitSummary value)? submitSummary,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SummaryPlayerEventCopyWith<$Res> {
  factory $SummaryPlayerEventCopyWith(
    SummaryPlayerEvent value,
    $Res Function(SummaryPlayerEvent) then,
  ) = _$SummaryPlayerEventCopyWithImpl<$Res, SummaryPlayerEvent>;
}

/// @nodoc
class _$SummaryPlayerEventCopyWithImpl<$Res, $Val extends SummaryPlayerEvent>
    implements $SummaryPlayerEventCopyWith<$Res> {
  _$SummaryPlayerEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadSummaryImplCopyWith<$Res> {
  factory _$$LoadSummaryImplCopyWith(
    _$LoadSummaryImpl value,
    $Res Function(_$LoadSummaryImpl) then,
  ) = __$$LoadSummaryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String journeyId});
}

/// @nodoc
class __$$LoadSummaryImplCopyWithImpl<$Res>
    extends _$SummaryPlayerEventCopyWithImpl<$Res, _$LoadSummaryImpl>
    implements _$$LoadSummaryImplCopyWith<$Res> {
  __$$LoadSummaryImplCopyWithImpl(
    _$LoadSummaryImpl _value,
    $Res Function(_$LoadSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? journeyId = null}) {
    return _then(
      _$LoadSummaryImpl(
        null == journeyId
            ? _value.journeyId
            : journeyId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LoadSummaryImpl implements _LoadSummary {
  const _$LoadSummaryImpl(this.journeyId);

  @override
  final String journeyId;

  @override
  String toString() {
    return 'SummaryPlayerEvent.loadSummary(journeyId: $journeyId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadSummaryImpl &&
            (identical(other.journeyId, journeyId) ||
                other.journeyId == journeyId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, journeyId);

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadSummaryImplCopyWith<_$LoadSummaryImpl> get copyWith =>
      __$$LoadSummaryImplCopyWithImpl<_$LoadSummaryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadSummary,
    required TResult Function(String itemId, dynamic data) completeItem,
    required TResult Function(String summaryId) submitSummary,
  }) {
    return loadSummary(journeyId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadSummary,
    TResult? Function(String itemId, dynamic data)? completeItem,
    TResult? Function(String summaryId)? submitSummary,
  }) {
    return loadSummary?.call(journeyId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadSummary,
    TResult Function(String itemId, dynamic data)? completeItem,
    TResult Function(String summaryId)? submitSummary,
    required TResult orElse(),
  }) {
    if (loadSummary != null) {
      return loadSummary(journeyId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadSummary value) loadSummary,
    required TResult Function(_CompleteItem value) completeItem,
    required TResult Function(_SubmitSummary value) submitSummary,
  }) {
    return loadSummary(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadSummary value)? loadSummary,
    TResult? Function(_CompleteItem value)? completeItem,
    TResult? Function(_SubmitSummary value)? submitSummary,
  }) {
    return loadSummary?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadSummary value)? loadSummary,
    TResult Function(_CompleteItem value)? completeItem,
    TResult Function(_SubmitSummary value)? submitSummary,
    required TResult orElse(),
  }) {
    if (loadSummary != null) {
      return loadSummary(this);
    }
    return orElse();
  }
}

abstract class _LoadSummary implements SummaryPlayerEvent {
  const factory _LoadSummary(final String journeyId) = _$LoadSummaryImpl;

  String get journeyId;

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadSummaryImplCopyWith<_$LoadSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CompleteItemImplCopyWith<$Res> {
  factory _$$CompleteItemImplCopyWith(
    _$CompleteItemImpl value,
    $Res Function(_$CompleteItemImpl) then,
  ) = __$$CompleteItemImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String itemId, dynamic data});
}

/// @nodoc
class __$$CompleteItemImplCopyWithImpl<$Res>
    extends _$SummaryPlayerEventCopyWithImpl<$Res, _$CompleteItemImpl>
    implements _$$CompleteItemImplCopyWith<$Res> {
  __$$CompleteItemImplCopyWithImpl(
    _$CompleteItemImpl _value,
    $Res Function(_$CompleteItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? itemId = null, Object? data = freezed}) {
    return _then(
      _$CompleteItemImpl(
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

class _$CompleteItemImpl implements _CompleteItem {
  const _$CompleteItemImpl(this.itemId, this.data);

  @override
  final String itemId;
  @override
  final dynamic data;

  @override
  String toString() {
    return 'SummaryPlayerEvent.completeItem(itemId: $itemId, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompleteItemImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    const DeepCollectionEquality().hash(data),
  );

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompleteItemImplCopyWith<_$CompleteItemImpl> get copyWith =>
      __$$CompleteItemImplCopyWithImpl<_$CompleteItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadSummary,
    required TResult Function(String itemId, dynamic data) completeItem,
    required TResult Function(String summaryId) submitSummary,
  }) {
    return completeItem(itemId, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadSummary,
    TResult? Function(String itemId, dynamic data)? completeItem,
    TResult? Function(String summaryId)? submitSummary,
  }) {
    return completeItem?.call(itemId, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadSummary,
    TResult Function(String itemId, dynamic data)? completeItem,
    TResult Function(String summaryId)? submitSummary,
    required TResult orElse(),
  }) {
    if (completeItem != null) {
      return completeItem(itemId, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadSummary value) loadSummary,
    required TResult Function(_CompleteItem value) completeItem,
    required TResult Function(_SubmitSummary value) submitSummary,
  }) {
    return completeItem(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadSummary value)? loadSummary,
    TResult? Function(_CompleteItem value)? completeItem,
    TResult? Function(_SubmitSummary value)? submitSummary,
  }) {
    return completeItem?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadSummary value)? loadSummary,
    TResult Function(_CompleteItem value)? completeItem,
    TResult Function(_SubmitSummary value)? submitSummary,
    required TResult orElse(),
  }) {
    if (completeItem != null) {
      return completeItem(this);
    }
    return orElse();
  }
}

abstract class _CompleteItem implements SummaryPlayerEvent {
  const factory _CompleteItem(final String itemId, final dynamic data) =
      _$CompleteItemImpl;

  String get itemId;
  dynamic get data;

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompleteItemImplCopyWith<_$CompleteItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SubmitSummaryImplCopyWith<$Res> {
  factory _$$SubmitSummaryImplCopyWith(
    _$SubmitSummaryImpl value,
    $Res Function(_$SubmitSummaryImpl) then,
  ) = __$$SubmitSummaryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String summaryId});
}

/// @nodoc
class __$$SubmitSummaryImplCopyWithImpl<$Res>
    extends _$SummaryPlayerEventCopyWithImpl<$Res, _$SubmitSummaryImpl>
    implements _$$SubmitSummaryImplCopyWith<$Res> {
  __$$SubmitSummaryImplCopyWithImpl(
    _$SubmitSummaryImpl _value,
    $Res Function(_$SubmitSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? summaryId = null}) {
    return _then(
      _$SubmitSummaryImpl(
        null == summaryId
            ? _value.summaryId
            : summaryId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SubmitSummaryImpl implements _SubmitSummary {
  const _$SubmitSummaryImpl(this.summaryId);

  @override
  final String summaryId;

  @override
  String toString() {
    return 'SummaryPlayerEvent.submitSummary(summaryId: $summaryId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmitSummaryImpl &&
            (identical(other.summaryId, summaryId) ||
                other.summaryId == summaryId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, summaryId);

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmitSummaryImplCopyWith<_$SubmitSummaryImpl> get copyWith =>
      __$$SubmitSummaryImplCopyWithImpl<_$SubmitSummaryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String journeyId) loadSummary,
    required TResult Function(String itemId, dynamic data) completeItem,
    required TResult Function(String summaryId) submitSummary,
  }) {
    return submitSummary(summaryId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String journeyId)? loadSummary,
    TResult? Function(String itemId, dynamic data)? completeItem,
    TResult? Function(String summaryId)? submitSummary,
  }) {
    return submitSummary?.call(summaryId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String journeyId)? loadSummary,
    TResult Function(String itemId, dynamic data)? completeItem,
    TResult Function(String summaryId)? submitSummary,
    required TResult orElse(),
  }) {
    if (submitSummary != null) {
      return submitSummary(summaryId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadSummary value) loadSummary,
    required TResult Function(_CompleteItem value) completeItem,
    required TResult Function(_SubmitSummary value) submitSummary,
  }) {
    return submitSummary(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadSummary value)? loadSummary,
    TResult? Function(_CompleteItem value)? completeItem,
    TResult? Function(_SubmitSummary value)? submitSummary,
  }) {
    return submitSummary?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadSummary value)? loadSummary,
    TResult Function(_CompleteItem value)? completeItem,
    TResult Function(_SubmitSummary value)? submitSummary,
    required TResult orElse(),
  }) {
    if (submitSummary != null) {
      return submitSummary(this);
    }
    return orElse();
  }
}

abstract class _SubmitSummary implements SummaryPlayerEvent {
  const factory _SubmitSummary(final String summaryId) = _$SubmitSummaryImpl;

  String get summaryId;

  /// Create a copy of SummaryPlayerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubmitSummaryImplCopyWith<_$SubmitSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SummaryPlayerState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(LearningJourney journey) loaded,
    required TResult Function() submitting,
    required TResult Function() completed,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function()? completed,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function()? completed,
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
abstract class $SummaryPlayerStateCopyWith<$Res> {
  factory $SummaryPlayerStateCopyWith(
    SummaryPlayerState value,
    $Res Function(SummaryPlayerState) then,
  ) = _$SummaryPlayerStateCopyWithImpl<$Res, SummaryPlayerState>;
}

/// @nodoc
class _$SummaryPlayerStateCopyWithImpl<$Res, $Val extends SummaryPlayerState>
    implements $SummaryPlayerStateCopyWith<$Res> {
  _$SummaryPlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SummaryPlayerState
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
    extends _$SummaryPlayerStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'SummaryPlayerState.initial()';
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
    required TResult Function() completed,
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
    TResult? Function()? completed,
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
    TResult Function()? completed,
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

abstract class _Initial implements SummaryPlayerState {
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
    extends _$SummaryPlayerStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'SummaryPlayerState.loading()';
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
    required TResult Function() completed,
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
    TResult? Function()? completed,
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
    TResult Function()? completed,
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

abstract class _Loading implements SummaryPlayerState {
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
    extends _$SummaryPlayerStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
    _$LoadedImpl _value,
    $Res Function(_$LoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerState
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

  /// Create a copy of SummaryPlayerState
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
    return 'SummaryPlayerState.loaded(journey: $journey)';
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

  /// Create a copy of SummaryPlayerState
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
    required TResult Function() completed,
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
    TResult? Function()? completed,
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
    TResult Function()? completed,
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

abstract class _Loaded implements SummaryPlayerState {
  const factory _Loaded(final LearningJourney journey) = _$LoadedImpl;

  LearningJourney get journey;

  /// Create a copy of SummaryPlayerState
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
    extends _$SummaryPlayerStateCopyWithImpl<$Res, _$SubmittingImpl>
    implements _$$SubmittingImplCopyWith<$Res> {
  __$$SubmittingImplCopyWithImpl(
    _$SubmittingImpl _value,
    $Res Function(_$SubmittingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SubmittingImpl implements _Submitting {
  const _$SubmittingImpl();

  @override
  String toString() {
    return 'SummaryPlayerState.submitting()';
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
    required TResult Function() completed,
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
    TResult? Function()? completed,
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
    TResult Function()? completed,
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

abstract class _Submitting implements SummaryPlayerState {
  const factory _Submitting() = _$SubmittingImpl;
}

/// @nodoc
abstract class _$$CompletedImplCopyWith<$Res> {
  factory _$$CompletedImplCopyWith(
    _$CompletedImpl value,
    $Res Function(_$CompletedImpl) then,
  ) = __$$CompletedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CompletedImplCopyWithImpl<$Res>
    extends _$SummaryPlayerStateCopyWithImpl<$Res, _$CompletedImpl>
    implements _$$CompletedImplCopyWith<$Res> {
  __$$CompletedImplCopyWithImpl(
    _$CompletedImpl _value,
    $Res Function(_$CompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CompletedImpl implements _Completed {
  const _$CompletedImpl();

  @override
  String toString() {
    return 'SummaryPlayerState.completed()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$CompletedImpl);
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
    required TResult Function() completed,
    required TResult Function(String message) error,
  }) {
    return completed();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(LearningJourney journey)? loaded,
    TResult? Function()? submitting,
    TResult? Function()? completed,
    TResult? Function(String message)? error,
  }) {
    return completed?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(LearningJourney journey)? loaded,
    TResult Function()? submitting,
    TResult Function()? completed,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed();
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

abstract class _Completed implements SummaryPlayerState {
  const factory _Completed() = _$CompletedImpl;
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
    extends _$SummaryPlayerStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SummaryPlayerState
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
    return 'SummaryPlayerState.error(message: $message)';
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

  /// Create a copy of SummaryPlayerState
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
    required TResult Function() completed,
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
    TResult? Function()? completed,
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
    TResult Function()? completed,
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

abstract class _Error implements SummaryPlayerState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of SummaryPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
