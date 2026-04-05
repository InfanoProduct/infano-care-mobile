// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CycleProfileModel _$CycleProfileModelFromJson(Map<String, dynamic> json) {
  return _CycleProfileModel.fromJson(json);
}

/// @nodoc
mixin _$CycleProfileModel {
  String get userId => throw _privateConstructorUsedError;
  String get trackerMode =>
      throw _privateConstructorUsedError; // 'active', 'watching_waiting', 'irregular'
  DateTime? get lastPeriodStart => throw _privateConstructorUsedError;
  int get avgCycleLength => throw _privateConstructorUsedError;
  int get avgPeriodDuration => throw _privateConstructorUsedError;
  int get currentLogStreak => throw _privateConstructorUsedError;
  int get longestLogStreak => throw _privateConstructorUsedError;
  DateTime? get lastLogDate => throw _privateConstructorUsedError;
  String? get currentPhase => throw _privateConstructorUsedError;
  int? get currentCycleDay => throw _privateConstructorUsedError;
  DateTime? get predictedNextStart => throw _privateConstructorUsedError;
  DateTime? get predictionWindowEarly => throw _privateConstructorUsedError;
  DateTime? get predictionWindowLate => throw _privateConstructorUsedError;
  String get confidenceLevel => throw _privateConstructorUsedError;

  /// Serializes this CycleProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CycleProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CycleProfileModelCopyWith<CycleProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CycleProfileModelCopyWith<$Res> {
  factory $CycleProfileModelCopyWith(
    CycleProfileModel value,
    $Res Function(CycleProfileModel) then,
  ) = _$CycleProfileModelCopyWithImpl<$Res, CycleProfileModel>;
  @useResult
  $Res call({
    String userId,
    String trackerMode,
    DateTime? lastPeriodStart,
    int avgCycleLength,
    int avgPeriodDuration,
    int currentLogStreak,
    int longestLogStreak,
    DateTime? lastLogDate,
    String? currentPhase,
    int? currentCycleDay,
    DateTime? predictedNextStart,
    DateTime? predictionWindowEarly,
    DateTime? predictionWindowLate,
    String confidenceLevel,
  });
}

/// @nodoc
class _$CycleProfileModelCopyWithImpl<$Res, $Val extends CycleProfileModel>
    implements $CycleProfileModelCopyWith<$Res> {
  _$CycleProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CycleProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? trackerMode = null,
    Object? lastPeriodStart = freezed,
    Object? avgCycleLength = null,
    Object? avgPeriodDuration = null,
    Object? currentLogStreak = null,
    Object? longestLogStreak = null,
    Object? lastLogDate = freezed,
    Object? currentPhase = freezed,
    Object? currentCycleDay = freezed,
    Object? predictedNextStart = freezed,
    Object? predictionWindowEarly = freezed,
    Object? predictionWindowLate = freezed,
    Object? confidenceLevel = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            trackerMode: null == trackerMode
                ? _value.trackerMode
                : trackerMode // ignore: cast_nullable_to_non_nullable
                      as String,
            lastPeriodStart: freezed == lastPeriodStart
                ? _value.lastPeriodStart
                : lastPeriodStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            avgCycleLength: null == avgCycleLength
                ? _value.avgCycleLength
                : avgCycleLength // ignore: cast_nullable_to_non_nullable
                      as int,
            avgPeriodDuration: null == avgPeriodDuration
                ? _value.avgPeriodDuration
                : avgPeriodDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            currentLogStreak: null == currentLogStreak
                ? _value.currentLogStreak
                : currentLogStreak // ignore: cast_nullable_to_non_nullable
                      as int,
            longestLogStreak: null == longestLogStreak
                ? _value.longestLogStreak
                : longestLogStreak // ignore: cast_nullable_to_non_nullable
                      as int,
            lastLogDate: freezed == lastLogDate
                ? _value.lastLogDate
                : lastLogDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            currentPhase: freezed == currentPhase
                ? _value.currentPhase
                : currentPhase // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentCycleDay: freezed == currentCycleDay
                ? _value.currentCycleDay
                : currentCycleDay // ignore: cast_nullable_to_non_nullable
                      as int?,
            predictedNextStart: freezed == predictedNextStart
                ? _value.predictedNextStart
                : predictedNextStart // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            predictionWindowEarly: freezed == predictionWindowEarly
                ? _value.predictionWindowEarly
                : predictionWindowEarly // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            predictionWindowLate: freezed == predictionWindowLate
                ? _value.predictionWindowLate
                : predictionWindowLate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            confidenceLevel: null == confidenceLevel
                ? _value.confidenceLevel
                : confidenceLevel // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CycleProfileModelImplCopyWith<$Res>
    implements $CycleProfileModelCopyWith<$Res> {
  factory _$$CycleProfileModelImplCopyWith(
    _$CycleProfileModelImpl value,
    $Res Function(_$CycleProfileModelImpl) then,
  ) = __$$CycleProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String trackerMode,
    DateTime? lastPeriodStart,
    int avgCycleLength,
    int avgPeriodDuration,
    int currentLogStreak,
    int longestLogStreak,
    DateTime? lastLogDate,
    String? currentPhase,
    int? currentCycleDay,
    DateTime? predictedNextStart,
    DateTime? predictionWindowEarly,
    DateTime? predictionWindowLate,
    String confidenceLevel,
  });
}

/// @nodoc
class __$$CycleProfileModelImplCopyWithImpl<$Res>
    extends _$CycleProfileModelCopyWithImpl<$Res, _$CycleProfileModelImpl>
    implements _$$CycleProfileModelImplCopyWith<$Res> {
  __$$CycleProfileModelImplCopyWithImpl(
    _$CycleProfileModelImpl _value,
    $Res Function(_$CycleProfileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CycleProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? trackerMode = null,
    Object? lastPeriodStart = freezed,
    Object? avgCycleLength = null,
    Object? avgPeriodDuration = null,
    Object? currentLogStreak = null,
    Object? longestLogStreak = null,
    Object? lastLogDate = freezed,
    Object? currentPhase = freezed,
    Object? currentCycleDay = freezed,
    Object? predictedNextStart = freezed,
    Object? predictionWindowEarly = freezed,
    Object? predictionWindowLate = freezed,
    Object? confidenceLevel = null,
  }) {
    return _then(
      _$CycleProfileModelImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        trackerMode: null == trackerMode
            ? _value.trackerMode
            : trackerMode // ignore: cast_nullable_to_non_nullable
                  as String,
        lastPeriodStart: freezed == lastPeriodStart
            ? _value.lastPeriodStart
            : lastPeriodStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        avgCycleLength: null == avgCycleLength
            ? _value.avgCycleLength
            : avgCycleLength // ignore: cast_nullable_to_non_nullable
                  as int,
        avgPeriodDuration: null == avgPeriodDuration
            ? _value.avgPeriodDuration
            : avgPeriodDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        currentLogStreak: null == currentLogStreak
            ? _value.currentLogStreak
            : currentLogStreak // ignore: cast_nullable_to_non_nullable
                  as int,
        longestLogStreak: null == longestLogStreak
            ? _value.longestLogStreak
            : longestLogStreak // ignore: cast_nullable_to_non_nullable
                  as int,
        lastLogDate: freezed == lastLogDate
            ? _value.lastLogDate
            : lastLogDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        currentPhase: freezed == currentPhase
            ? _value.currentPhase
            : currentPhase // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentCycleDay: freezed == currentCycleDay
            ? _value.currentCycleDay
            : currentCycleDay // ignore: cast_nullable_to_non_nullable
                  as int?,
        predictedNextStart: freezed == predictedNextStart
            ? _value.predictedNextStart
            : predictedNextStart // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        predictionWindowEarly: freezed == predictionWindowEarly
            ? _value.predictionWindowEarly
            : predictionWindowEarly // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        predictionWindowLate: freezed == predictionWindowLate
            ? _value.predictionWindowLate
            : predictionWindowLate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        confidenceLevel: null == confidenceLevel
            ? _value.confidenceLevel
            : confidenceLevel // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CycleProfileModelImpl implements _CycleProfileModel {
  const _$CycleProfileModelImpl({
    required this.userId,
    required this.trackerMode,
    required this.lastPeriodStart,
    required this.avgCycleLength,
    required this.avgPeriodDuration,
    required this.currentLogStreak,
    required this.longestLogStreak,
    required this.lastLogDate,
    required this.currentPhase,
    required this.currentCycleDay,
    required this.predictedNextStart,
    required this.predictionWindowEarly,
    required this.predictionWindowLate,
    required this.confidenceLevel,
  });

  factory _$CycleProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CycleProfileModelImplFromJson(json);

  @override
  final String userId;
  @override
  final String trackerMode;
  // 'active', 'watching_waiting', 'irregular'
  @override
  final DateTime? lastPeriodStart;
  @override
  final int avgCycleLength;
  @override
  final int avgPeriodDuration;
  @override
  final int currentLogStreak;
  @override
  final int longestLogStreak;
  @override
  final DateTime? lastLogDate;
  @override
  final String? currentPhase;
  @override
  final int? currentCycleDay;
  @override
  final DateTime? predictedNextStart;
  @override
  final DateTime? predictionWindowEarly;
  @override
  final DateTime? predictionWindowLate;
  @override
  final String confidenceLevel;

  @override
  String toString() {
    return 'CycleProfileModel(userId: $userId, trackerMode: $trackerMode, lastPeriodStart: $lastPeriodStart, avgCycleLength: $avgCycleLength, avgPeriodDuration: $avgPeriodDuration, currentLogStreak: $currentLogStreak, longestLogStreak: $longestLogStreak, lastLogDate: $lastLogDate, currentPhase: $currentPhase, currentCycleDay: $currentCycleDay, predictedNextStart: $predictedNextStart, predictionWindowEarly: $predictionWindowEarly, predictionWindowLate: $predictionWindowLate, confidenceLevel: $confidenceLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CycleProfileModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.trackerMode, trackerMode) ||
                other.trackerMode == trackerMode) &&
            (identical(other.lastPeriodStart, lastPeriodStart) ||
                other.lastPeriodStart == lastPeriodStart) &&
            (identical(other.avgCycleLength, avgCycleLength) ||
                other.avgCycleLength == avgCycleLength) &&
            (identical(other.avgPeriodDuration, avgPeriodDuration) ||
                other.avgPeriodDuration == avgPeriodDuration) &&
            (identical(other.currentLogStreak, currentLogStreak) ||
                other.currentLogStreak == currentLogStreak) &&
            (identical(other.longestLogStreak, longestLogStreak) ||
                other.longestLogStreak == longestLogStreak) &&
            (identical(other.lastLogDate, lastLogDate) ||
                other.lastLogDate == lastLogDate) &&
            (identical(other.currentPhase, currentPhase) ||
                other.currentPhase == currentPhase) &&
            (identical(other.currentCycleDay, currentCycleDay) ||
                other.currentCycleDay == currentCycleDay) &&
            (identical(other.predictedNextStart, predictedNextStart) ||
                other.predictedNextStart == predictedNextStart) &&
            (identical(other.predictionWindowEarly, predictionWindowEarly) ||
                other.predictionWindowEarly == predictionWindowEarly) &&
            (identical(other.predictionWindowLate, predictionWindowLate) ||
                other.predictionWindowLate == predictionWindowLate) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    trackerMode,
    lastPeriodStart,
    avgCycleLength,
    avgPeriodDuration,
    currentLogStreak,
    longestLogStreak,
    lastLogDate,
    currentPhase,
    currentCycleDay,
    predictedNextStart,
    predictionWindowEarly,
    predictionWindowLate,
    confidenceLevel,
  );

  /// Create a copy of CycleProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CycleProfileModelImplCopyWith<_$CycleProfileModelImpl> get copyWith =>
      __$$CycleProfileModelImplCopyWithImpl<_$CycleProfileModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CycleProfileModelImplToJson(this);
  }
}

abstract class _CycleProfileModel implements CycleProfileModel {
  const factory _CycleProfileModel({
    required final String userId,
    required final String trackerMode,
    required final DateTime? lastPeriodStart,
    required final int avgCycleLength,
    required final int avgPeriodDuration,
    required final int currentLogStreak,
    required final int longestLogStreak,
    required final DateTime? lastLogDate,
    required final String? currentPhase,
    required final int? currentCycleDay,
    required final DateTime? predictedNextStart,
    required final DateTime? predictionWindowEarly,
    required final DateTime? predictionWindowLate,
    required final String confidenceLevel,
  }) = _$CycleProfileModelImpl;

  factory _CycleProfileModel.fromJson(Map<String, dynamic> json) =
      _$CycleProfileModelImpl.fromJson;

  @override
  String get userId;
  @override
  String get trackerMode; // 'active', 'watching_waiting', 'irregular'
  @override
  DateTime? get lastPeriodStart;
  @override
  int get avgCycleLength;
  @override
  int get avgPeriodDuration;
  @override
  int get currentLogStreak;
  @override
  int get longestLogStreak;
  @override
  DateTime? get lastLogDate;
  @override
  String? get currentPhase;
  @override
  int? get currentCycleDay;
  @override
  DateTime? get predictedNextStart;
  @override
  DateTime? get predictionWindowEarly;
  @override
  DateTime? get predictionWindowLate;
  @override
  String get confidenceLevel;

  /// Create a copy of CycleProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CycleProfileModelImplCopyWith<_$CycleProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CycleLogModel _$CycleLogModelFromJson(Map<String, dynamic> json) {
  return _CycleLogModel.fromJson(json);
}

/// @nodoc
mixin _$CycleLogModel {
  String get id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get flow =>
      throw _privateConstructorUsedError; // 'none', 'light', 'medium', 'heavy', 'spotting', 'ended'
  List<String> get symptoms => throw _privateConstructorUsedError;
  int? get crampIntensity => throw _privateConstructorUsedError;
  String? get moodPrimary => throw _privateConstructorUsedError;
  List<String> get moodSecondary => throw _privateConstructorUsedError;
  int? get energyLevel => throw _privateConstructorUsedError;
  double? get sleepHours => throw _privateConstructorUsedError;
  int? get sleepQuality => throw _privateConstructorUsedError;
  String? get noteText => throw _privateConstructorUsedError;
  List<String> get nutritionTags => throw _privateConstructorUsedError;
  List<String> get activityTags => throw _privateConstructorUsedError;
  bool? get isRetroactive => throw _privateConstructorUsedError;

  /// Serializes this CycleLogModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CycleLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CycleLogModelCopyWith<CycleLogModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CycleLogModelCopyWith<$Res> {
  factory $CycleLogModelCopyWith(
    CycleLogModel value,
    $Res Function(CycleLogModel) then,
  ) = _$CycleLogModelCopyWithImpl<$Res, CycleLogModel>;
  @useResult
  $Res call({
    String id,
    DateTime date,
    String? flow,
    List<String> symptoms,
    int? crampIntensity,
    String? moodPrimary,
    List<String> moodSecondary,
    int? energyLevel,
    double? sleepHours,
    int? sleepQuality,
    String? noteText,
    List<String> nutritionTags,
    List<String> activityTags,
    bool? isRetroactive,
  });
}

/// @nodoc
class _$CycleLogModelCopyWithImpl<$Res, $Val extends CycleLogModel>
    implements $CycleLogModelCopyWith<$Res> {
  _$CycleLogModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CycleLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? flow = freezed,
    Object? symptoms = null,
    Object? crampIntensity = freezed,
    Object? moodPrimary = freezed,
    Object? moodSecondary = null,
    Object? energyLevel = freezed,
    Object? sleepHours = freezed,
    Object? sleepQuality = freezed,
    Object? noteText = freezed,
    Object? nutritionTags = null,
    Object? activityTags = null,
    Object? isRetroactive = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            flow: freezed == flow
                ? _value.flow
                : flow // ignore: cast_nullable_to_non_nullable
                      as String?,
            symptoms: null == symptoms
                ? _value.symptoms
                : symptoms // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            crampIntensity: freezed == crampIntensity
                ? _value.crampIntensity
                : crampIntensity // ignore: cast_nullable_to_non_nullable
                      as int?,
            moodPrimary: freezed == moodPrimary
                ? _value.moodPrimary
                : moodPrimary // ignore: cast_nullable_to_non_nullable
                      as String?,
            moodSecondary: null == moodSecondary
                ? _value.moodSecondary
                : moodSecondary // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            energyLevel: freezed == energyLevel
                ? _value.energyLevel
                : energyLevel // ignore: cast_nullable_to_non_nullable
                      as int?,
            sleepHours: freezed == sleepHours
                ? _value.sleepHours
                : sleepHours // ignore: cast_nullable_to_non_nullable
                      as double?,
            sleepQuality: freezed == sleepQuality
                ? _value.sleepQuality
                : sleepQuality // ignore: cast_nullable_to_non_nullable
                      as int?,
            noteText: freezed == noteText
                ? _value.noteText
                : noteText // ignore: cast_nullable_to_non_nullable
                      as String?,
            nutritionTags: null == nutritionTags
                ? _value.nutritionTags
                : nutritionTags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            activityTags: null == activityTags
                ? _value.activityTags
                : activityTags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isRetroactive: freezed == isRetroactive
                ? _value.isRetroactive
                : isRetroactive // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CycleLogModelImplCopyWith<$Res>
    implements $CycleLogModelCopyWith<$Res> {
  factory _$$CycleLogModelImplCopyWith(
    _$CycleLogModelImpl value,
    $Res Function(_$CycleLogModelImpl) then,
  ) = __$$CycleLogModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    DateTime date,
    String? flow,
    List<String> symptoms,
    int? crampIntensity,
    String? moodPrimary,
    List<String> moodSecondary,
    int? energyLevel,
    double? sleepHours,
    int? sleepQuality,
    String? noteText,
    List<String> nutritionTags,
    List<String> activityTags,
    bool? isRetroactive,
  });
}

/// @nodoc
class __$$CycleLogModelImplCopyWithImpl<$Res>
    extends _$CycleLogModelCopyWithImpl<$Res, _$CycleLogModelImpl>
    implements _$$CycleLogModelImplCopyWith<$Res> {
  __$$CycleLogModelImplCopyWithImpl(
    _$CycleLogModelImpl _value,
    $Res Function(_$CycleLogModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CycleLogModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? flow = freezed,
    Object? symptoms = null,
    Object? crampIntensity = freezed,
    Object? moodPrimary = freezed,
    Object? moodSecondary = null,
    Object? energyLevel = freezed,
    Object? sleepHours = freezed,
    Object? sleepQuality = freezed,
    Object? noteText = freezed,
    Object? nutritionTags = null,
    Object? activityTags = null,
    Object? isRetroactive = freezed,
  }) {
    return _then(
      _$CycleLogModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        flow: freezed == flow
            ? _value.flow
            : flow // ignore: cast_nullable_to_non_nullable
                  as String?,
        symptoms: null == symptoms
            ? _value._symptoms
            : symptoms // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        crampIntensity: freezed == crampIntensity
            ? _value.crampIntensity
            : crampIntensity // ignore: cast_nullable_to_non_nullable
                  as int?,
        moodPrimary: freezed == moodPrimary
            ? _value.moodPrimary
            : moodPrimary // ignore: cast_nullable_to_non_nullable
                  as String?,
        moodSecondary: null == moodSecondary
            ? _value._moodSecondary
            : moodSecondary // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        energyLevel: freezed == energyLevel
            ? _value.energyLevel
            : energyLevel // ignore: cast_nullable_to_non_nullable
                  as int?,
        sleepHours: freezed == sleepHours
            ? _value.sleepHours
            : sleepHours // ignore: cast_nullable_to_non_nullable
                  as double?,
        sleepQuality: freezed == sleepQuality
            ? _value.sleepQuality
            : sleepQuality // ignore: cast_nullable_to_non_nullable
                  as int?,
        noteText: freezed == noteText
            ? _value.noteText
            : noteText // ignore: cast_nullable_to_non_nullable
                  as String?,
        nutritionTags: null == nutritionTags
            ? _value._nutritionTags
            : nutritionTags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        activityTags: null == activityTags
            ? _value._activityTags
            : activityTags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isRetroactive: freezed == isRetroactive
            ? _value.isRetroactive
            : isRetroactive // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CycleLogModelImpl implements _CycleLogModel {
  const _$CycleLogModelImpl({
    required this.id,
    required this.date,
    this.flow,
    final List<String> symptoms = const [],
    this.crampIntensity,
    this.moodPrimary,
    final List<String> moodSecondary = const [],
    this.energyLevel,
    this.sleepHours,
    this.sleepQuality,
    this.noteText,
    final List<String> nutritionTags = const [],
    final List<String> activityTags = const [],
    this.isRetroactive,
  }) : _symptoms = symptoms,
       _moodSecondary = moodSecondary,
       _nutritionTags = nutritionTags,
       _activityTags = activityTags;

  factory _$CycleLogModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CycleLogModelImplFromJson(json);

  @override
  final String id;
  @override
  final DateTime date;
  @override
  final String? flow;
  // 'none', 'light', 'medium', 'heavy', 'spotting', 'ended'
  final List<String> _symptoms;
  // 'none', 'light', 'medium', 'heavy', 'spotting', 'ended'
  @override
  @JsonKey()
  List<String> get symptoms {
    if (_symptoms is EqualUnmodifiableListView) return _symptoms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_symptoms);
  }

  @override
  final int? crampIntensity;
  @override
  final String? moodPrimary;
  final List<String> _moodSecondary;
  @override
  @JsonKey()
  List<String> get moodSecondary {
    if (_moodSecondary is EqualUnmodifiableListView) return _moodSecondary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moodSecondary);
  }

  @override
  final int? energyLevel;
  @override
  final double? sleepHours;
  @override
  final int? sleepQuality;
  @override
  final String? noteText;
  final List<String> _nutritionTags;
  @override
  @JsonKey()
  List<String> get nutritionTags {
    if (_nutritionTags is EqualUnmodifiableListView) return _nutritionTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nutritionTags);
  }

  final List<String> _activityTags;
  @override
  @JsonKey()
  List<String> get activityTags {
    if (_activityTags is EqualUnmodifiableListView) return _activityTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activityTags);
  }

  @override
  final bool? isRetroactive;

  @override
  String toString() {
    return 'CycleLogModel(id: $id, date: $date, flow: $flow, symptoms: $symptoms, crampIntensity: $crampIntensity, moodPrimary: $moodPrimary, moodSecondary: $moodSecondary, energyLevel: $energyLevel, sleepHours: $sleepHours, sleepQuality: $sleepQuality, noteText: $noteText, nutritionTags: $nutritionTags, activityTags: $activityTags, isRetroactive: $isRetroactive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CycleLogModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.flow, flow) || other.flow == flow) &&
            const DeepCollectionEquality().equals(other._symptoms, _symptoms) &&
            (identical(other.crampIntensity, crampIntensity) ||
                other.crampIntensity == crampIntensity) &&
            (identical(other.moodPrimary, moodPrimary) ||
                other.moodPrimary == moodPrimary) &&
            const DeepCollectionEquality().equals(
              other._moodSecondary,
              _moodSecondary,
            ) &&
            (identical(other.energyLevel, energyLevel) ||
                other.energyLevel == energyLevel) &&
            (identical(other.sleepHours, sleepHours) ||
                other.sleepHours == sleepHours) &&
            (identical(other.sleepQuality, sleepQuality) ||
                other.sleepQuality == sleepQuality) &&
            (identical(other.noteText, noteText) ||
                other.noteText == noteText) &&
            const DeepCollectionEquality().equals(
              other._nutritionTags,
              _nutritionTags,
            ) &&
            const DeepCollectionEquality().equals(
              other._activityTags,
              _activityTags,
            ) &&
            (identical(other.isRetroactive, isRetroactive) ||
                other.isRetroactive == isRetroactive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    flow,
    const DeepCollectionEquality().hash(_symptoms),
    crampIntensity,
    moodPrimary,
    const DeepCollectionEquality().hash(_moodSecondary),
    energyLevel,
    sleepHours,
    sleepQuality,
    noteText,
    const DeepCollectionEquality().hash(_nutritionTags),
    const DeepCollectionEquality().hash(_activityTags),
    isRetroactive,
  );

  /// Create a copy of CycleLogModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CycleLogModelImplCopyWith<_$CycleLogModelImpl> get copyWith =>
      __$$CycleLogModelImplCopyWithImpl<_$CycleLogModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CycleLogModelImplToJson(this);
  }
}

abstract class _CycleLogModel implements CycleLogModel {
  const factory _CycleLogModel({
    required final String id,
    required final DateTime date,
    final String? flow,
    final List<String> symptoms,
    final int? crampIntensity,
    final String? moodPrimary,
    final List<String> moodSecondary,
    final int? energyLevel,
    final double? sleepHours,
    final int? sleepQuality,
    final String? noteText,
    final List<String> nutritionTags,
    final List<String> activityTags,
    final bool? isRetroactive,
  }) = _$CycleLogModelImpl;

  factory _CycleLogModel.fromJson(Map<String, dynamic> json) =
      _$CycleLogModelImpl.fromJson;

  @override
  String get id;
  @override
  DateTime get date;
  @override
  String? get flow; // 'none', 'light', 'medium', 'heavy', 'spotting', 'ended'
  @override
  List<String> get symptoms;
  @override
  int? get crampIntensity;
  @override
  String? get moodPrimary;
  @override
  List<String> get moodSecondary;
  @override
  int? get energyLevel;
  @override
  double? get sleepHours;
  @override
  int? get sleepQuality;
  @override
  String? get noteText;
  @override
  List<String> get nutritionTags;
  @override
  List<String> get activityTags;
  @override
  bool? get isRetroactive;

  /// Create a copy of CycleLogModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CycleLogModelImplCopyWith<_$CycleLogModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PredictionResultModel _$PredictionResultModelFromJson(
  Map<String, dynamic> json,
) {
  return _PredictionResultModel.fromJson(json);
}

/// @nodoc
mixin _$PredictionResultModel {
  DateTime get predictedStart => throw _privateConstructorUsedError;
  DateTime get windowEarly => throw _privateConstructorUsedError;
  DateTime get windowLate => throw _privateConstructorUsedError;
  DateTime get ovulationDate => throw _privateConstructorUsedError;
  DateTime get fertilityStart => throw _privateConstructorUsedError;
  DateTime get fertilityEnd => throw _privateConstructorUsedError;
  String get confidenceLevel => throw _privateConstructorUsedError;
  int get daysUntilPrediction => throw _privateConstructorUsedError;
  String get currentPhase => throw _privateConstructorUsedError;
  int get cycleDay => throw _privateConstructorUsedError;
  double get coefficientOfVar => throw _privateConstructorUsedError;
  int get cyclesLogged => throw _privateConstructorUsedError;
  int get currentLogStreak => throw _privateConstructorUsedError;
  bool get hasLoggedToday => throw _privateConstructorUsedError;
  List<String> get insights => throw _privateConstructorUsedError;

  /// Serializes this PredictionResultModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PredictionResultModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PredictionResultModelCopyWith<PredictionResultModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PredictionResultModelCopyWith<$Res> {
  factory $PredictionResultModelCopyWith(
    PredictionResultModel value,
    $Res Function(PredictionResultModel) then,
  ) = _$PredictionResultModelCopyWithImpl<$Res, PredictionResultModel>;
  @useResult
  $Res call({
    DateTime predictedStart,
    DateTime windowEarly,
    DateTime windowLate,
    DateTime ovulationDate,
    DateTime fertilityStart,
    DateTime fertilityEnd,
    String confidenceLevel,
    int daysUntilPrediction,
    String currentPhase,
    int cycleDay,
    double coefficientOfVar,
    int cyclesLogged,
    int currentLogStreak,
    bool hasLoggedToday,
    List<String> insights,
  });
}

/// @nodoc
class _$PredictionResultModelCopyWithImpl<
  $Res,
  $Val extends PredictionResultModel
>
    implements $PredictionResultModelCopyWith<$Res> {
  _$PredictionResultModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PredictionResultModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? predictedStart = null,
    Object? windowEarly = null,
    Object? windowLate = null,
    Object? ovulationDate = null,
    Object? fertilityStart = null,
    Object? fertilityEnd = null,
    Object? confidenceLevel = null,
    Object? daysUntilPrediction = null,
    Object? currentPhase = null,
    Object? cycleDay = null,
    Object? coefficientOfVar = null,
    Object? cyclesLogged = null,
    Object? currentLogStreak = null,
    Object? hasLoggedToday = null,
    Object? insights = null,
  }) {
    return _then(
      _value.copyWith(
            predictedStart: null == predictedStart
                ? _value.predictedStart
                : predictedStart // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            windowEarly: null == windowEarly
                ? _value.windowEarly
                : windowEarly // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            windowLate: null == windowLate
                ? _value.windowLate
                : windowLate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            ovulationDate: null == ovulationDate
                ? _value.ovulationDate
                : ovulationDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            fertilityStart: null == fertilityStart
                ? _value.fertilityStart
                : fertilityStart // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            fertilityEnd: null == fertilityEnd
                ? _value.fertilityEnd
                : fertilityEnd // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            confidenceLevel: null == confidenceLevel
                ? _value.confidenceLevel
                : confidenceLevel // ignore: cast_nullable_to_non_nullable
                      as String,
            daysUntilPrediction: null == daysUntilPrediction
                ? _value.daysUntilPrediction
                : daysUntilPrediction // ignore: cast_nullable_to_non_nullable
                      as int,
            currentPhase: null == currentPhase
                ? _value.currentPhase
                : currentPhase // ignore: cast_nullable_to_non_nullable
                      as String,
            cycleDay: null == cycleDay
                ? _value.cycleDay
                : cycleDay // ignore: cast_nullable_to_non_nullable
                      as int,
            coefficientOfVar: null == coefficientOfVar
                ? _value.coefficientOfVar
                : coefficientOfVar // ignore: cast_nullable_to_non_nullable
                      as double,
            cyclesLogged: null == cyclesLogged
                ? _value.cyclesLogged
                : cyclesLogged // ignore: cast_nullable_to_non_nullable
                      as int,
            currentLogStreak: null == currentLogStreak
                ? _value.currentLogStreak
                : currentLogStreak // ignore: cast_nullable_to_non_nullable
                      as int,
            hasLoggedToday: null == hasLoggedToday
                ? _value.hasLoggedToday
                : hasLoggedToday // ignore: cast_nullable_to_non_nullable
                      as bool,
            insights: null == insights
                ? _value.insights
                : insights // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PredictionResultModelImplCopyWith<$Res>
    implements $PredictionResultModelCopyWith<$Res> {
  factory _$$PredictionResultModelImplCopyWith(
    _$PredictionResultModelImpl value,
    $Res Function(_$PredictionResultModelImpl) then,
  ) = __$$PredictionResultModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime predictedStart,
    DateTime windowEarly,
    DateTime windowLate,
    DateTime ovulationDate,
    DateTime fertilityStart,
    DateTime fertilityEnd,
    String confidenceLevel,
    int daysUntilPrediction,
    String currentPhase,
    int cycleDay,
    double coefficientOfVar,
    int cyclesLogged,
    int currentLogStreak,
    bool hasLoggedToday,
    List<String> insights,
  });
}

/// @nodoc
class __$$PredictionResultModelImplCopyWithImpl<$Res>
    extends
        _$PredictionResultModelCopyWithImpl<$Res, _$PredictionResultModelImpl>
    implements _$$PredictionResultModelImplCopyWith<$Res> {
  __$$PredictionResultModelImplCopyWithImpl(
    _$PredictionResultModelImpl _value,
    $Res Function(_$PredictionResultModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PredictionResultModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? predictedStart = null,
    Object? windowEarly = null,
    Object? windowLate = null,
    Object? ovulationDate = null,
    Object? fertilityStart = null,
    Object? fertilityEnd = null,
    Object? confidenceLevel = null,
    Object? daysUntilPrediction = null,
    Object? currentPhase = null,
    Object? cycleDay = null,
    Object? coefficientOfVar = null,
    Object? cyclesLogged = null,
    Object? currentLogStreak = null,
    Object? hasLoggedToday = null,
    Object? insights = null,
  }) {
    return _then(
      _$PredictionResultModelImpl(
        predictedStart: null == predictedStart
            ? _value.predictedStart
            : predictedStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        windowEarly: null == windowEarly
            ? _value.windowEarly
            : windowEarly // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        windowLate: null == windowLate
            ? _value.windowLate
            : windowLate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        ovulationDate: null == ovulationDate
            ? _value.ovulationDate
            : ovulationDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        fertilityStart: null == fertilityStart
            ? _value.fertilityStart
            : fertilityStart // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        fertilityEnd: null == fertilityEnd
            ? _value.fertilityEnd
            : fertilityEnd // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confidenceLevel: null == confidenceLevel
            ? _value.confidenceLevel
            : confidenceLevel // ignore: cast_nullable_to_non_nullable
                  as String,
        daysUntilPrediction: null == daysUntilPrediction
            ? _value.daysUntilPrediction
            : daysUntilPrediction // ignore: cast_nullable_to_non_nullable
                  as int,
        currentPhase: null == currentPhase
            ? _value.currentPhase
            : currentPhase // ignore: cast_nullable_to_non_nullable
                  as String,
        cycleDay: null == cycleDay
            ? _value.cycleDay
            : cycleDay // ignore: cast_nullable_to_non_nullable
                  as int,
        coefficientOfVar: null == coefficientOfVar
            ? _value.coefficientOfVar
            : coefficientOfVar // ignore: cast_nullable_to_non_nullable
                  as double,
        cyclesLogged: null == cyclesLogged
            ? _value.cyclesLogged
            : cyclesLogged // ignore: cast_nullable_to_non_nullable
                  as int,
        currentLogStreak: null == currentLogStreak
            ? _value.currentLogStreak
            : currentLogStreak // ignore: cast_nullable_to_non_nullable
                  as int,
        hasLoggedToday: null == hasLoggedToday
            ? _value.hasLoggedToday
            : hasLoggedToday // ignore: cast_nullable_to_non_nullable
                  as bool,
        insights: null == insights
            ? _value._insights
            : insights // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PredictionResultModelImpl implements _PredictionResultModel {
  const _$PredictionResultModelImpl({
    required this.predictedStart,
    required this.windowEarly,
    required this.windowLate,
    required this.ovulationDate,
    required this.fertilityStart,
    required this.fertilityEnd,
    required this.confidenceLevel,
    required this.daysUntilPrediction,
    required this.currentPhase,
    required this.cycleDay,
    this.coefficientOfVar = 0.0,
    this.cyclesLogged = 0,
    this.currentLogStreak = 0,
    this.hasLoggedToday = false,
    final List<String> insights = const [],
  }) : _insights = insights;

  factory _$PredictionResultModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PredictionResultModelImplFromJson(json);

  @override
  final DateTime predictedStart;
  @override
  final DateTime windowEarly;
  @override
  final DateTime windowLate;
  @override
  final DateTime ovulationDate;
  @override
  final DateTime fertilityStart;
  @override
  final DateTime fertilityEnd;
  @override
  final String confidenceLevel;
  @override
  final int daysUntilPrediction;
  @override
  final String currentPhase;
  @override
  final int cycleDay;
  @override
  @JsonKey()
  final double coefficientOfVar;
  @override
  @JsonKey()
  final int cyclesLogged;
  @override
  @JsonKey()
  final int currentLogStreak;
  @override
  @JsonKey()
  final bool hasLoggedToday;
  final List<String> _insights;
  @override
  @JsonKey()
  List<String> get insights {
    if (_insights is EqualUnmodifiableListView) return _insights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_insights);
  }

  @override
  String toString() {
    return 'PredictionResultModel(predictedStart: $predictedStart, windowEarly: $windowEarly, windowLate: $windowLate, ovulationDate: $ovulationDate, fertilityStart: $fertilityStart, fertilityEnd: $fertilityEnd, confidenceLevel: $confidenceLevel, daysUntilPrediction: $daysUntilPrediction, currentPhase: $currentPhase, cycleDay: $cycleDay, coefficientOfVar: $coefficientOfVar, cyclesLogged: $cyclesLogged, currentLogStreak: $currentLogStreak, hasLoggedToday: $hasLoggedToday, insights: $insights)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PredictionResultModelImpl &&
            (identical(other.predictedStart, predictedStart) ||
                other.predictedStart == predictedStart) &&
            (identical(other.windowEarly, windowEarly) ||
                other.windowEarly == windowEarly) &&
            (identical(other.windowLate, windowLate) ||
                other.windowLate == windowLate) &&
            (identical(other.ovulationDate, ovulationDate) ||
                other.ovulationDate == ovulationDate) &&
            (identical(other.fertilityStart, fertilityStart) ||
                other.fertilityStart == fertilityStart) &&
            (identical(other.fertilityEnd, fertilityEnd) ||
                other.fertilityEnd == fertilityEnd) &&
            (identical(other.confidenceLevel, confidenceLevel) ||
                other.confidenceLevel == confidenceLevel) &&
            (identical(other.daysUntilPrediction, daysUntilPrediction) ||
                other.daysUntilPrediction == daysUntilPrediction) &&
            (identical(other.currentPhase, currentPhase) ||
                other.currentPhase == currentPhase) &&
            (identical(other.cycleDay, cycleDay) ||
                other.cycleDay == cycleDay) &&
            (identical(other.coefficientOfVar, coefficientOfVar) ||
                other.coefficientOfVar == coefficientOfVar) &&
            (identical(other.cyclesLogged, cyclesLogged) ||
                other.cyclesLogged == cyclesLogged) &&
            (identical(other.currentLogStreak, currentLogStreak) ||
                other.currentLogStreak == currentLogStreak) &&
            (identical(other.hasLoggedToday, hasLoggedToday) ||
                other.hasLoggedToday == hasLoggedToday) &&
            const DeepCollectionEquality().equals(other._insights, _insights));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    predictedStart,
    windowEarly,
    windowLate,
    ovulationDate,
    fertilityStart,
    fertilityEnd,
    confidenceLevel,
    daysUntilPrediction,
    currentPhase,
    cycleDay,
    coefficientOfVar,
    cyclesLogged,
    currentLogStreak,
    hasLoggedToday,
    const DeepCollectionEquality().hash(_insights),
  );

  /// Create a copy of PredictionResultModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PredictionResultModelImplCopyWith<_$PredictionResultModelImpl>
  get copyWith =>
      __$$PredictionResultModelImplCopyWithImpl<_$PredictionResultModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PredictionResultModelImplToJson(this);
  }
}

abstract class _PredictionResultModel implements PredictionResultModel {
  const factory _PredictionResultModel({
    required final DateTime predictedStart,
    required final DateTime windowEarly,
    required final DateTime windowLate,
    required final DateTime ovulationDate,
    required final DateTime fertilityStart,
    required final DateTime fertilityEnd,
    required final String confidenceLevel,
    required final int daysUntilPrediction,
    required final String currentPhase,
    required final int cycleDay,
    final double coefficientOfVar,
    final int cyclesLogged,
    final int currentLogStreak,
    final bool hasLoggedToday,
    final List<String> insights,
  }) = _$PredictionResultModelImpl;

  factory _PredictionResultModel.fromJson(Map<String, dynamic> json) =
      _$PredictionResultModelImpl.fromJson;

  @override
  DateTime get predictedStart;
  @override
  DateTime get windowEarly;
  @override
  DateTime get windowLate;
  @override
  DateTime get ovulationDate;
  @override
  DateTime get fertilityStart;
  @override
  DateTime get fertilityEnd;
  @override
  String get confidenceLevel;
  @override
  int get daysUntilPrediction;
  @override
  String get currentPhase;
  @override
  int get cycleDay;
  @override
  double get coefficientOfVar;
  @override
  int get cyclesLogged;
  @override
  int get currentLogStreak;
  @override
  bool get hasLoggedToday;
  @override
  List<String> get insights;

  /// Create a copy of PredictionResultModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PredictionResultModelImplCopyWith<_$PredictionResultModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CycleRecordModel _$CycleRecordModelFromJson(Map<String, dynamic> json) {
  return _CycleRecordModel.fromJson(json);
}

/// @nodoc
mixin _$CycleRecordModel {
  String get id => throw _privateConstructorUsedError;
  int get cycleNumber => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get periodStartDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  DateTime? get periodEndDate => throw _privateConstructorUsedError;
  int? get cycleLengthDays => throw _privateConstructorUsedError;
  int? get periodDurationDays => throw _privateConstructorUsedError;
  bool get isComplete => throw _privateConstructorUsedError;

  /// Serializes this CycleRecordModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CycleRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CycleRecordModelCopyWith<CycleRecordModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CycleRecordModelCopyWith<$Res> {
  factory $CycleRecordModelCopyWith(
    CycleRecordModel value,
    $Res Function(CycleRecordModel) then,
  ) = _$CycleRecordModelCopyWithImpl<$Res, CycleRecordModel>;
  @useResult
  $Res call({
    String id,
    int cycleNumber,
    DateTime startDate,
    DateTime periodStartDate,
    DateTime? endDate,
    DateTime? periodEndDate,
    int? cycleLengthDays,
    int? periodDurationDays,
    bool isComplete,
  });
}

/// @nodoc
class _$CycleRecordModelCopyWithImpl<$Res, $Val extends CycleRecordModel>
    implements $CycleRecordModelCopyWith<$Res> {
  _$CycleRecordModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CycleRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cycleNumber = null,
    Object? startDate = null,
    Object? periodStartDate = null,
    Object? endDate = freezed,
    Object? periodEndDate = freezed,
    Object? cycleLengthDays = freezed,
    Object? periodDurationDays = freezed,
    Object? isComplete = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            cycleNumber: null == cycleNumber
                ? _value.cycleNumber
                : cycleNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            periodStartDate: null == periodStartDate
                ? _value.periodStartDate
                : periodStartDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            periodEndDate: freezed == periodEndDate
                ? _value.periodEndDate
                : periodEndDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cycleLengthDays: freezed == cycleLengthDays
                ? _value.cycleLengthDays
                : cycleLengthDays // ignore: cast_nullable_to_non_nullable
                      as int?,
            periodDurationDays: freezed == periodDurationDays
                ? _value.periodDurationDays
                : periodDurationDays // ignore: cast_nullable_to_non_nullable
                      as int?,
            isComplete: null == isComplete
                ? _value.isComplete
                : isComplete // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CycleRecordModelImplCopyWith<$Res>
    implements $CycleRecordModelCopyWith<$Res> {
  factory _$$CycleRecordModelImplCopyWith(
    _$CycleRecordModelImpl value,
    $Res Function(_$CycleRecordModelImpl) then,
  ) = __$$CycleRecordModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int cycleNumber,
    DateTime startDate,
    DateTime periodStartDate,
    DateTime? endDate,
    DateTime? periodEndDate,
    int? cycleLengthDays,
    int? periodDurationDays,
    bool isComplete,
  });
}

/// @nodoc
class __$$CycleRecordModelImplCopyWithImpl<$Res>
    extends _$CycleRecordModelCopyWithImpl<$Res, _$CycleRecordModelImpl>
    implements _$$CycleRecordModelImplCopyWith<$Res> {
  __$$CycleRecordModelImplCopyWithImpl(
    _$CycleRecordModelImpl _value,
    $Res Function(_$CycleRecordModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CycleRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cycleNumber = null,
    Object? startDate = null,
    Object? periodStartDate = null,
    Object? endDate = freezed,
    Object? periodEndDate = freezed,
    Object? cycleLengthDays = freezed,
    Object? periodDurationDays = freezed,
    Object? isComplete = null,
  }) {
    return _then(
      _$CycleRecordModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        cycleNumber: null == cycleNumber
            ? _value.cycleNumber
            : cycleNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        periodStartDate: null == periodStartDate
            ? _value.periodStartDate
            : periodStartDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        periodEndDate: freezed == periodEndDate
            ? _value.periodEndDate
            : periodEndDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cycleLengthDays: freezed == cycleLengthDays
            ? _value.cycleLengthDays
            : cycleLengthDays // ignore: cast_nullable_to_non_nullable
                  as int?,
        periodDurationDays: freezed == periodDurationDays
            ? _value.periodDurationDays
            : periodDurationDays // ignore: cast_nullable_to_non_nullable
                  as int?,
        isComplete: null == isComplete
            ? _value.isComplete
            : isComplete // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CycleRecordModelImpl implements _CycleRecordModel {
  const _$CycleRecordModelImpl({
    required this.id,
    required this.cycleNumber,
    required this.startDate,
    required this.periodStartDate,
    this.endDate,
    this.periodEndDate,
    this.cycleLengthDays,
    this.periodDurationDays,
    this.isComplete = false,
  });

  factory _$CycleRecordModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CycleRecordModelImplFromJson(json);

  @override
  final String id;
  @override
  final int cycleNumber;
  @override
  final DateTime startDate;
  @override
  final DateTime periodStartDate;
  @override
  final DateTime? endDate;
  @override
  final DateTime? periodEndDate;
  @override
  final int? cycleLengthDays;
  @override
  final int? periodDurationDays;
  @override
  @JsonKey()
  final bool isComplete;

  @override
  String toString() {
    return 'CycleRecordModel(id: $id, cycleNumber: $cycleNumber, startDate: $startDate, periodStartDate: $periodStartDate, endDate: $endDate, periodEndDate: $periodEndDate, cycleLengthDays: $cycleLengthDays, periodDurationDays: $periodDurationDays, isComplete: $isComplete)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CycleRecordModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cycleNumber, cycleNumber) ||
                other.cycleNumber == cycleNumber) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.periodStartDate, periodStartDate) ||
                other.periodStartDate == periodStartDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.periodEndDate, periodEndDate) ||
                other.periodEndDate == periodEndDate) &&
            (identical(other.cycleLengthDays, cycleLengthDays) ||
                other.cycleLengthDays == cycleLengthDays) &&
            (identical(other.periodDurationDays, periodDurationDays) ||
                other.periodDurationDays == periodDurationDays) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    cycleNumber,
    startDate,
    periodStartDate,
    endDate,
    periodEndDate,
    cycleLengthDays,
    periodDurationDays,
    isComplete,
  );

  /// Create a copy of CycleRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CycleRecordModelImplCopyWith<_$CycleRecordModelImpl> get copyWith =>
      __$$CycleRecordModelImplCopyWithImpl<_$CycleRecordModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CycleRecordModelImplToJson(this);
  }
}

abstract class _CycleRecordModel implements CycleRecordModel {
  const factory _CycleRecordModel({
    required final String id,
    required final int cycleNumber,
    required final DateTime startDate,
    required final DateTime periodStartDate,
    final DateTime? endDate,
    final DateTime? periodEndDate,
    final int? cycleLengthDays,
    final int? periodDurationDays,
    final bool isComplete,
  }) = _$CycleRecordModelImpl;

  factory _CycleRecordModel.fromJson(Map<String, dynamic> json) =
      _$CycleRecordModelImpl.fromJson;

  @override
  String get id;
  @override
  int get cycleNumber;
  @override
  DateTime get startDate;
  @override
  DateTime get periodStartDate;
  @override
  DateTime? get endDate;
  @override
  DateTime? get periodEndDate;
  @override
  int? get cycleLengthDays;
  @override
  int? get periodDurationDays;
  @override
  bool get isComplete;

  /// Create a copy of CycleRecordModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CycleRecordModelImplCopyWith<_$CycleRecordModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
