import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:infano_care_mobile/features/courses/data/models/course_models.dart';

class CoursesRepository {
  final Dio _dio;

  CoursesRepository(this._dio);

  /// Fetch user enrolled courses with progress
  Future<List<LmsEnrollment>> getMyCourses() async {
    try {
      final response = await _dio.get('lms/my-courses');
      if (response.data is List) {
        return (response.data as List)
            .map((item) => LmsEnrollment.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CoursesRepository] Error fetching my courses: $e');
      rethrow;
    }
  }

  /// Fetch all active explore courses
  Future<List<LmsCourse>> getExploreCourses() async {
    try {
      final response = await _dio.get('lms/explore');
      if (response.data is List) {
        return (response.data as List)
            .map((item) => LmsCourse.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CoursesRepository] Error fetching explore courses: $e');
      rethrow;
    }
  }

  /// Fetch course details (modules, chapters, instructor, etc.)
  Future<LmsCourse> getCourseDetails(String courseId) async {
    try {
      final response = await _dio.get('lms/$courseId');
      return LmsCourse.fromJson(response.data);
    } catch (e) {
      debugPrint('[CoursesRepository] Error fetching course details: $e');
      rethrow;
    }
  }

  /// Fetch user progress for a course
  Future<List<LmsProgress>> getCourseProgress(String courseId) async {
    try {
      final response = await _dio.get('lms/$courseId/progress');
      if (response.data != null &&
          response.data is Map &&
          response.data['progress'] is List) {
        return (response.data['progress'] as List)
            .map((item) => LmsProgress.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CoursesRepository] Error fetching course progress: $e');
      return [];
    }
  }

  /// Mark chapter as completed (with optional quiz score and answers)
  Future<LmsProgress> markChapterComplete(
    String courseId,
    String chapterId, {
    int? score,
    List<int>? answers,
    int? watchTime,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (score != null) payload['score'] = score;
      if (answers != null) payload['answers'] = answers;
      if (watchTime != null) payload['watchTime'] = watchTime;

      final response = await _dio.post(
        'lms/$courseId/chapters/$chapterId/complete',
        data: payload,
      );

      if (response.data != null && response.data['progress'] != null) {
        return LmsProgress.fromJson(
            response.data['progress'] as Map<String, dynamic>);
      }
      return LmsProgress(chapterId: chapterId, isCompleted: true, score: score);
    } catch (e) {
      debugPrint('[CoursesRepository] Error marking chapter complete: $e');
      rethrow;
    }
  }

  /// Fetch comments for a chapter
  Future<List<ChapterComment>> getChapterComments(String chapterId) async {
    try {
      final response = await _dio.get('lms/chapters/$chapterId/comments');
      if (response.data is List) {
        return (response.data as List)
            .map((item) =>
                ChapterComment.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CoursesRepository] Error fetching chapter comments: $e');
      return [];
    }
  }

  /// Post a new comment on a chapter
  Future<ChapterComment> postChapterComment(
      String chapterId, String text) async {
    try {
      final response = await _dio.post(
        'lms/chapters/$chapterId/comments',
        data: {'text': text},
      );
      return ChapterComment.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[CoursesRepository] Error posting comment: $e');
      rethrow;
    }
  }

  /// Toggle like on a comment
  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    try {
      final response =
          await _dio.post('lms/comments/$commentId/toggle-like');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[CoursesRepository] Error toggling comment like: $e');
      rethrow;
    }
  }

  /// Fetch chapter likes count and user liked status
  Future<ChapterLikesInfo> getChapterLikes(String chapterId) async {
    try {
      final response = await _dio.get('lms/chapters/$chapterId/likes');
      if (response.data != null) {
        return ChapterLikesInfo.fromJson(
            response.data as Map<String, dynamic>);
      }
      return const ChapterLikesInfo(liked: false, count: 0);
    } catch (e) {
      debugPrint('[CoursesRepository] Error fetching chapter likes: $e');
      return const ChapterLikesInfo(liked: false, count: 0);
    }
  }

  /// Toggle like on a chapter
  Future<ChapterLikesInfo> toggleChapterLike(String chapterId) async {
    try {
      final response =
          await _dio.post('lms/chapters/$chapterId/toggle-like');
      if (response.data != null) {
        return ChapterLikesInfo.fromJson(
            response.data as Map<String, dynamic>);
      }
      return const ChapterLikesInfo(liked: false, count: 0);
    } catch (e) {
      debugPrint('[CoursesRepository] Error toggling chapter like: $e');
      rethrow;
    }
  }
}
