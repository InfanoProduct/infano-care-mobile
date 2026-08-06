import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/core/services/api_service.dart';
import 'package:infano_care_mobile/features/journal/application/journal_cubit.dart';
import 'package:infano_care_mobile/features/journal/application/journal_state.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/models/video_diary_data.dart';
import 'package:infano_care_mobile/features/journal/data/repositories/journal_repository.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/abstract_mood_tile_painter.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/app_video_player.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/share_to_community_sheet.dart';

class JournalEntryDetailScreen extends StatefulWidget {
  final String id;

  const JournalEntryDetailScreen({super.key, required this.id});

  @override
  State<JournalEntryDetailScreen> createState() => _JournalEntryDetailScreenState();
}

class _JournalEntryDetailScreenState extends State<JournalEntryDetailScreen> {
  late Future<JournalEntry> _entryFuture;

  @override
  void initState() {
    super.initState();
    _entryFuture = _resolveEntry();
  }

  Future<JournalEntry> _resolveEntry() async {
    final state = context.read<JournalCubit>().state;
    if (state is JournalLoaded) {
      final found = state.entries.where((e) => e.id == widget.id).firstOrNull;
      if (found != null) return found;
    }
    final repo = JournalRepository(ApiService.instance.dio);
    return repo.getEntry(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF),
      body: FutureBuilder<JournalEntry>(
        future: _entryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildError(context);
          }
          return _buildDetail(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, JournalEntry entry) {
    final gradient = entry.mode.gradient;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(entry.mode.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(entry.mode.displayName, style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        const Spacer(),
                        if (entry.moodTag != null)
                          Text(entry.moodTag!, style: const TextStyle(fontSize: 24)),
                        if (entry.isSealedTimeCapsule)
                          Padding(padding: const EdgeInsets.only(left: 8), child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20)),
                      ]),
                      const SizedBox(height: 8),
                      if (entry.title != null && entry.title!.isNotEmpty)
                        Text(entry.title!, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
                      Text(DateFormat('EEEE, MMMM d, y').format(entry.createdAt),
                        style: GoogleFonts.nunito(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ShareToCommunitySheet(entry: entry),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE9D5FF), width: 1),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Color(0xFF7C3AED),
                  size: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => context.push('/journal/compose', extra: {'entry': entry}),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: () => _confirmDelete(context, entry),
            ),
          ],
          backgroundColor: gradient.first,
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildContentBlock(entry),
              const SizedBox(height: 20),
              if (entry.isSealedTimeCapsule && entry.capsuleRevealDate != null)
                _buildCapsuleInfo(entry.capsuleRevealDate!),
              if (entry.prompt != null && entry.mode != JournalMode.guidedPrompt) _buildPromptInfo(entry.prompt!),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildContentBlock(JournalEntry entry) {
    switch (entry.mode) {
      case JournalMode.freeWrite:
        return _TextBlock(text: entry.content['text'] as String? ?? '');
      case JournalMode.guidedPrompt:
        final promptText = entry.content['promptText'] as String? ?? entry.prompt?.text ?? 'Daily Guided Reflection';
        final answer = entry.content['answer'] as String? ?? entry.content['text'] as String? ?? '';
        final selectedOption = entry.content['selectedOption'] as String?;
        final rawOpts = entry.content['selectedOptions'] as List?;
        final selectedOptions = rawOpts != null ? List<String>.from(rawOpts) : <String>[];
        return _GuidedPromptBlock(
          promptText: promptText,
          answer: answer,
          selectedOption: selectedOption,
          selectedOptions: selectedOptions,
        );
      case JournalMode.letterMode:
        return _LetterBlock(to: entry.content['to'] as String? ?? 'Someone', body: entry.content['body'] as String? ?? '');
      case JournalMode.moodColor:
        final tileData = AbstractMoodTileData.fromJson(entry.content);
        return _ColorBlock(tileData: tileData, moodTag: entry.moodTag);
      case JournalMode.voiceNote:
        final filePath = entry.content['filePath'] as String?;
        final duration = entry.content['durationSeconds'] as int? ?? 15;
        return _VoiceBlock(filePath: filePath, duration: duration);
      case JournalMode.doodle:
        final strokesRaw = entry.content['strokes'] as List?;
        final strokes = strokesRaw != null
            ? strokesRaw.map((s) => DoodleStroke.fromJson(s as Map<String, dynamic>)).toList()
            : <DoodleStroke>[];
        return _DoodleBlock(strokes: strokes);
      case JournalMode.photoBoard:
        final caption = entry.content['caption'] as String? ?? '';
        final count = entry.content['photoCount'] as int? ?? 0;
        final photos = List<String>.from(entry.content['photos'] as List? ?? []);
        return _PhotoBlock(photos: photos, count: count, caption: caption);
      case JournalMode.videoDiary:
        return _VideoDiaryDetailBlock(entry: entry);
      case JournalMode.blackoutPoetry:
        final words = List<String>.from(entry.content['selectedWords'] as List? ?? []);
        final poem = entry.content['poem'] as String?;
        return _BlackoutPoetryBlock(words: words, poem: poem);
    }
  }

  Widget _buildCapsuleInfo(DateTime revealDate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.purple.withValues(alpha: 0.2))),
      child: Row(children: [
        const Text('🔮', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text('Sealed until ${DateFormat('MMM d, y').format(revealDate)}',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.purple, fontSize: 13)),
      ]),
    );
  }

  Widget _buildPromptInfo(JournalPrompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text('Prompt: ${prompt.text}', style: GoogleFonts.nunito(color: const Color(0xFF065F46), fontSize: 13))),
      ]),
    );
  }

  Widget _buildError(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: const Center(child: Text('Entry not found')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete entry?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('This entry will be permanently removed from your journal.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<JournalCubit>().deleteEntry(entry.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ─── Content Block Widgets ─────────────────────────────────────────────────────

class _TextBlock extends StatelessWidget {
  final String text;
  const _TextBlock({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)]),
      child: Text(text, style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark, height: 1.7)),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _LetterBlock extends StatelessWidget {
  final String to, body;
  const _LetterBlock({required this.to, required this.body});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFF5F5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dear $to, 💌', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.pink)),
        const SizedBox(height: 12),
        Text(body, style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark, height: 1.7)),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }
}



class _ColorBlock extends StatelessWidget {
  final AbstractMoodTileData tileData;
  final String? moodTag;
  const _ColorBlock({required this.tileData, this.moodTag});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showExpandedArtwork(context),
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AbstractMoodTileWidget(
              data: tileData,
              width: double.infinity,
              height: 260,
              borderRadius: 24,
              childOverlay: Stack(
                children: [
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (moodTag != null) ...[
                            Text(moodTag!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tileData.label ?? 'Mood Color Splash',
                            style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fullscreen, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to expand',
                            style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (tileData.caption != null && tileData.caption!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reflection',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.purple),
                ),
                const SizedBox(height: 4),
                Text(
                  tileData.caption!,
                  style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showExpandedArtwork(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 450),
              child: AbstractMoodTileWidget(
                data: tileData,
                width: double.infinity,
                height: 400,
                borderRadius: 28,
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}



class _VoiceBlock extends StatefulWidget {
  final String? filePath;
  final int duration;

  const _VoiceBlock({this.filePath, required this.duration});

  @override
  State<_VoiceBlock> createState() => _VoiceBlockState();
}

class _VoiceBlockState extends State<_VoiceBlock> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.duration);

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _duration = d);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (widget.filePath != null && File(widget.filePath!).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(widget.filePath!));
      } else {
        await _audioPlayer.play(AssetSource('audio/journal_demo.mp3')).catchError((_) {});
      }
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Voice Note 🎤',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('${_format(_position)} / ${_format(_duration)}',
                      style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AnimatedSoundWave(isPlaying: _isPlaying),
        ],
      ),
    );
  }
}

class _AnimatedSoundWave extends StatelessWidget {
  final bool isPlaying;

  const _AnimatedSoundWave({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    final heights = [0.4, 0.8, 0.5, 1.0, 0.6, 0.9, 0.3, 0.7, 0.5, 0.8, 0.4, 0.6, 0.9, 0.5, 0.7, 0.3, 0.8, 0.6];
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(heights.length, (i) {
          final h = heights[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: Duration(milliseconds: isPlaying ? 250 + (i * 60) % 300 : 300),
              width: 4,
              height: isPlaying ? 32 * h : 8,
              decoration: BoxDecoration(
                color: isPlaying ? const Color(0xFFEF4444) : const Color(0xFFFDA4AF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DoodleBlock extends StatelessWidget {
  final List<DoodleStroke> strokes;
  const _DoodleBlock({required this.strokes});

  @override
  Widget build(BuildContext context) {
    if (strokes.isEmpty) {
      return const _DoodlePlaceholder(mode: JournalMode.doodle);
    }
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CustomPaint(
          painter: DoodlePainter(strokes: strokes),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DoodlePlaceholder extends StatelessWidget {
  final JournalMode mode;
  const _DoodlePlaceholder({required this.mode});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: mode.gradient.map((c) => c.withValues(alpha: 0.08)).toList()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mode.gradient.first.withValues(alpha: 0.3)),
      ),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(mode.emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text(mode.displayName, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: mode.gradient.first, fontSize: 16)),
      ])),
    );
  }
}

class _PhotoBlock extends StatelessWidget {
  final List<String> photos;
  final int count;
  final String caption;

  const _PhotoBlock({required this.photos, required this.count, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📸', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('${photos.isNotEmpty ? photos.length : count} Photo${count != 1 ? 's' : ''}',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          if (photos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: photos.length,
              itemBuilder: (ctx, i) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImageWidget(photos[i]),
                  ),
                );
              },
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 36, color: Color(0xFF0D9488)),
                    const SizedBox(height: 6),
                    Text('$count photos attached', style: GoogleFonts.nunito(color: const Color(0xFF065F46), fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(caption, style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark, height: 1.4)),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildImageWidget(String src) {
    try {
      if (src.startsWith('data:image')) {
        final base64String = src.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } else if (src.startsWith('http')) {
        return Image.network(src, fit: BoxFit.cover);
      } else {
        final file = File(src);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      }
    } catch (e) {
      debugPrint("[IMAGE_RENDER_ERROR] $e");
    }
    return Container(
      color: const Color(0xFFD1FAE5),
      child: const Center(
        child: Icon(Icons.image_rounded, color: Color(0xFF059669), size: 36),
      ),
    );
  }
}

class _VideoDiaryDetailBlock extends StatelessWidget {
  final JournalEntry entry;
  const _VideoDiaryDetailBlock({required this.entry});

  @override
  Widget build(BuildContext context) {
    final videoData = VideoDiaryData.fromJson(entry.content);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 9 / 14,
          child: Stack(
            children: [
              // Background Container or Live Video Player
              Positioned.fill(
                child: videoData.videoPath != null
                    ? AppVideoPlayer(
                        videoPath: videoData.videoPath!,
                        autoPlay: true,
                        loop: true,
                        showControls: false,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1F2937), Color(0xFF111827)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.movie_filter_rounded, color: Colors.white70, size: 52),
                              const SizedBox(height: 12),
                              Text(
                                'Video Story Memory ✨',
                                style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Filter Sheen Overlay Tint
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: videoData.filterOverlayGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Top Segment Bar & Info Badges
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            videoData.vibeTag ?? 'Video Story',
                            style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            videoData.filterName,
                            style: GoogleFonts.nunito(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Floating Reaction Stickers Column
              if (videoData.stickers.isNotEmpty)
                Positioned(
                  top: 75,
                  right: 16,
                  child: Column(
                    children: videoData.stickers.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 24)),
                    )).toList(),
                  ),
                ),

              // Center Pulsating Play Button (Tap to View Snapchat Story Modal)
              Center(
                child: GestureDetector(
                  onTap: () => _showSnapchatStoryViewer(context, videoData, entry),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF7C3AED)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 900.ms,
                  ),
                ),
              ),

              // Bottom Caption Ribbon Overlay (High Contrast & Bold)
              if (videoData.caption != null && videoData.caption!.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      videoData.caption!,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showSnapchatStoryViewer(BuildContext context, VideoDiaryData data, JournalEntry entry) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Story Video Aspect Player Frame
                Positioned.fill(
                  child: data.videoPath != null
                      ? AppVideoPlayer(
                          videoPath: data.videoPath!,
                          autoPlay: true,
                          loop: true,
                          showControls: true,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: data.filterOverlayGradient,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_rounded, color: Colors.white, size: 72)
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms),
                                const SizedBox(height: 16),
                                Text(
                                  data.vibeTag ?? 'Story Memory ✨',
                                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data.filterName,
                                  style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Active Filter Sheen Overlay
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: data.filterOverlayGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Top Segment Bar & Header Controls
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Text('🎬', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMM d, yyyy').format(entry.createdAt),
                                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right Side Floating Reaction Stamps
                if (data.stickers.isNotEmpty)
                  Positioned(
                    right: 20,
                    top: 120,
                    child: Column(
                      children: data.stickers.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 28)),
                        ),
                      )).toList(),
                    ),
                  ),

                // Bottom Floating Banner Caption (High Contrast)
                if (data.caption != null && data.caption!.isNotEmpty)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        data.caption!,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlackoutPoetryBlock extends StatelessWidget {
  final List<String> words;
  final String? poem;
  const _BlackoutPoetryBlock({required this.words, this.poem});

  @override
  Widget build(BuildContext context) {
    final poemText = (poem != null && poem!.isNotEmpty)
        ? poem!
        : words.join('  ·  ');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('📜', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('For You', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 18),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((w) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(w, style: GoogleFonts.nunito(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            );
          }).toList(),
        ),
        if (poemText.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
            ),
            child: Text(
              '“ $poemText ”',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.6,
              ),
            ),
          ),
        ],
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _GuidedPromptBlock extends StatelessWidget {
  final String promptText;
  final String answer;
  final String? selectedOption;
  final List<String> selectedOptions;

  const _GuidedPromptBlock({
    required this.promptText,
    required this.answer,
    this.selectedOption,
    this.selectedOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOptions = selectedOptions.isNotEmpty
        ? selectedOptions
        : (selectedOption != null && selectedOption!.isNotEmpty ? [selectedOption!] : <String>[]);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('Daily Guided Prompt', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              promptText,
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (effectiveOptions.isNotEmpty) ...[
              Text(
                'Selected Options:',
                style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: effectiveOptions.map((opt) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC084FC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, color: AppColors.purple, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          opt,
                          style: GoogleFonts.nunito(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Your Answer:',
              style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              answer,
              style: GoogleFonts.nunito(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w600, height: 1.6),
            ),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
