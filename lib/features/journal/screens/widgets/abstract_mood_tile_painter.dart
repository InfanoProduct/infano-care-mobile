import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Represents an individual color splash or shape on the abstract tile
class MoodSplashBlob {
  final double normalizedX; // 0.0 to 1.0
  final double normalizedY; // 0.0 to 1.0
  final double radius;      // 0.05 to 0.45 relative to tile width
  final int colorIndex;
  final double opacity;
  final int shapeStyle;     // 0: orb, 1: oval, 2: starburst/shard, 3: ribbon curve, 4: polygon cell
  final double rotation;    // in radians

  const MoodSplashBlob({
    required this.normalizedX,
    required this.normalizedY,
    required this.radius,
    required this.colorIndex,
    this.opacity = 0.75,
    this.shapeStyle = 0,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'nx': normalizedX,
    'ny': normalizedY,
    'r': radius,
    'ci': colorIndex,
    'op': opacity,
    'st': shapeStyle,
    'rot': rotation,
  };

  factory MoodSplashBlob.fromJson(Map<String, dynamic> json) => MoodSplashBlob(
    normalizedX: (json['nx'] as num? ?? 0.5).toDouble(),
    normalizedY: (json['ny'] as num? ?? 0.5).toDouble(),
    radius: (json['r'] as num? ?? 0.2).toDouble(),
    colorIndex: json['ci'] as int? ?? 0,
    opacity: (json['op'] as num? ?? 0.75).toDouble(),
    shapeStyle: json['st'] as int? ?? 0,
    rotation: (json['rot'] as num? ?? 0.0).toDouble(),
  );

  MoodSplashBlob copyWith({
    double? normalizedX,
    double? normalizedY,
    double? radius,
    int? colorIndex,
    double? opacity,
    int? shapeStyle,
    double? rotation,
  }) => MoodSplashBlob(
    normalizedX: normalizedX ?? this.normalizedX,
    normalizedY: normalizedY ?? this.normalizedY,
    radius: radius ?? this.radius,
    colorIndex: colorIndex ?? this.colorIndex,
    opacity: opacity ?? this.opacity,
    shapeStyle: shapeStyle ?? this.shapeStyle,
    rotation: rotation ?? this.rotation,
  );
}

const Map<String, String> kDefaultColorEmotions = {
  '#FF6B6B': 'Vibrant Passion',
  '#FFA500': 'Warm Energy',
  '#FFD700': 'Radiant Optimism',
  '#4FC3F7': 'Peaceful Clarity',
  '#0288D1': 'Tranquil Reflection',
  '#CE93D8': 'Gentle Intuition',
  '#7B1FA2': 'Mystic Wisdom',
  '#80CBC4': 'Fresh Renewal',
  '#00796B': 'Grounding Balance',
  '#F48FB1': 'Soft Tenderness',
  '#C2185B': 'Deep Love',
  '#607D8B': 'Quiet Contemplation',
  '#263238': 'Inner Stillness',
  '#EF9A9A': 'Warm Empathy',
  '#B71C1C': 'Bold Strength',
  '#A5D6A7': 'Nature Harmony',
  '#2E7D32': 'Deep Healing',
  '#7986CB': 'Twilight Dreams',
  '#1A237E': 'Midnight Mystery',
  '#FFAB91': 'Cozy Comfort',
  '#BF360C': 'Fiery Purpose',
  '#B3E5FC': 'Sky Serenity',
  '#01579B': 'Infinite Focus',
};

/// Data payload stored in JournalEntry.content for mood_color mode
class AbstractMoodTileData {
  final List<String> colors; // Hex codes
  final String patternStyle; // 'fluid', 'geometric', 'cosmic', 'marble', 'stained_glass'
  final String textureOverlay; // 'sparkles', 'glass', 'aurora', 'none'
  final List<MoodSplashBlob> blobs;
  final double intensity;
  final String? caption;
  final String? label;
  final Map<String, String> colorMeanings;

  const AbstractMoodTileData({
    required this.colors,
    this.patternStyle = 'fluid',
    this.textureOverlay = 'glass',
    required this.blobs,
    this.intensity = 0.7,
    this.caption,
    this.label,
    this.colorMeanings = const {},
  });

  List<String> get emotionTags {
    final tags = <String>[];
    for (final hex in colors) {
      final keyUpper = hex.toUpperCase();
      final meaning = colorMeanings[hex] ?? colorMeanings[keyUpper] ?? kDefaultColorEmotions[keyUpper] ?? kDefaultColorEmotions[hex];
      if (meaning != null && !tags.contains(meaning)) {
        tags.add(meaning);
      }
    }
    return tags;
  }

  Map<String, dynamic> toJson() => {
    'colors': colors,
    'patternStyle': patternStyle,
    'textureOverlay': textureOverlay,
    'blobs': blobs.map((b) => b.toJson()).toList(),
    'intensity': intensity,
    if (caption != null) 'caption': caption,
    if (label != null) 'label': label,
    if (colorMeanings.isNotEmpty) 'colorMeanings': colorMeanings,
  };

  factory AbstractMoodTileData.fromJson(Map<String, dynamic> json) {
    final hexList = List<String>.from(json['colors'] as List? ?? ['#7C3AED', '#EC4899', '#3B82F6']);
    final rawBlobs = json['blobs'] as List?;
    final patternStyle = json['patternStyle'] as String? ?? 'fluid';
    final label = json['label'] as String?;
    final caption = json['caption'] as String?;
    final rawMeanings = Map<String, String>.from(json['colorMeanings'] as Map? ?? {});

    List<MoodSplashBlob> blobList;
    if (rawBlobs != null && rawBlobs.isNotEmpty) {
      blobList = rawBlobs.map((b) => MoodSplashBlob.fromJson(b as Map<String, dynamic>)).toList();
    } else {
      blobList = generateSeedBlobs(hexList.length, patternStyle: patternStyle);
    }

    return AbstractMoodTileData(
      colors: hexList,
      patternStyle: patternStyle,
      textureOverlay: json['textureOverlay'] as String? ?? 'glass',
      blobs: blobList,
      intensity: (json['intensity'] as num? ?? 0.7).toDouble(),
      caption: caption,
      label: label,
      colorMeanings: rawMeanings,
    );
  }

  /// Create default data for backwards compatibility or fresh initialization
  factory AbstractMoodTileData.defaultForColors(
    List<String> colors, {
    String patternStyle = 'fluid',
    String? label,
    String? caption,
  }) {
    return AbstractMoodTileData(
      colors: colors.isEmpty ? ['#7C3AED', '#EC4899'] : colors,
      patternStyle: patternStyle,
      textureOverlay: 'glass',
      blobs: generateSeedBlobs(colors.length, patternStyle: patternStyle),
      caption: caption,
      label: label,
    );
  }

  static List<MoodSplashBlob> generateSeedBlobs(int numColors, {String patternStyle = 'fluid'}) {
    final rand = math.Random(patternStyle.hashCode);
    final count = patternStyle == 'geometric' ? 9 : (patternStyle == 'stained_glass' ? 12 : 8);
    final blobs = <MoodSplashBlob>[];

    for (int i = 0; i < count; i++) {
      final nx = 0.15 + rand.nextDouble() * 0.7;
      final ny = 0.15 + rand.nextDouble() * 0.7;
      final radius = 0.15 + rand.nextDouble() * 0.25;
      final colorIdx = (i % math.max(1, numColors)).toInt();
      final opacity = 0.4 + rand.nextDouble() * 0.45;
      final rot = rand.nextDouble() * math.pi * 2;
      int shapeStyle = 0;

      if (patternStyle == 'geometric') {
        shapeStyle = (i % 2 == 0) ? 1 : 3;
      } else if (patternStyle == 'cosmic') {
        shapeStyle = (i % 3 == 0) ? 2 : 0;
      } else if (patternStyle == 'marble') {
        shapeStyle = 3;
      } else if (patternStyle == 'stained_glass') {
        shapeStyle = 4;
      }

      blobs.add(MoodSplashBlob(
        normalizedX: nx,
        normalizedY: ny,
        radius: radius,
        colorIndex: colorIdx,
        opacity: opacity,
        shapeStyle: shapeStyle,
        rotation: rot,
      ));
    }
    return blobs;
  }
}

/// CustomPainter rendering abstract tiles with smooth gradients, blobs, and textures
class AbstractMoodTilePainter extends CustomPainter {
  final AbstractMoodTileData tileData;

  AbstractMoodTilePainter({required this.tileData});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final parsedColors = tileData.colors.map(_hexToColor).toList();
    if (parsedColors.isEmpty) parsedColors.add(const Color(0xFF7C3AED));
    if (parsedColors.length < 2) parsedColors.add(parsedColors.first.withValues(alpha: 0.8));

    final rect = Offset.zero & size;

    // 1. Base Gradient Canvas
    final baseGradient = LinearGradient(
      colors: parsedColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final basePaint = Paint()..shader = baseGradient.createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 2. Pattern Style Specific Painting
    switch (tileData.patternStyle) {
      case 'geometric':
        _paintGeometricStyle(canvas, size, parsedColors);
        break;
      case 'cosmic':
        _paintCosmicStyle(canvas, size, parsedColors);
        break;
      case 'marble':
        _paintMarbleStyle(canvas, size, parsedColors);
        break;
      case 'stained_glass':
        _paintStainedGlassStyle(canvas, size, parsedColors);
        break;
      case 'fluid':
      default:
        _paintFluidStyle(canvas, size, parsedColors);
        break;
    }

    // 3. User Splash Blobs
    for (final blob in tileData.blobs) {
      _paintBlob(canvas, size, blob, parsedColors);
    }

    // 4. Texture & Finish Overlays
    _paintTextureOverlay(canvas, size, tileData.textureOverlay);
  }

  void _paintFluidStyle(Canvas canvas, Size size, List<Color> colors) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.max(size.width, size.height) * 0.6;
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.last.withValues(alpha: 0.5),
          colors.first.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, radialPaint);
  }

  void _paintGeometricStyle(Canvas canvas, Size size, List<Color> colors) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw background angled shards
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width * 0.2, size.height)
      ..close();

    paint.shader = LinearGradient(
      colors: [colors[colors.length ~/ 2].withValues(alpha: 0.35), colors.first.withValues(alpha: 0.15)],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawPath(path, borderPaint);
  }

  void _paintCosmicStyle(Canvas canvas, Size size, List<Color> colors) {
    // Ambient dark overlay for cosmic depth
    final darkPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRect(Offset.zero & size, darkPaint);

    // Glowing core
    final coreCenter = Offset(size.width * 0.7, size.height * 0.3);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.6), colors.first.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: coreCenter, radius: size.width * 0.4));
    canvas.drawCircle(coreCenter, size.width * 0.4, corePaint);

    // Star sparkles
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    final rand = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final sx = rand.nextDouble() * size.width;
      final sy = rand.nextDouble() * size.height;
      final sr = 1.0 + rand.nextDouble() * 2.5;
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }
  }

  void _paintMarbleStyle(Canvas canvas, Size size, List<Color> colors) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startY = size.height * (0.15 + i * 0.18);
      path.moveTo(0, startY);
      path.cubicTo(
        size.width * 0.3, startY + (i % 2 == 0 ? 30 : -30),
        size.width * 0.7, startY + (i % 2 == 0 ? -40 : 40),
        size.width, startY + (i % 2 == 0 ? 20 : -20),
      );

      paint.strokeWidth = 12.0 + (i * 4);
      paint.color = colors[i % colors.length].withValues(alpha: 0.35);
      canvas.drawPath(path, paint);
    }
  }

  void _paintStainedGlassStyle(Canvas canvas, Size size, List<Color> colors) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.4);

    final cols = 3;
    final rows = 3;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final rand = math.Random(101);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        final cellColor = colors[(r + c) % colors.length].withValues(alpha: 0.3 + rand.nextDouble() * 0.3);
        canvas.drawRect(rect, Paint()..color = cellColor);
        canvas.drawRect(rect, linePaint);
      }
    }
  }

  void _paintBlob(Canvas canvas, Size size, MoodSplashBlob blob, List<Color> colors) {
    final blobColor = colors[blob.colorIndex % colors.length];
    final center = Offset(blob.normalizedX * size.width, blob.normalizedY * size.height);
    final r = blob.radius * math.min(size.width, size.height);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(blob.rotation);

    switch (blob.shapeStyle) {
      case 1: // Angled Ellipse
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              blobColor.withValues(alpha: blob.opacity),
              blobColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(-r * 1.4, -r * 0.8, r * 2.8, r * 1.6));
        canvas.drawOval(Rect.fromLTWH(-r * 1.4, -r * 0.8, r * 2.8, r * 1.6), paint);
        break;

      case 2: // Starburst / Glow
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: blob.opacity),
              blobColor.withValues(alpha: blob.opacity * 0.7),
              blobColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.3));
        canvas.drawCircle(Offset.zero, r * 1.3, paint);
        break;

      case 3: // Ribbon / Curved Swirl
        final path = Path()
          ..moveTo(-r, -r * 0.5)
          ..quadraticBezierTo(0, r, r, -r * 0.5)
          ..quadraticBezierTo(0, 0, -r, -r * 0.5);
        final paint = Paint()
          ..color = blobColor.withValues(alpha: blob.opacity * 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, paint);
        break;

      case 4: // Stained glass cell shard
        final path = Path();
        final points = 5;
        final rand = math.Random((blob.normalizedX * 1000).toInt());
        for (int i = 0; i < points; i++) {
          final angle = (i * 2 * math.pi / points);
          final dist = r * (0.7 + rand.nextDouble() * 0.5);
          final px = dist * math.cos(angle);
          final py = dist * math.sin(angle);
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        final paint = Paint()
          ..color = blobColor.withValues(alpha: blob.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, paint);
        final borderPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(path, borderPaint);
        break;

      case 0:
      default: // Soft Radial Orb
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              blobColor.withValues(alpha: blob.opacity),
              blobColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, paint);
        break;
    }

    canvas.restore();
  }

  void _paintTextureOverlay(Canvas canvas, Size size, String overlayType) {
    if (overlayType == 'none') return;

    if (overlayType == 'glass') {
      // Frosted specular sheen line across top corner
      final glassPath = Path()
        ..moveTo(0, size.height * 0.25)
        ..lineTo(size.width * 0.6, 0)
        ..lineTo(size.width * 0.75, 0)
        ..lineTo(0, size.height * 0.35)
        ..close();

      final glassPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0.05),
          ],
        ).createShader(glassPath.getBounds());
      canvas.drawPath(glassPath, glassPaint);

    } else if (overlayType == 'sparkles') {
      // Golden / Diamond Sparkles
      final sparklePaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.75);
      final rand = math.Random(77);
      for (int i = 0; i < 14; i++) {
        final cx = rand.nextDouble() * size.width;
        final cy = rand.nextDouble() * size.height;
        final sz = 2.0 + rand.nextDouble() * 4.0;

        final path = Path()
          ..moveTo(cx, cy - sz)
          ..lineTo(cx + sz * 0.3, cy - sz * 0.3)
          ..lineTo(cx + sz, cy)
          ..lineTo(cx + sz * 0.3, cy + sz * 0.3)
          ..lineTo(cx, cy + sz)
          ..lineTo(cx - sz * 0.3, cy + sz * 0.3)
          ..lineTo(cx - sz, cy)
          ..lineTo(cx - sz * 0.3, cy - sz * 0.3)
          ..close();

        canvas.drawPath(path, sparklePaint);
      }

    } else if (overlayType == 'aurora') {
      // Vignette glow frame around tile
      final rect = Offset.zero & size;
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.75,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
          ],
          stops: const [0.6, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, vignettePaint);
    }
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF7C3AED);
    }
  }

  @override
  bool shouldRepaint(covariant AbstractMoodTilePainter oldDelegate) {
    return oldDelegate.tileData != tileData;
  }
}

/// Reusable Widget for rendering abstract mood artwork
class AbstractMoodTileWidget extends StatelessWidget {
  final AbstractMoodTileData data;
  final double width;
  final double height;
  final double borderRadius;
  final Widget? childOverlay;

  const AbstractMoodTileWidget({
    super.key,
    required this.data,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 20.0,
    this.childOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AbstractMoodTilePainter(tileData: data),
              ),
            ),
            if (childOverlay != null) Positioned.fill(child: childOverlay!),
          ],
        ),
      ),
    );
  }
}
