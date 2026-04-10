// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'learning_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LearningJourney _$LearningJourneyFromJson(Map<String, dynamic> json) {
  return _LearningJourney.fromJson(json);
}

/// @nodoc
mixin _$LearningJourney {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  String? get bannerImage => throw _privateConstructorUsedError;
  int get totalXP => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get ageBand => throw _privateConstructorUsedError;
  List<String> get topics => throw _privateConstructorUsedError;
  List<String> get goals => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String get contentTone => throw _privateConstructorUsedError;
  String get minContentTier => throw _privateConstructorUsedError;
  List<Episode> get episodes => throw _privateConstructorUsedError;

  /// Serializes this LearningJourney to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LearningJourney
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LearningJourneyCopyWith<LearningJourney> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningJourneyCopyWith<$Res> {
  factory $LearningJourneyCopyWith(
    LearningJourney value,
    $Res Function(LearningJourney) then,
  ) = _$LearningJourneyCopyWithImpl<$Res, LearningJourney>;
  @useResult
  $Res call({
    String id,
    String title,
    String slug,
    String description,
    String? thumbnailUrl,
    String? bannerImage,
    int totalXP,
    String? category,
    bool isActive,
    String? ageBand,
    List<String> topics,
    List<String> goals,
    List<String> tags,
    String contentTone,
    String minContentTier,
    List<Episode> episodes,
  });
}

/// @nodoc
class _$LearningJourneyCopyWithImpl<$Res, $Val extends LearningJourney>
    implements $LearningJourneyCopyWith<$Res> {
  _$LearningJourneyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LearningJourney
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? description = null,
    Object? thumbnailUrl = freezed,
    Object? bannerImage = freezed,
    Object? totalXP = null,
    Object? category = freezed,
    Object? isActive = null,
    Object? ageBand = freezed,
    Object? topics = null,
    Object? goals = null,
    Object? tags = null,
    Object? contentTone = null,
    Object? minContentTier = null,
    Object? episodes = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailUrl: freezed == thumbnailUrl
                ? _value.thumbnailUrl
                : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            bannerImage: freezed == bannerImage
                ? _value.bannerImage
                : bannerImage // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalXP: null == totalXP
                ? _value.totalXP
                : totalXP // ignore: cast_nullable_to_non_nullable
                      as int,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            ageBand: freezed == ageBand
                ? _value.ageBand
                : ageBand // ignore: cast_nullable_to_non_nullable
                      as String?,
            topics: null == topics
                ? _value.topics
                : topics // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            goals: null == goals
                ? _value.goals
                : goals // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            contentTone: null == contentTone
                ? _value.contentTone
                : contentTone // ignore: cast_nullable_to_non_nullable
                      as String,
            minContentTier: null == minContentTier
                ? _value.minContentTier
                : minContentTier // ignore: cast_nullable_to_non_nullable
                      as String,
            episodes: null == episodes
                ? _value.episodes
                : episodes // ignore: cast_nullable_to_non_nullable
                      as List<Episode>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LearningJourneyImplCopyWith<$Res>
    implements $LearningJourneyCopyWith<$Res> {
  factory _$$LearningJourneyImplCopyWith(
    _$LearningJourneyImpl value,
    $Res Function(_$LearningJourneyImpl) then,
  ) = __$$LearningJourneyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String slug,
    String description,
    String? thumbnailUrl,
    String? bannerImage,
    int totalXP,
    String? category,
    bool isActive,
    String? ageBand,
    List<String> topics,
    List<String> goals,
    List<String> tags,
    String contentTone,
    String minContentTier,
    List<Episode> episodes,
  });
}

/// @nodoc
class __$$LearningJourneyImplCopyWithImpl<$Res>
    extends _$LearningJourneyCopyWithImpl<$Res, _$LearningJourneyImpl>
    implements _$$LearningJourneyImplCopyWith<$Res> {
  __$$LearningJourneyImplCopyWithImpl(
    _$LearningJourneyImpl _value,
    $Res Function(_$LearningJourneyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LearningJourney
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? slug = null,
    Object? description = null,
    Object? thumbnailUrl = freezed,
    Object? bannerImage = freezed,
    Object? totalXP = null,
    Object? category = freezed,
    Object? isActive = null,
    Object? ageBand = freezed,
    Object? topics = null,
    Object? goals = null,
    Object? tags = null,
    Object? contentTone = null,
    Object? minContentTier = null,
    Object? episodes = null,
  }) {
    return _then(
      _$LearningJourneyImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailUrl: freezed == thumbnailUrl
            ? _value.thumbnailUrl
            : thumbnailUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        bannerImage: freezed == bannerImage
            ? _value.bannerImage
            : bannerImage // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalXP: null == totalXP
            ? _value.totalXP
            : totalXP // ignore: cast_nullable_to_non_nullable
                  as int,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        ageBand: freezed == ageBand
            ? _value.ageBand
            : ageBand // ignore: cast_nullable_to_non_nullable
                  as String?,
        topics: null == topics
            ? _value._topics
            : topics // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        goals: null == goals
            ? _value._goals
            : goals // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        contentTone: null == contentTone
            ? _value.contentTone
            : contentTone // ignore: cast_nullable_to_non_nullable
                  as String,
        minContentTier: null == minContentTier
            ? _value.minContentTier
            : minContentTier // ignore: cast_nullable_to_non_nullable
                  as String,
        episodes: null == episodes
            ? _value._episodes
            : episodes // ignore: cast_nullable_to_non_nullable
                  as List<Episode>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningJourneyImpl implements _LearningJourney {
  const _$LearningJourneyImpl({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.thumbnailUrl,
    this.bannerImage,
    this.totalXP = 0,
    this.category,
    this.isActive = true,
    this.ageBand,
    final List<String> topics = const [],
    final List<String> goals = const [],
    final List<String> tags = const [],
    this.contentTone = 'moderate',
    this.minContentTier = 'TEEN_EARLY',
    final List<Episode> episodes = const [],
  }) : _topics = topics,
       _goals = goals,
       _tags = tags,
       _episodes = episodes;

  factory _$LearningJourneyImpl.fromJson(Map<String, dynamic> json) =>
      _$$LearningJourneyImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String description;
  @override
  final String? thumbnailUrl;
  @override
  final String? bannerImage;
  @override
  @JsonKey()
  final int totalXP;
  @override
  final String? category;
  @override
  @JsonKey()
  final bool isActive;
  @override
  final String? ageBand;
  final List<String> _topics;
  @override
  @JsonKey()
  List<String> get topics {
    if (_topics is EqualUnmodifiableListView) return _topics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_topics);
  }

  final List<String> _goals;
  @override
  @JsonKey()
  List<String> get goals {
    if (_goals is EqualUnmodifiableListView) return _goals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goals);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final String contentTone;
  @override
  @JsonKey()
  final String minContentTier;
  final List<Episode> _episodes;
  @override
  @JsonKey()
  List<Episode> get episodes {
    if (_episodes is EqualUnmodifiableListView) return _episodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_episodes);
  }

  @override
  String toString() {
    return 'LearningJourney(id: $id, title: $title, slug: $slug, description: $description, thumbnailUrl: $thumbnailUrl, bannerImage: $bannerImage, totalXP: $totalXP, category: $category, isActive: $isActive, ageBand: $ageBand, topics: $topics, goals: $goals, tags: $tags, contentTone: $contentTone, minContentTier: $minContentTier, episodes: $episodes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningJourneyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.bannerImage, bannerImage) ||
                other.bannerImage == bannerImage) &&
            (identical(other.totalXP, totalXP) || other.totalXP == totalXP) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.ageBand, ageBand) || other.ageBand == ageBand) &&
            const DeepCollectionEquality().equals(other._topics, _topics) &&
            const DeepCollectionEquality().equals(other._goals, _goals) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.contentTone, contentTone) ||
                other.contentTone == contentTone) &&
            (identical(other.minContentTier, minContentTier) ||
                other.minContentTier == minContentTier) &&
            const DeepCollectionEquality().equals(other._episodes, _episodes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    slug,
    description,
    thumbnailUrl,
    bannerImage,
    totalXP,
    category,
    isActive,
    ageBand,
    const DeepCollectionEquality().hash(_topics),
    const DeepCollectionEquality().hash(_goals),
    const DeepCollectionEquality().hash(_tags),
    contentTone,
    minContentTier,
    const DeepCollectionEquality().hash(_episodes),
  );

  /// Create a copy of LearningJourney
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningJourneyImplCopyWith<_$LearningJourneyImpl> get copyWith =>
      __$$LearningJourneyImplCopyWithImpl<_$LearningJourneyImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningJourneyImplToJson(this);
  }
}

abstract class _LearningJourney implements LearningJourney {
  const factory _LearningJourney({
    required final String id,
    required final String title,
    required final String slug,
    required final String description,
    final String? thumbnailUrl,
    final String? bannerImage,
    final int totalXP,
    final String? category,
    final bool isActive,
    final String? ageBand,
    final List<String> topics,
    final List<String> goals,
    final List<String> tags,
    final String contentTone,
    final String minContentTier,
    final List<Episode> episodes,
  }) = _$LearningJourneyImpl;

  factory _LearningJourney.fromJson(Map<String, dynamic> json) =
      _$LearningJourneyImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get slug;
  @override
  String get description;
  @override
  String? get thumbnailUrl;
  @override
  String? get bannerImage;
  @override
  int get totalXP;
  @override
  String? get category;
  @override
  bool get isActive;
  @override
  String? get ageBand;
  @override
  List<String> get topics;
  @override
  List<String> get goals;
  @override
  List<String> get tags;
  @override
  String get contentTone;
  @override
  String get minContentTier;
  @override
  List<Episode> get episodes;

  /// Create a copy of LearningJourney
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LearningJourneyImplCopyWith<_$LearningJourneyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Episode _$EpisodeFromJson(Map<String, dynamic> json) {
  return _Episode.fromJson(json);
}

/// @nodoc
mixin _$Episode {
  String get id => throw _privateConstructorUsedError;
  String get journeyId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  dynamic get content =>
      throw _privateConstructorUsedError; // Structured map of 5 segments
  int get points => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this Episode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpisodeCopyWith<Episode> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodeCopyWith<$Res> {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) then) =
      _$EpisodeCopyWithImpl<$Res, Episode>;
  @useResult
  $Res call({
    String id,
    String journeyId,
    String title,
    String slug,
    String? description,
    int order,
    dynamic content,
    int points,
    bool isActive,
  });
}

/// @nodoc
class _$EpisodeCopyWithImpl<$Res, $Val extends Episode>
    implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? journeyId = null,
    Object? title = null,
    Object? slug = null,
    Object? description = freezed,
    Object? order = null,
    Object? content = freezed,
    Object? points = null,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            journeyId: null == journeyId
                ? _value.journeyId
                : journeyId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as dynamic,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EpisodeImplCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$$EpisodeImplCopyWith(
    _$EpisodeImpl value,
    $Res Function(_$EpisodeImpl) then,
  ) = __$$EpisodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String journeyId,
    String title,
    String slug,
    String? description,
    int order,
    dynamic content,
    int points,
    bool isActive,
  });
}

/// @nodoc
class __$$EpisodeImplCopyWithImpl<$Res>
    extends _$EpisodeCopyWithImpl<$Res, _$EpisodeImpl>
    implements _$$EpisodeImplCopyWith<$Res> {
  __$$EpisodeImplCopyWithImpl(
    _$EpisodeImpl _value,
    $Res Function(_$EpisodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? journeyId = null,
    Object? title = null,
    Object? slug = null,
    Object? description = freezed,
    Object? order = null,
    Object? content = freezed,
    Object? points = null,
    Object? isActive = null,
  }) {
    return _then(
      _$EpisodeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        journeyId: null == journeyId
            ? _value.journeyId
            : journeyId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as dynamic,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EpisodeImpl implements _Episode {
  const _$EpisodeImpl({
    required this.id,
    required this.journeyId,
    required this.title,
    required this.slug,
    this.description,
    this.order = 0,
    required this.content,
    this.points = 50,
    this.isActive = true,
  });

  factory _$EpisodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpisodeImplFromJson(json);

  @override
  final String id;
  @override
  final String journeyId;
  @override
  final String title;
  @override
  final String slug;
  @override
  final String? description;
  @override
  @JsonKey()
  final int order;
  @override
  final dynamic content;
  // Structured map of 5 segments
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'Episode(id: $id, journeyId: $journeyId, title: $title, slug: $slug, description: $description, order: $order, content: $content, points: $points, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.journeyId, journeyId) ||
                other.journeyId == journeyId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    journeyId,
    title,
    slug,
    description,
    order,
    const DeepCollectionEquality().hash(content),
    points,
    isActive,
  );

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodeImplCopyWith<_$EpisodeImpl> get copyWith =>
      __$$EpisodeImplCopyWithImpl<_$EpisodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpisodeImplToJson(this);
  }
}

abstract class _Episode implements Episode {
  const factory _Episode({
    required final String id,
    required final String journeyId,
    required final String title,
    required final String slug,
    final String? description,
    final int order,
    required final dynamic content,
    final int points,
    final bool isActive,
  }) = _$EpisodeImpl;

  factory _Episode.fromJson(Map<String, dynamic> json) = _$EpisodeImpl.fromJson;

  @override
  String get id;
  @override
  String get journeyId;
  @override
  String get title;
  @override
  String get slug;
  @override
  String? get description;
  @override
  int get order;
  @override
  dynamic get content; // Structured map of 5 segments
  @override
  int get points;
  @override
  bool get isActive;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodeImplCopyWith<_$EpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) {
  return _UserProgress.fromJson(json);
}

/// @nodoc
mixin _$UserProgress {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get episodeId => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  String? get lastViewedItemId => throw _privateConstructorUsedError;
  dynamic get completedItems => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  Episode? get episode => throw _privateConstructorUsedError;

  /// Serializes this UserProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProgressCopyWith<UserProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProgressCopyWith<$Res> {
  factory $UserProgressCopyWith(
    UserProgress value,
    $Res Function(UserProgress) then,
  ) = _$UserProgressCopyWithImpl<$Res, UserProgress>;
  @useResult
  $Res call({
    String id,
    String userId,
    String episodeId,
    bool completed,
    String? lastViewedItemId,
    dynamic completedItems,
    DateTime updatedAt,
    Episode? episode,
  });

  $EpisodeCopyWith<$Res>? get episode;
}

/// @nodoc
class _$UserProgressCopyWithImpl<$Res, $Val extends UserProgress>
    implements $UserProgressCopyWith<$Res> {
  _$UserProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? episodeId = null,
    Object? completed = null,
    Object? lastViewedItemId = freezed,
    Object? completedItems = freezed,
    Object? updatedAt = null,
    Object? episode = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            episodeId: null == episodeId
                ? _value.episodeId
                : episodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            completed: null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastViewedItemId: freezed == lastViewedItemId
                ? _value.lastViewedItemId
                : lastViewedItemId // ignore: cast_nullable_to_non_nullable
                      as String?,
            completedItems: freezed == completedItems
                ? _value.completedItems
                : completedItems // ignore: cast_nullable_to_non_nullable
                      as dynamic,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            episode: freezed == episode
                ? _value.episode
                : episode // ignore: cast_nullable_to_non_nullable
                      as Episode?,
          )
          as $Val,
    );
  }

  /// Create a copy of UserProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EpisodeCopyWith<$Res>? get episode {
    if (_value.episode == null) {
      return null;
    }

    return $EpisodeCopyWith<$Res>(_value.episode!, (value) {
      return _then(_value.copyWith(episode: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProgressImplCopyWith<$Res>
    implements $UserProgressCopyWith<$Res> {
  factory _$$UserProgressImplCopyWith(
    _$UserProgressImpl value,
    $Res Function(_$UserProgressImpl) then,
  ) = __$$UserProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String episodeId,
    bool completed,
    String? lastViewedItemId,
    dynamic completedItems,
    DateTime updatedAt,
    Episode? episode,
  });

  @override
  $EpisodeCopyWith<$Res>? get episode;
}

/// @nodoc
class __$$UserProgressImplCopyWithImpl<$Res>
    extends _$UserProgressCopyWithImpl<$Res, _$UserProgressImpl>
    implements _$$UserProgressImplCopyWith<$Res> {
  __$$UserProgressImplCopyWithImpl(
    _$UserProgressImpl _value,
    $Res Function(_$UserProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? episodeId = null,
    Object? completed = null,
    Object? lastViewedItemId = freezed,
    Object? completedItems = freezed,
    Object? updatedAt = null,
    Object? episode = freezed,
  }) {
    return _then(
      _$UserProgressImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        episodeId: null == episodeId
            ? _value.episodeId
            : episodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        completed: null == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastViewedItemId: freezed == lastViewedItemId
            ? _value.lastViewedItemId
            : lastViewedItemId // ignore: cast_nullable_to_non_nullable
                  as String?,
        completedItems: freezed == completedItems
            ? _value.completedItems
            : completedItems // ignore: cast_nullable_to_non_nullable
                  as dynamic,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        episode: freezed == episode
            ? _value.episode
            : episode // ignore: cast_nullable_to_non_nullable
                  as Episode?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProgressImpl implements _UserProgress {
  const _$UserProgressImpl({
    required this.id,
    required this.userId,
    required this.episodeId,
    this.completed = false,
    this.lastViewedItemId,
    required this.completedItems,
    required this.updatedAt,
    this.episode,
  });

  factory _$UserProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProgressImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String episodeId;
  @override
  @JsonKey()
  final bool completed;
  @override
  final String? lastViewedItemId;
  @override
  final dynamic completedItems;
  @override
  final DateTime updatedAt;
  @override
  final Episode? episode;

  @override
  String toString() {
    return 'UserProgress(id: $id, userId: $userId, episodeId: $episodeId, completed: $completed, lastViewedItemId: $lastViewedItemId, completedItems: $completedItems, updatedAt: $updatedAt, episode: $episode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProgressImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.episodeId, episodeId) ||
                other.episodeId == episodeId) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.lastViewedItemId, lastViewedItemId) ||
                other.lastViewedItemId == lastViewedItemId) &&
            const DeepCollectionEquality().equals(
              other.completedItems,
              completedItems,
            ) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.episode, episode) || other.episode == episode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    episodeId,
    completed,
    lastViewedItemId,
    const DeepCollectionEquality().hash(completedItems),
    updatedAt,
    episode,
  );

  /// Create a copy of UserProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProgressImplCopyWith<_$UserProgressImpl> get copyWith =>
      __$$UserProgressImplCopyWithImpl<_$UserProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProgressImplToJson(this);
  }
}

abstract class _UserProgress implements UserProgress {
  const factory _UserProgress({
    required final String id,
    required final String userId,
    required final String episodeId,
    final bool completed,
    final String? lastViewedItemId,
    required final dynamic completedItems,
    required final DateTime updatedAt,
    final Episode? episode,
  }) = _$UserProgressImpl;

  factory _UserProgress.fromJson(Map<String, dynamic> json) =
      _$UserProgressImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get episodeId;
  @override
  bool get completed;
  @override
  String? get lastViewedItemId;
  @override
  dynamic get completedItems;
  @override
  DateTime get updatedAt;
  @override
  Episode? get episode;

  /// Create a copy of UserProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProgressImplCopyWith<_$UserProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
