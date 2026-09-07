class LmsInstructor {
  final String name;
  final String? designation;
  final String? experience;
  final String? avatarUrl;
  final String? bio;
  final List<String> specializations;

  const LmsInstructor({
    required this.name,
    this.designation,
    this.experience,
    this.avatarUrl,
    this.bio,
    this.specializations = const [],
  });

  factory LmsInstructor.fromJson(Map<String, dynamic> json) {
    return LmsInstructor(
      name: json['name'] as String? ?? 'Expert Instructor',
      designation: json['designation'] as String?,
      experience: json['experience'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'designation': designation,
        'experience': experience,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'specializations': specializations,
      };
}

class AssessmentQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  const AssessmentQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctAnswerIndex: json['correctAnswerIndex'] is int
          ? json['correctAnswerIndex'] as int
          : int.tryParse(json['correctAnswerIndex']?.toString() ?? '0') ?? 0,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctAnswerIndex': correctAnswerIndex,
        'explanation': explanation,
      };
}

class LmsAssessment {
  final String? id;
  final String? chapterId;
  final List<AssessmentQuestion> questions;
  final int passingScore;

  const LmsAssessment({
    this.id,
    this.chapterId,
    required this.questions,
    this.passingScore = 80,
  });

  factory LmsAssessment.fromJson(Map<String, dynamic> json) {
    var rawQuestions = json['questions'];
    List<AssessmentQuestion> qList = [];
    if (rawQuestions is List) {
      qList = rawQuestions
          .map((q) => AssessmentQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
    }
    return LmsAssessment(
      id: json['id'] as String?,
      chapterId: json['chapterId'] as String?,
      questions: qList,
      passingScore: json['passingScore'] is int
          ? json['passingScore'] as int
          : int.tryParse(json['passingScore']?.toString() ?? '80') ?? 80,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'questions': questions.map((q) => q.toJson()).toList(),
        'passingScore': passingScore,
      };
}

class LmsVideo {
  final String? id;
  final String? chapterId;
  final String videoUrl;
  final int duration; // In seconds

  const LmsVideo({
    this.id,
    this.chapterId,
    required this.videoUrl,
    this.duration = 0,
  });

  factory LmsVideo.fromJson(Map<String, dynamic> json) {
    return LmsVideo(
      id: json['id'] as String?,
      chapterId: json['chapterId'] as String?,
      videoUrl: json['videoUrl'] as String? ?? '',
      duration: json['duration'] is int
          ? json['duration'] as int
          : int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'videoUrl': videoUrl,
        'duration': duration,
      };
}

class ChapterFaq {
  final String question;
  final String answer;

  const ChapterFaq({required this.question, required this.answer});

  factory ChapterFaq.fromJson(Map<String, dynamic> json) {
    return ChapterFaq(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };
}

class LmsChapter {
  final String id;
  final String moduleId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String type; // "VIDEO" or "ASSESSMENT"
  final int order;
  final LmsVideo? video;
  final LmsAssessment? assessment;
  final List<String> goodToKnowPoints;
  final List<ChapterFaq> faqs;

  const LmsChapter({
    required this.id,
    required this.moduleId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.type,
    this.order = 0,
    this.video,
    this.assessment,
    this.goodToKnowPoints = const [],
    this.faqs = const [],
  });

  factory LmsChapter.fromJson(Map<String, dynamic> json) {
    List<ChapterFaq> faqList = [];
    if (json['faqs'] is List) {
      for (var f in json['faqs'] as List) {
        if (f is Map<String, dynamic>) {
          faqList.add(ChapterFaq.fromJson(f));
        } else if (f is Map) {
          faqList.add(ChapterFaq.fromJson(Map<String, dynamic>.from(f)));
        }
      }
    }

    return LmsChapter(
      id: json['id'] as String? ?? '',
      moduleId: json['moduleId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Chapter',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      type: (json['type'] as String? ?? 'VIDEO').toUpperCase(),
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      video: json['video'] != null
          ? LmsVideo.fromJson(json['video'] as Map<String, dynamic>)
          : null,
      assessment: json['assessment'] != null
          ? LmsAssessment.fromJson(json['assessment'] as Map<String, dynamic>)
          : null,
      goodToKnowPoints: (json['goodToKnowPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      faqs: faqList,
    );
  }
}

class LmsModule {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final int timeDuration; // In minutes
  final String? thumbnailUrl;
  final int order;
  final List<LmsChapter> chapters;

  const LmsModule({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.timeDuration = 0,
    this.thumbnailUrl,
    this.order = 0,
    this.chapters = const [],
  });

  factory LmsModule.fromJson(Map<String, dynamic> json) {
    var rawChapters = json['chapters'];
    List<LmsChapter> chList = [];
    if (rawChapters is List) {
      chList = rawChapters
          .map((c) => LmsChapter.fromJson(c as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    return LmsModule(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? 'Module',
      description: json['description'] as String?,
      timeDuration: json['timeDuration'] is int
          ? json['timeDuration'] as int
          : int.tryParse(json['timeDuration']?.toString() ?? '0') ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      chapters: chList,
    );
  }
}

class LmsCourse {
  final String id;
  final String title;
  final String? description;
  final int timeDuration; // In minutes
  final String? thumbnailUrl;
  final double price;
  final bool isFree;
  final String? category;
  final List<String> highlights;
  final LmsInstructor? instructor;
  final List<LmsModule> modules;

  const LmsCourse({
    required this.id,
    required this.title,
    this.description,
    this.timeDuration = 0,
    this.thumbnailUrl,
    this.price = 0,
    this.isFree = false,
    this.category,
    this.highlights = const [],
    this.instructor,
    this.modules = const [],
  });

  factory LmsCourse.fromJson(Map<String, dynamic> json) {
    var rawModules = json['modules'];
    List<LmsModule> mList = [];
    if (rawModules is List) {
      mList = rawModules
          .map((m) => LmsModule.fromJson(m as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    return LmsCourse(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Course',
      description: json['description'] as String?,
      timeDuration: json['timeDuration'] is int
          ? json['timeDuration'] as int
          : int.tryParse(json['timeDuration']?.toString() ?? '0') ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      isFree: json['isFree'] as bool? ?? false,
      category: json['category'] as String?,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      instructor: json['instructor'] != null
          ? LmsInstructor.fromJson(json['instructor'] as Map<String, dynamic>)
          : null,
      modules: mList,
    );
  }

  /// Total chapters in all modules
  int get totalChapters =>
      modules.fold(0, (acc, mod) => acc + mod.chapters.length);

  /// Flattened list of chapters in ordered sequence
  List<LmsChapter> get flatChapters {
    final list = <LmsChapter>[];
    for (final mod in modules) {
      list.addAll(mod.chapters);
    }
    return list;
  }
}

class LmsProgress {
  final String? id;
  final String? enrollmentId;
  final String chapterId;
  final bool isCompleted;
  final int? score;
  final List<int>? answers;
  final int? watchTime;
  final DateTime? completedAt;

  const LmsProgress({
    this.id,
    this.enrollmentId,
    required this.chapterId,
    required this.isCompleted,
    this.score,
    this.answers,
    this.watchTime,
    this.completedAt,
  });

  factory LmsProgress.fromJson(Map<String, dynamic> json) {
    List<int>? ansList;
    if (json['answers'] is List) {
      ansList = (json['answers'] as List)
          .map((a) => a is int ? a : int.tryParse(a.toString()) ?? 0)
          .toList();
    }

    return LmsProgress(
      id: json['id'] as String?,
      enrollmentId: json['enrollmentId'] as String?,
      chapterId: json['chapterId'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      score: json['score'] != null
          ? (json['score'] is int
              ? json['score'] as int
              : int.tryParse(json['score'].toString()))
          : null,
      answers: ansList,
      watchTime: json['watchTime'] != null
          ? (json['watchTime'] is int
              ? json['watchTime'] as int
              : int.tryParse(json['watchTime'].toString()))
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enrollmentId': enrollmentId,
        'chapterId': chapterId,
        'isCompleted': isCompleted,
        'score': score,
        'answers': answers,
        'watchTime': watchTime,
        'completedAt': completedAt?.toIso8601String(),
      };
}

class LmsEnrollment {
  final String id;
  final String userId;
  final String courseId;
  final String status;
  final LmsCourse course;
  final List<LmsProgress> progress;
  final DateTime? createdAt;

  const LmsEnrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.status,
    required this.course,
    this.progress = const [],
    this.createdAt,
  });

  factory LmsEnrollment.fromJson(Map<String, dynamic> json) {
    var rawProgress = json['progress'];
    List<LmsProgress> progList = [];
    if (rawProgress is List) {
      progList = rawProgress
          .map((p) => LmsProgress.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return LmsEnrollment(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      course: LmsCourse.fromJson(
          json['course'] as Map<String, dynamic>? ?? const {}),
      progress: progList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  int get completedChaptersCount =>
      progress.where((p) => p.isCompleted).length;

  int get progressPercent {
    final total = course.totalChapters;
    if (total == 0) return 0;
    return ((completedChaptersCount / total) * 100).round();
  }

  int get remainingHours {
    if (course.timeDuration <= 0) return 0;
    final pct = progressPercent;
    return (((100 - pct) / 100) * (course.timeDuration / 60)).ceil();
  }
}

class ChapterComment {
  final String id;
  final String chapterId;
  final String authorName;
  final String authorInitials;
  final String text;
  final DateTime timestamp;
  final int likes;
  final bool liked;

  const ChapterComment({
    required this.id,
    required this.chapterId,
    required this.authorName,
    required this.authorInitials,
    required this.text,
    required this.timestamp,
    required this.likes,
    required this.liked,
  });

  factory ChapterComment.fromJson(Map<String, dynamic> json) {
    return ChapterComment(
      id: json['id'] as String? ?? '',
      chapterId: json['chapterId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Learner',
      authorInitials: json['authorInitials'] as String? ?? 'L',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      likes: json['likes'] is int
          ? json['likes'] as int
          : int.tryParse(json['likes']?.toString() ?? '0') ?? 0,
      liked: json['liked'] as bool? ?? false,
    );
  }

  ChapterComment copyWith({int? likes, bool? liked}) {
    return ChapterComment(
      id: id,
      chapterId: chapterId,
      authorName: authorName,
      authorInitials: authorInitials,
      text: text,
      timestamp: timestamp,
      likes: likes ?? this.likes,
      liked: liked ?? this.liked,
    );
  }
}

class ChapterLikesInfo {
  final bool liked;
  final int count;

  const ChapterLikesInfo({required this.liked, required this.count});

  factory ChapterLikesInfo.fromJson(Map<String, dynamic> json) {
    return ChapterLikesInfo(
      liked: json['liked'] as bool? ?? false,
      count: json['likesCount'] is int
          ? json['likesCount'] as int
          : (json['count'] is int
              ? json['count'] as int
              : int.tryParse(json['likesCount']?.toString() ?? '0') ?? 0),
    );
  }
}
