import 'dart:convert';

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

  factory LmsInstructor.fromJson(dynamic json) {
    if (json == null) return const LmsInstructor(name: 'Expert Instructor');
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    return LmsInstructor(
      name: map['name']?.toString() ?? 'Expert Instructor',
      designation: map['designation']?.toString(),
      experience: map['experience']?.toString(),
      avatarUrl: map['avatarUrl']?.toString(),
      bio: map['bio']?.toString(),
      specializations: (map['specializations'] is List)
          ? (map['specializations'] as List).map((e) => e.toString()).toList()
          : const [],
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

  factory AssessmentQuestion.fromJson(dynamic json) {
    if (json == null) {
      return const AssessmentQuestion(
        question: '',
        options: [],
        correctAnswerIndex: 0,
      );
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    final correctIdx = map['correctOptionIndex'] ?? map['correctAnswerIndex'];
    return AssessmentQuestion(
      question: map['question']?.toString() ?? '',
      options: (map['options'] is List)
          ? (map['options'] as List).map((e) => e.toString()).toList()
          : const [],
      correctAnswerIndex: correctIdx is int
          ? correctIdx
          : int.tryParse(correctIdx?.toString() ?? '0') ?? 0,
      explanation: map['explanation']?.toString(),
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

  factory LmsAssessment.fromJson(dynamic json) {
    if (json == null) return const LmsAssessment(questions: []);
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    var rawQuestions = map['questions'];
    if (rawQuestions is String) {
      try {
        rawQuestions = jsonDecode(rawQuestions);
      } catch (_) {}
    }
    List<AssessmentQuestion> qList = [];
    if (rawQuestions is List) {
      for (var q in rawQuestions) {
        if (q != null) {
          qList.add(AssessmentQuestion.fromJson(q));
        }
      }
    }
    return LmsAssessment(
      id: map['id']?.toString(),
      chapterId: map['chapterId']?.toString(),
      questions: qList,
      passingScore: map['passingScore'] is int
          ? map['passingScore'] as int
          : int.tryParse(map['passingScore']?.toString() ?? '80') ?? 80,
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

  factory LmsVideo.fromJson(dynamic json) {
    if (json == null) return const LmsVideo(videoUrl: '');
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    return LmsVideo(
      id: map['id']?.toString(),
      chapterId: map['chapterId']?.toString(),
      videoUrl: map['videoUrl']?.toString() ?? '',
      duration: map['duration'] is int
          ? map['duration'] as int
          : int.tryParse(map['duration']?.toString() ?? '0') ?? 0,
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

  factory ChapterFaq.fromJson(dynamic json) {
    if (json == null) return const ChapterFaq(question: '', answer: '');
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    return ChapterFaq(
      question: map['question']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
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

  factory LmsChapter.fromJson(dynamic json) {
    if (json == null) {
      return const LmsChapter(
        id: '',
        moduleId: '',
        title: 'Untitled Chapter',
        type: 'VIDEO',
      );
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};

    List<ChapterFaq> faqList = [];
    var rawFaqs = map['faqs'];
    if (rawFaqs is String) {
      try {
        rawFaqs = jsonDecode(rawFaqs);
      } catch (_) {}
    }
    if (rawFaqs is List) {
      for (var f in rawFaqs) {
        if (f != null) {
          faqList.add(ChapterFaq.fromJson(f));
        }
      }
    }

    List<String> goodPoints = [];
    var rawPoints = map['goodToKnowPoints'];
    if (rawPoints is String) {
      try {
        rawPoints = jsonDecode(rawPoints);
      } catch (_) {}
    }
    if (rawPoints is List) {
      goodPoints = rawPoints.map((e) => e.toString()).toList();
    }

    return LmsChapter(
      id: map['id']?.toString() ?? '',
      moduleId: map['moduleId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Chapter',
      description: map['description']?.toString(),
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      type: (map['type']?.toString() ?? 'VIDEO').toUpperCase(),
      order: map['order'] is int
          ? map['order'] as int
          : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      video: map['video'] != null ? LmsVideo.fromJson(map['video']) : null,
      assessment: map['assessment'] != null
          ? LmsAssessment.fromJson(map['assessment'])
          : null,
      goodToKnowPoints: goodPoints,
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

  factory LmsModule.fromJson(dynamic json) {
    if (json == null) {
      return const LmsModule(id: '', courseId: '', title: 'Module');
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    var rawChapters = map['chapters'];
    if (rawChapters is String) {
      try {
        rawChapters = jsonDecode(rawChapters);
      } catch (_) {}
    }
    List<LmsChapter> chList = [];
    if (rawChapters is List) {
      for (var c in rawChapters) {
        if (c != null) {
          chList.add(LmsChapter.fromJson(c));
        }
      }
      chList.sort((a, b) => a.order.compareTo(b.order));
    }

    return LmsModule(
      id: map['id']?.toString() ?? '',
      courseId: map['courseId']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Module',
      description: map['description']?.toString(),
      timeDuration: map['timeDuration'] is int
          ? map['timeDuration'] as int
          : int.tryParse(map['timeDuration']?.toString() ?? '0') ?? 0,
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      order: map['order'] is int
          ? map['order'] as int
          : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
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

  factory LmsCourse.fromJson(dynamic json) {
    if (json == null) {
      return const LmsCourse(id: '', title: 'Untitled Course');
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};

    var rawModules = map['modules'];
    if (rawModules is String) {
      try {
        rawModules = jsonDecode(rawModules);
      } catch (_) {}
    }
    List<LmsModule> mList = [];
    if (rawModules is List) {
      for (var m in rawModules) {
        if (m != null) {
          mList.add(LmsModule.fromJson(m));
        }
      }
      mList.sort((a, b) => a.order.compareTo(b.order));
    }

    List<String> hlList = [];
    var rawHl = map['highlights'];
    if (rawHl is String) {
      try {
        rawHl = jsonDecode(rawHl);
      } catch (_) {}
    }
    if (rawHl is List) {
      hlList = rawHl.map((e) => e.toString()).toList();
    }

    return LmsCourse(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Course',
      description: map['description']?.toString(),
      timeDuration: map['timeDuration'] is int
          ? map['timeDuration'] as int
          : int.tryParse(map['timeDuration']?.toString() ?? '0') ?? 0,
      thumbnailUrl: map['thumbnailUrl']?.toString(),
      price: map['price'] is num
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      isFree: map['isFree'] as bool? ??
          (map['price'] == 0 || map['price'] == null),
      category: map['category']?.toString(),
      highlights: hlList,
      instructor: map['instructor'] != null
          ? LmsInstructor.fromJson(map['instructor'])
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

  factory LmsProgress.fromJson(dynamic json) {
    if (json == null) {
      return const LmsProgress(chapterId: '', isCompleted: false);
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    List<int>? ansList;
    var rawAnswers = map['answers'];
    if (rawAnswers is String) {
      try {
        rawAnswers = jsonDecode(rawAnswers);
      } catch (_) {}
    }
    if (rawAnswers is List) {
      ansList = rawAnswers
          .map((a) => a is int ? a : int.tryParse(a.toString()) ?? 0)
          .toList();
    }

    return LmsProgress(
      id: map['id']?.toString(),
      enrollmentId: map['enrollmentId']?.toString(),
      chapterId: map['chapterId']?.toString() ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      score: map['score'] is int
          ? map['score'] as int
          : int.tryParse(map['score']?.toString() ?? ''),
      answers: ansList,
      watchTime: map['watchTime'] is int
          ? map['watchTime'] as int
          : int.tryParse(map['watchTime']?.toString() ?? ''),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
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

  factory LmsEnrollment.fromJson(dynamic json) {
    if (json == null) {
      return const LmsEnrollment(
        id: '',
        userId: '',
        courseId: '',
        status: 'ACTIVE',
        course: LmsCourse(id: '', title: ''),
      );
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    var rawProgress = map['progress'];
    List<LmsProgress> progList = [];
    if (rawProgress is List) {
      for (var p in rawProgress) {
        if (p != null) {
          progList.add(LmsProgress.fromJson(p));
        }
      }
    }

    return LmsEnrollment(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      courseId: map['courseId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'ACTIVE',
      course: LmsCourse.fromJson(map['course']),
      progress: progList,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
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

  factory ChapterComment.fromJson(dynamic json) {
    if (json == null) {
      return ChapterComment(
        id: '',
        chapterId: '',
        authorName: 'Learner',
        authorInitials: 'L',
        text: '',
        timestamp: DateTime.now(),
        likes: 0,
        liked: false,
      );
    }
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    return ChapterComment(
      id: map['id']?.toString() ?? '',
      chapterId: map['chapterId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? 'Learner',
      authorInitials: map['authorInitials']?.toString() ?? 'L',
      text: map['text']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      likes: map['likes'] is int
          ? map['likes'] as int
          : int.tryParse(map['likes']?.toString() ?? '0') ?? 0,
      liked: map['liked'] as bool? ?? false,
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

  factory ChapterLikesInfo.fromJson(dynamic json) {
    if (json == null) return const ChapterLikesInfo(liked: false, count: 0);
    final Map<String, dynamic> map =
        json is Map ? Map<String, dynamic>.from(json) : {};
    return ChapterLikesInfo(
      liked: map['liked'] as bool? ?? false,
      count: map['likesCount'] is int
          ? map['likesCount'] as int
          : (map['count'] is int
              ? map['count'] as int
              : int.tryParse(map['likesCount']?.toString() ??
                      map['count']?.toString() ??
                      '0') ??
                  0),
    );
  }
}
