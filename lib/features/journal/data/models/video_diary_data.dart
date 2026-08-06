import 'package:flutter/material.dart';

class VideoDiaryData {
  final String? videoPath;
  final int durationSeconds;
  final String filterStyle; // 'golden_glow', 'cyber_neon', 'soft_dream', 'vhs_retro', 'clean'
  final String? caption;
  final String? vibeTag;
  final List<String> stickers;

  const VideoDiaryData({
    this.videoPath,
    this.durationSeconds = 15,
    this.filterStyle = 'golden_glow',
    this.caption,
    this.vibeTag = 'Daily Vibe ✨',
    this.stickers = const [],
  });

  Map<String, dynamic> toJson() => {
        'videoPath': videoPath,
        'durationSeconds': durationSeconds,
        'filterStyle': filterStyle,
        'caption': caption,
        'vibeTag': vibeTag,
        'stickers': stickers,
      };

  factory VideoDiaryData.fromJson(Map<String, dynamic> json) {
    return VideoDiaryData(
      videoPath: json['videoPath'] as String? ?? json['filePath'] as String?,
      durationSeconds: json['durationSeconds'] as int? ?? 15,
      filterStyle: json['filterStyle'] as String? ?? 'golden_glow',
      caption: json['caption'] as String? ?? json['text'] as String?,
      vibeTag: json['vibeTag'] as String? ?? 'Daily Vibe ✨',
      stickers: List<String>.from(json['stickers'] as List? ?? []),
    );
  }

  /// Get gradient tint for filter
  List<Color> get filterOverlayGradient {
    switch (filterStyle) {
      case 'cyber_neon':
        return [
          const Color(0xFF7C3AED).withValues(alpha: 0.4),
          const Color(0xFF06B6D4).withValues(alpha: 0.3),
        ];
      case 'soft_dream':
        return [
          const Color(0xFFEC4899).withValues(alpha: 0.35),
          const Color(0xFFF472B6).withValues(alpha: 0.25),
        ];
      case 'vhs_retro':
        return [
          const Color(0xFFD97706).withValues(alpha: 0.3),
          const Color(0xFF451A03).withValues(alpha: 0.4),
        ];
      case 'clean':
        return [
          Colors.black.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.35),
        ];
      case 'golden_glow':
      default:
        return [
          const Color(0xFFF59E0B).withValues(alpha: 0.35),
          const Color(0xFFD97706).withValues(alpha: 0.25),
        ];
    }
  }

  /// Filter display name
  String get filterName {
    switch (filterStyle) {
      case 'cyber_neon':
        return '🔮 Cyber Neon';
      case 'soft_dream':
        return '🎀 Soft Dream';
      case 'vhs_retro':
        return '📼 90s VHS';
      case 'clean':
        return '✨ Clean Aesthetic';
      case 'golden_glow':
      default:
        return '💫 Golden Hour';
    }
  }
}
