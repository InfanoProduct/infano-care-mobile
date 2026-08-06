import 'dart:ui';
import 'package:flutter/material.dart';

enum JournalMode {
  freeWrite,
  guidedPrompt,
  doodle,
  voiceNote,
  moodColor,
  photoBoard,
  letterMode,
  videoDiary,
  blackoutPoetry;

  String get apiValue {
    switch (this) {
      case JournalMode.freeWrite: return 'free_write';
      case JournalMode.guidedPrompt: return 'guided_prompt';
      case JournalMode.doodle: return 'doodle';
      case JournalMode.voiceNote: return 'voice_note';
      case JournalMode.moodColor: return 'mood_color';
      case JournalMode.photoBoard: return 'photo_board';
      case JournalMode.letterMode: return 'letter_mode';
      case JournalMode.videoDiary: return 'video_diary';
      case JournalMode.blackoutPoetry: return 'blackout_poetry';
    }
  }

  static JournalMode fromApi(String value) {
    switch (value.toLowerCase()) {
      case 'free_write':
      case 'freewrite':
        return JournalMode.freeWrite;
      case 'guided_prompt':
      case 'guided':
      case 'prompt':
        return JournalMode.guidedPrompt;
      case 'doodle':
      case 'draw':
        return JournalMode.doodle;
      case 'voice_note':
      case 'voice':
      case 'audio':
        return JournalMode.voiceNote;
      case 'mood_color':
      case 'mood':
      case 'color':
        return JournalMode.moodColor;
      case 'photo_board':
      case 'photo':
      case 'photos':
        return JournalMode.photoBoard;
      case 'letter_mode':
      case 'letter':
        return JournalMode.letterMode;
      case 'video_diary':
      case 'video':
        return JournalMode.videoDiary;
      case 'blackout_poetry':
      case 'blackout':
      case 'poem':
        return JournalMode.blackoutPoetry;
      case 'sticker_decorate':
      case 'comic_strip':
      case 'list_journal':
      default:
        return JournalMode.freeWrite;
    }
  }

  String get displayName {
    switch (this) {
      case JournalMode.freeWrite: return 'Free Write';
      case JournalMode.guidedPrompt: return 'Guided Prompt';
      case JournalMode.doodle: return 'Doodle';
      case JournalMode.voiceNote: return 'Voice Note';
      case JournalMode.moodColor: return 'Mood Color';
      case JournalMode.photoBoard: return 'Photo Board';
      case JournalMode.letterMode: return 'Letter Mode';
      case JournalMode.videoDiary: return 'Video Diary';
      case JournalMode.blackoutPoetry: return 'Blackout Poetry';
    }
  }

  String get emoji {
    switch (this) {
      case JournalMode.freeWrite: return '✏️';
      case JournalMode.guidedPrompt: return '💡';
      case JournalMode.doodle: return '🎨';
      case JournalMode.voiceNote: return '🎤';
      case JournalMode.moodColor: return '🌈';
      case JournalMode.photoBoard: return '📸';
      case JournalMode.letterMode: return '💌';
      case JournalMode.videoDiary: return '🎬';
      case JournalMode.blackoutPoetry: return '🖊️';
    }
  }

  String get description {
    switch (this) {
      case JournalMode.freeWrite: return 'Write freely, no rules';
      case JournalMode.guidedPrompt: return 'Answer today\'s question';
      case JournalMode.doodle: return 'Draw your feelings';
      case JournalMode.voiceNote: return 'Talk it out, 90 sec max';
      case JournalMode.moodColor: return 'Paint your mood in colors';
      case JournalMode.photoBoard: return 'Capture a moment';
      case JournalMode.letterMode: return 'Write to someone';
      case JournalMode.videoDiary: return '60-sec video just for you';
      case JournalMode.blackoutPoetry: return 'Find your poem in words';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case JournalMode.freeWrite:
        return [const Color(0xFF7C3AED), const Color(0xFFA855F7)];
      case JournalMode.guidedPrompt:
        return [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)];
      case JournalMode.doodle:
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case JournalMode.voiceNote:
        return [const Color(0xFFEF4444), const Color(0xFFF97316)];
      case JournalMode.moodColor:
        return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case JournalMode.photoBoard:
        return [const Color(0xFF0D9488), const Color(0xFF34D399)];
      case JournalMode.letterMode:
        return [const Color(0xFFDB2777), const Color(0xFFF472B6)];
      case JournalMode.videoDiary:
        return [const Color(0xFF059669), const Color(0xFF10B981)];
      case JournalMode.blackoutPoetry:
        return [const Color(0xFF374151), const Color(0xFF6B7280)];
    }
  }
}

class JournalEntry {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JournalMode mode;
  final String? promptId;
  final String? moodTag;
  final String? moodColor;
  final Map<String, dynamic> content;
  final bool isSealedTimeCapsule;
  final DateTime? capsuleRevealDate;
  final String visibility;
  final int pointsAwarded;
  final String? title;
  final JournalPrompt? prompt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.mode,
    this.promptId,
    this.moodTag,
    this.moodColor,
    required this.content,
    required this.isSealedTimeCapsule,
    this.capsuleRevealDate,
    required this.visibility,
    required this.pointsAwarded,
    this.title,
    this.prompt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.parse(json['createdAt'] as String),
      mode: JournalMode.fromApi(json['mode'] as String),
      promptId: json['promptId'] as String?,
      moodTag: json['moodTag'] as String?,
      moodColor: json['moodColor'] as String?,
      content: Map<String, dynamic>.from(json['content'] as Map? ?? {}),
      isSealedTimeCapsule: json['isSealedTimeCapsule'] as bool? ?? false,
      capsuleRevealDate: json['capsuleRevealDate'] != null
          ? DateTime.parse(json['capsuleRevealDate'] as String)
          : null,
      visibility: json['visibility'] as String? ?? 'private',
      pointsAwarded: json['pointsAwarded'] as int? ?? 0,
      title: json['title'] as String?,
      prompt: json['prompt'] != null
          ? JournalPrompt.fromJson(json['prompt'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'mode': mode.apiValue,
    'promptId': promptId,
    'moodTag': moodTag,
    'moodColor': moodColor,
    'content': content,
    'isSealedTimeCapsule': isSealedTimeCapsule,
    'capsuleRevealDate': capsuleRevealDate?.toIso8601String(),
    'visibility': visibility,
    'pointsAwarded': pointsAwarded,
    'title': title,
  };

  /// Returns a preview string for the scrapbook feed
  String get preview {
    switch (mode) {
      case JournalMode.freeWrite:
      case JournalMode.guidedPrompt:
        return (content['text'] as String? ?? '').take(120);
      case JournalMode.letterMode:
        final to = content['to'] as String? ?? 'Someone';
        final body = (content['body'] as String? ?? '').take(80);
        return 'Dear $to — $body';
      case JournalMode.moodColor:
        return 'A mood color splash';
      case JournalMode.doodle:
        return 'A doodle page';
      case JournalMode.voiceNote:
        return 'A voice note';
      case JournalMode.videoDiary:
        return 'A video diary entry';
      case JournalMode.photoBoard:
        return 'A photo mood board';
      case JournalMode.blackoutPoetry:
        final poem = content['poem'] as String?;
        if (poem != null && poem.isNotEmpty) {
          return poem.replaceAll('\n', '  ·  ').take(120);
        }
        final words = (content['selectedWords'] as List? ?? []).join(' · ');
        return words.isEmpty ? 'A blackout poem' : words;
    }
  }
}

class JournalPrompt {
  final String id;
  final String category;
  final String text;
  final List<String> bestModes;
  final List<String> options;

  const JournalPrompt({
    required this.id,
    required this.category,
    required this.text,
    required this.bestModes,
    this.options = const [],
  });

  factory JournalPrompt.fromJson(Map<String, dynamic> json) => JournalPrompt(
    id: json['id'] as String,
    category: json['category'] as String,
    text: json['text'] as String,
    bestModes: List<String>.from(json['bestModes'] as List? ?? []),
    options: List<String>.from(json['options'] as List? ?? []),
  );
}

extension StringTake on String {
  String take(int n) => length > n ? '${substring(0, n)}…' : this;
}

class DoodleStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DoodleStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  Map<String, dynamic> toJson() => {
    'color': color.value,
    'width': strokeWidth,
    'isEraser': isEraser,
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
  };

  factory DoodleStroke.fromJson(Map<String, dynamic> json) => DoodleStroke(
    color: Color(json['color'] as int? ?? 0xFF7C3AED),
    strokeWidth: (json['width'] as num? ?? 4.0).toDouble(),
    isEraser: json['isEraser'] as bool? ?? false,
    points: (json['points'] as List? ?? []).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList(),
  );
}

class DoodlePainter extends CustomPainter {
  final List<DoodleStroke> strokes;
  final DoodleStroke? currentStroke;

  DoodlePainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allStrokes = [...strokes, if (currentStroke != null) currentStroke!];

    for (final stroke in allStrokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.isEraser ? Colors.white : stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawPoints(PointMode.points, stroke.points, paint);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) => true;
}
