import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:infano_care_mobile/features/journal/application/journal_cubit.dart';
import 'package:infano_care_mobile/features/journal/application/journal_state.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/models/video_diary_data.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/abstract_mood_tile_painter.dart';
import 'package:infano_care_mobile/features/journal/screens/widgets/app_video_player.dart';

// ─── Mood Colors ──────────────────────────────────────────────────────────────
const _moodPalettes = [
  {'label': 'Sunset', 'colors': ['#FF6B6B', '#FFA500']},
  {'label': 'Ocean', 'colors': ['#4FC3F7', '#0288D1']},
  {'label': 'Lavender', 'colors': ['#CE93D8', '#7B1FA2']},
  {'label': 'Mint', 'colors': ['#80CBC4', '#00796B']},
  {'label': 'Rose', 'colors': ['#F48FB1', '#C2185B']},
  {'label': 'Golden', 'colors': ['#FFCA28', '#F57F17']},
  {'label': 'Storm', 'colors': ['#607D8B', '#263238']},
  {'label': 'Cherry', 'colors': ['#EF9A9A', '#B71C1C']},
  {'label': 'Forest', 'colors': ['#A5D6A7', '#2E7D32']},
  {'label': 'Night', 'colors': ['#7986CB', '#1A237E']},
  {'label': 'Peach', 'colors': ['#FFAB91', '#BF360C']},
  {'label': 'Sky', 'colors': ['#B3E5FC', '#01579B']},
];

// ─── Blackout Poetry Words ────────────────────────────────────────────────────
const _blackoutWords = [
  'worry', 'bright', 'tired', 'hopeful', 'stuck', 'brave', 'quiet', 'ready',
  'wonder', 'rise', 'gentle', 'fierce', 'heavy', 'light', 'afraid', 'strong',
  'searching', 'found', 'lonely', 'connected', 'lost', 'here', 'seen', 'heard',
  'broken', 'whole', 'dreaming', 'awake', 'soft', 'loud',
];

class JournalComposerScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const JournalComposerScreen({super.key, this.extra});

  @override
  State<JournalComposerScreen> createState() => _JournalComposerScreenState();
}

class _JournalComposerScreenState extends State<JournalComposerScreen>
    with SingleTickerProviderStateMixin {
  late JournalMode _mode;
  String? _promptId;
  String? _promptText;
  String? _moodTag;
  String? _moodColor;
  bool _isSealedTimeCapsule = false;
  DateTime? _capsuleRevealDate;
  Timer? _autosaveTimer;
  bool _isSaving = false;

  // Free write / guided / letter
  final _textController = TextEditingController();
  final _titleController = TextEditingController();

  // Letter mode
  final _letterToController = TextEditingController();

  // Mood color studio state
  int _selectedPaletteIndex = 0;
  String _patternStyle = 'fluid';
  String _textureOverlay = 'glass';
  List<MoodSplashBlob> _activeBlobs = [];
  int _activeColorIndex = 0;
  final Map<String, String> _customColorMeanings = {};
  final TextEditingController _moodNoteController = TextEditingController();

  // Doodle state
  Color _activeDoodleColor = const Color(0xFF7C3AED);
  double _activeDoodleWidth = 4.0;
  bool _isDoodleEraser = false;
  final List<DoodleStroke> _doodleStrokes = [];
  DoodleStroke? _currentDoodleStroke;

  // Voice note
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _recordedPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _isPlayingBack = false;

  // Photo board
  final _picker = ImagePicker();
  final List<File> _selectedPhotos = [];
  final List<String> _selectedPhotoData = [];

  // Video diary
  String? _videoPath;
  String? _videoDataUri;
  String _videoFilterStyle = 'golden_glow';
  String _videoVibeTag = 'Daily Vibe ✨';
  final List<String> _videoStickers = ['🔥', '✨'];

  @override
  void initState() {
    super.initState();
    final extra = widget.extra ?? {};
    final existingEntry = extra['entry'] as JournalEntry?;

    if (existingEntry != null) {
      _existingEntryId = existingEntry.id;
      _mode = existingEntry.mode;
      _promptId = existingEntry.promptId;
      _moodTag = existingEntry.moodTag;
      _moodColor = existingEntry.moodColor;
      if (existingEntry.title != null) {
        _titleController.text = existingEntry.title!;
      }
      _isSealedTimeCapsule = existingEntry.isSealedTimeCapsule;

      final content = existingEntry.content;
      if (_mode == JournalMode.guidedPrompt) {
        _promptId = content['promptId'] as String? ?? existingEntry.promptId;
        _promptText = content['promptText'] as String? ?? existingEntry.prompt?.text;
        if (existingEntry.prompt != null && existingEntry.prompt!.options.isNotEmpty) {
          _dynamicPromptOptions = existingEntry.prompt!.options;
        }
        final ans = content['answer'] as String? ?? content['text'] as String? ?? '';
        _textController.text = ans;
        final rawOpts = content['selectedOptions'] as List?;
        if (rawOpts != null) {
          _selectedPromptOptions.addAll(rawOpts.cast<String>());
        } else {
          final selectedOpt = content['selectedOption'] as String?;
          if (selectedOpt != null && selectedOpt.isNotEmpty) {
            _selectedPromptOptions.add(selectedOpt);
          }
        }
      } else if (_mode == JournalMode.freeWrite) {
        _textController.text = content['text'] as String? ?? '';
      } else if (_mode == JournalMode.letterMode) {
        _letterToController.text = content['to'] as String? ?? '';
        _textController.text = content['body'] as String? ?? '';
      } else if (_mode == JournalMode.photoBoard) {
        final photos = List<String>.from(content['photos'] as List? ?? []);
        _selectedPhotoData.addAll(photos);
        _textController.text = content['caption'] as String? ?? '';
      } else if (_mode == JournalMode.blackoutPoetry) {
        final words = List<String>.from(content['selectedWords'] as List? ?? []);
        _selectedBlackoutWords.addAll(words);
      } else if (_mode == JournalMode.doodle) {
        final strokesRaw = content['strokes'] as List?;
        if (strokesRaw != null) {
          _doodleStrokes.addAll(strokesRaw.map((s) => DoodleStroke.fromJson(s as Map<String, dynamic>)));
        }
      } else if (_mode == JournalMode.moodColor) {
        _patternStyle = content['patternStyle'] as String? ?? 'fluid';
        _textureOverlay = content['textureOverlay'] as String? ?? 'glass';
        final rawBlobs = content['blobs'] as List?;
        if (rawBlobs != null && rawBlobs.isNotEmpty) {
          _activeBlobs = rawBlobs.map((b) => MoodSplashBlob.fromJson(b as Map<String, dynamic>)).toList();
        }
        final labelStr = content['label'] as String?;
        if (labelStr != null) {
          final foundIdx = _moodPalettes.indexWhere((p) => p['label'] == labelStr);
          if (foundIdx != -1) _selectedPaletteIndex = foundIdx;
        }
        final note = content['caption'] as String? ?? content['note'] as String? ?? '';
        _moodNoteController.text = note;
      }
    } else {
      _mode = extra['mode'] != null
          ? JournalMode.fromApi(extra['mode'] as String)
          : JournalMode.freeWrite;
      _promptId = extra['promptId'] as String?;
      _promptText = extra['promptText'] as String?;
      final pOpts = extra['promptOptions'] as List?;
      if (pOpts != null && pOpts.isNotEmpty) {
        _dynamicPromptOptions = List<String>.from(pOpts);
      }
      _moodTag = extra['moodTag'] as String?;
      _moodColor = extra['moodColor'] as String?;
    }

    _textController.addListener(_triggerAutosave);
  }

  String? _existingEntryId;

  bool _hasUserContent() {
    switch (_mode) {
      case JournalMode.freeWrite:
        return _textController.text.trim().isNotEmpty;
      case JournalMode.guidedPrompt:
        return _textController.text.trim().isNotEmpty || _selectedPromptOptions.isNotEmpty;
      case JournalMode.letterMode:
        return _textController.text.trim().isNotEmpty;
      case JournalMode.voiceNote:
        return _recordedPath != null || _isRecording;
      case JournalMode.doodle:
      case JournalMode.moodColor:
        return true;
      case JournalMode.photoBoard:
        return _selectedPhotos.isNotEmpty;
      case JournalMode.videoDiary:
        return _videoPath != null;
      case JournalMode.blackoutPoetry:
        return _selectedBlackoutWords.isNotEmpty;
    }
  }

  void _triggerAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isSaving) _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (!_hasUserContent()) return;
    await _save(silent: true);
  }

  Map<String, dynamic> _getContent() {
    switch (_mode) {
      case JournalMode.freeWrite:
        final text = _textController.text.trim();
        return {'text': text.isEmpty ? 'Journal entry' : text};
      case JournalMode.guidedPrompt:
        final answer = _textController.text.trim();
        final selectedList = _selectedPromptOptions.toList();
        final legacyOption = selectedList.isNotEmpty ? selectedList.join(', ') : null;
        final finalAnswer = answer.isNotEmpty
            ? answer
            : (selectedList.isNotEmpty ? selectedList.join('\n') : 'Reflected on today’s prompt');
        return {
          'promptId': _promptId,
          'promptText': _promptText ?? "Daily Prompt Reflection",
          'selectedOption': legacyOption,
          'selectedOptions': selectedList,
          'answer': finalAnswer,
          'text': finalAnswer,
        };
      case JournalMode.letterMode:
        final body = _textController.text.trim();
        return {'to': _letterToController.text.trim(), 'body': body.isEmpty ? 'Notes...' : body};
      case JournalMode.moodColor:
        final palette = _moodPalettes[_selectedPaletteIndex];
        final colors = List<String>.from(palette['colors'] as List? ?? ['#FF6B6B', '#FFA500']);
        if (_activeBlobs.isEmpty) {
          _activeBlobs = AbstractMoodTileData.generateSeedBlobs(colors.length, patternStyle: _patternStyle);
        }
        final tileData = AbstractMoodTileData(
          colors: colors,
          patternStyle: _patternStyle,
          textureOverlay: _textureOverlay,
          blobs: _activeBlobs,
          caption: _moodNoteController.text.trim().isEmpty ? null : _moodNoteController.text.trim(),
          label: palette['label'] as String?,
          colorMeanings: _customColorMeanings,
        );
        final map = tileData.toJson();
        map['label'] = palette['label'];
        return map;
      case JournalMode.voiceNote:
        final path = _recordedPath ?? 'voice_note_recorded.m4a';
        final durationSecs = _recordingDuration.inSeconds > 0 ? _recordingDuration.inSeconds : 15;
        return {'filePath': path, 'durationSeconds': durationSecs};
      case JournalMode.doodle:
        return {
          'strokes': _doodleStrokes.map((s) => s.toJson()).toList(),
          'strokeCount': _doodleStrokes.length,
        };
      case JournalMode.photoBoard:
        final photoPayload = _selectedPhotoData.isNotEmpty
            ? _selectedPhotoData
            : _selectedPhotos.map((f) => f.path).toList();
        return {
          'photoCount': photoPayload.length,
          'photos': photoPayload,
          'caption': _textController.text.trim(),
        };
      case JournalMode.videoDiary:
        final vpath = _videoDataUri ?? _videoPath ?? 'video_diary_recorded.mp4';
        final payload = VideoDiaryData(
          videoPath: vpath,
          durationSeconds: 30,
          filterStyle: _videoFilterStyle,
          caption: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
          vibeTag: _videoVibeTag,
          stickers: _videoStickers,
        );
        return payload.toJson();
      case JournalMode.blackoutPoetry:
        final selectedList = _selectedBlackoutWords.toList();
        final poemText = _poemTextController.text.trim().isNotEmpty
            ? _poemTextController.text.trim()
            : PoetryGenerator.generate(selectedList, styleIndex: _poemStyleIndex);
        return {
          'selectedWords': selectedList.isEmpty ? ['quiet', 'brave'] : selectedList,
          'poem': poemText,
        };
    }
  }

  final Set<String> _selectedBlackoutWords = {};

  Future<void> _save({bool silent = false}) async {
    if (_isSaving) return;
    if (!_hasUserContent() && !silent) return;

    if (_mode == JournalMode.voiceNote && _isRecording) {
      await _stopRecording();
    }

    final content = _getContent();
    print("[JOURNAL_SAVE_DEBUG] Saving entry mode=${_mode.apiValue}, id=$_existingEntryId, content=$content");

    setState(() => _isSaving = true);
    try {
      final entry = await context.read<JournalCubit>().saveEntry(
        id: _existingEntryId,
        mode: _mode.apiValue,
        content: content,
        promptId: _promptId,
        moodTag: _moodTag,
        moodColor: _moodColor,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        isSealedTimeCapsule: _isSealedTimeCapsule,
        capsuleRevealDate: _capsuleRevealDate?.toIso8601String(),
      );
      if (entry != null) {
        _existingEntryId = entry.id;
      }
      print("[JOURNAL_SAVE_DEBUG] Save result: ${entry?.id}");
      if (mounted && !silent) {
        _showSuccessAnimation();
      }
    } catch (e, s) {
      print("[JOURNAL_SAVE_ERROR] Save failed: $e\n$s");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('✨', style: TextStyle(fontSize: 72)).animate().scale(begin: const Offset(0.3, 0.3), duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 12),
          Text('Entry saved!', style: GoogleFonts.nunito(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
        context.go('/journal');
      }
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _recordingTimer?.cancel();
    _textController.dispose();
    _titleController.dispose();
    _letterToController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalCubit, JournalState>(
      listener: (context, state) {
        if (state is JournalError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF4FF),
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final gradient = _mode.gradient;
    return AppBar(
      backgroundColor: gradient.first,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(children: [
        Text(_mode.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(_mode.displayName, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
      ]),
      actions: [
        if (_isSaving)
          const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
        else
          TextButton.icon(
            onPressed: () => _save(),
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: Text('Save', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }

  Widget _buildBody() {
    final isDrawingMode = _mode == JournalMode.doodle;

    return SingleChildScrollView(
      physics: isDrawingMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_promptText != null && _mode != JournalMode.guidedPrompt && _mode != JournalMode.doodle)
            _buildPromptCard(),
          _buildTitleField(),
          const SizedBox(height: 12),
          _buildModeComposer(),
          if (!isDrawingMode) ...[
            const SizedBox(height: 20),
            _buildMoodTagRow(),
            const SizedBox(height: 12),
            _buildCapsuleToggle(),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _mode.gradient),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(_promptText!, style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3))),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: 'Title (optional)',
        hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildModeComposer() {
    switch (_mode) {
      case JournalMode.freeWrite:
        return _buildTextComposer('Start writing freely...');
      case JournalMode.guidedPrompt:
        return _buildGuidedPromptComposer();
      case JournalMode.letterMode:
        return _buildLetterComposer();
      case JournalMode.moodColor:
        return _buildMoodColorComposer();
      case JournalMode.doodle:
        return _buildDoodleComposer();
      case JournalMode.voiceNote:
        return _buildVoiceNoteComposer();
      case JournalMode.photoBoard:
        return _buildPhotoBoardComposer();
      case JournalMode.videoDiary:
        return _buildVideoDiaryComposer();
      case JournalMode.blackoutPoetry:
        return _buildBlackoutPoetryComposer();
    }
  }

  // ── Guided Prompt ──────────────────────────────────────────────────────────
  final Set<String> _selectedPromptOptions = {};
  List<String>? _dynamicPromptOptions;
  final List<String> _defaultPromptOptions = [
    '🌟 Peaceful & balanced',
    '⚡ Energized & productive',
    '🧘 Calmer than yesterday',
    '😴 A bit tired / overwhelmed',
    '🌧️ Needing some quiet rest',
    '✨ Grateful & hopeful',
  ];

  List<String> get _activePromptOptions {
    if (_dynamicPromptOptions != null && _dynamicPromptOptions!.isNotEmpty) {
      return _dynamicPromptOptions!;
    }
    return _defaultPromptOptions;
  }

  void _updateReflectionText() {
    final activeOpts = _activePromptOptions;
    final currentLines = _textController.text.split('\n');
    final customLines = currentLines
        .where((line) => line.trim().isNotEmpty && !activeOpts.contains(line.trim()))
        .toList();

    final newLines = [..._selectedPromptOptions, ...customLines];
    _textController.text = newLines.join('\n');
  }

  Widget _buildGuidedPromptComposer() {
    final promptTitle = _promptText ?? "How are you feeling about your day so far?";
    final options = _activePromptOptions;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Guided Prompt Question Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
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
                Text('Guided Question', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            promptTitle,
            style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.4),
          ),
        ]),
      ),

      const SizedBox(height: 24),
      Text('Select options that apply to you:',
        style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),

      // Multiple selection option pills
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: List.generate(options.length, (i) {
          final opt = options[i];
          final isSelected = _selectedPromptOptions.contains(opt);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedPromptOptions.remove(opt);
                } else {
                  _selectedPromptOptions.add(opt);
                }
                _updateReflectionText();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.purple : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.purple : Colors.purple.shade100,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.purple.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    opt,
                    style: GoogleFonts.nunito(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),

      const SizedBox(height: 24),
      Text('Add additional notes or thoughts (optional)',
        style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),

      // Reflection text input box
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
        ),
        child: TextField(
          controller: _textController,
          maxLines: null,
          minLines: 4,
          style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark, height: 1.6),
          decoration: InputDecoration(
            hintText: 'Type your reflection or answer here…',
            hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    ]);
  }

  // ── Free Write / Guided Prompt ──────────────────────────────────────────────
  Widget _buildTextComposer(String hint) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
      ),
      child: TextField(
        controller: _textController,
        maxLines: null,
        minLines: 8,
        style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark, height: 1.6),
        decoration: InputDecoration(
          hintText: _promptText ?? hint,
          hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ── Letter Mode ─────────────────────────────────────────────────────────────
  Widget _buildLetterComposer() {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Dear', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _letterToController,
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.pink),
            decoration: InputDecoration(
              hintText: 'Future Me / Mum / Anyone…',
              hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          )),
          const Text('💌', style: TextStyle(fontSize: 20)),
        ]),
        const Divider(height: 20),
        TextField(
          controller: _textController,
          maxLines: null,
          minLines: 8,
          style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark, height: 1.7),
          decoration: InputDecoration(
            hintText: 'Write from the heart…',
            hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ]),
    );
  }

  // ── Mood Color ──────────────────────────────────────────────────────────────
  // ── Mood Color Abstract Studio ──────────────────────────────────────────────
  Widget _buildMoodColorComposer() {
    final selectedPalette = _moodPalettes[_selectedPaletteIndex];
    final selectedHexes = List<String>.from(selectedPalette['colors'] as List? ?? ['#7C3AED', '#EC4899']);

    final activeHex = selectedHexes[_activeColorIndex % selectedHexes.length];
    final activeUpperHex = activeHex.toUpperCase();
    final currentMeaning = _customColorMeanings[activeHex] ??
        _customColorMeanings[activeUpperHex] ??
        kDefaultColorEmotions[activeUpperHex] ??
        kDefaultColorEmotions[activeHex] ??
        'Mood Feeling';

    if (_activeBlobs.isEmpty) {
      _activeBlobs = AbstractMoodTileData.generateSeedBlobs(selectedHexes.length, patternStyle: _patternStyle);
    }

    final tileData = AbstractMoodTileData(
      colors: selectedHexes,
      patternStyle: _patternStyle,
      textureOverlay: _textureOverlay,
      blobs: _activeBlobs,
      label: selectedPalette['label'] as String?,
      caption: _moodNoteController.text,
    );

    final patternStyles = [
      {'id': 'fluid', 'label': '💧 Liquid', 'icon': Icons.water_drop},
      {'id': 'geometric', 'label': '📐 Glass Shards', 'icon': Icons.category},
      {'id': 'cosmic', 'label': '✨ Cosmic Nebula', 'icon': Icons.auto_awesome},
      {'id': 'marble', 'label': '🌊 Silk Waves', 'icon': Icons.waves},
      {'id': 'stained_glass', 'label': '💎 Stained Glass', 'icon': Icons.grid_view},
    ];

    final textureOptions = [
      {'id': 'glass', 'label': '🧊 Glass Sheen'},
      {'id': 'sparkles', 'label': '✨ Gold Sparkles'},
      {'id': 'aurora', 'label': '🌌 Vignette Glow'},
      {'id': 'none', 'label': '🎨 Clean Finish'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Interactive Abstract Painting Canvas
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth;
            const canvasHeight = 240.0;
            return GestureDetector(
              onTapDown: (details) => _addSplashAt(details.localPosition, canvasWidth, canvasHeight, selectedHexes.length),
              onPanUpdate: (details) => _addSplashAt(details.localPosition, canvasWidth, canvasHeight, selectedHexes.length),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: canvasHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _hexToColor(selectedHexes.first).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AbstractMoodTileWidget(
                      data: tileData,
                      width: double.infinity,
                      height: canvasHeight,
                      borderRadius: 24,
                    ),
                    // Canvas Top Badges
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(_moodTag ?? '🌈', style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '${selectedPalette['label']}',
                              style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Helper Hint
                    Positioned(
                      bottom: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '✨ Tap or drag to splash mood colors',
                          style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        // 2. Interactive Action Toolbar (Re-Paint, Finish, Undo, Clear)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _activeBlobs = AbstractMoodTileData.generateSeedBlobs(
                      selectedHexes.length,
                      patternStyle: _patternStyle,
                    );
                  });
                },
                icon: const Text('🎲', style: TextStyle(fontSize: 16)),
                label: Text('Magic Re-Paint', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (val) => setState(() => _textureOverlay = val),
              itemBuilder: (ctx) => textureOptions.map((t) => PopupMenuItem(
                value: t['id']!,
                child: Text(t['label']!, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              )).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.purple),
                    const SizedBox(width: 4),
                    Text(
                      textureOptions.firstWhere((t) => t['id'] == _textureOverlay)['label']!.split(' ').last,
                      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.purple),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _activeBlobs.isEmpty ? null : () => setState(() => _activeBlobs.removeLast()),
              icon: const Icon(Icons.undo, size: 20),
              tooltip: 'Undo Splash',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.2)),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _activeBlobs.clear()),
              icon: const Icon(Icons.refresh, size: 20, color: AppColors.error),
              tooltip: 'Clear Splashes',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 3. Pattern Style Tabs
        Text('Abstract Style', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: patternStyles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final st = patternStyles[i];
              final isSel = _patternStyle == st['id'];
              return ChoiceChip(
                label: Text(st['label'] as String),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _patternStyle = st['id'] as String;
                      _activeBlobs = AbstractMoodTileData.generateSeedBlobs(selectedHexes.length, patternStyle: _patternStyle);
                    });
                  }
                },
                selectedColor: AppColors.purple.withValues(alpha: 0.15),
                backgroundColor: Colors.white,
                side: BorderSide(color: isSel ? AppColors.purple : Colors.grey.shade300, width: isSel ? 1.5 : 1),
                labelStyle: GoogleFonts.nunito(
                  color: isSel ? AppColors.purple : AppColors.textMedium,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // 4. Mood Palette Feeling Selector
        Text('Select Mood Feeling', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_moodPalettes.length, (i) {
            final p = _moodPalettes[i];
            final colors = (p['colors']! as List<String>).map(_hexToColor).toList();
            final isSel = _selectedPaletteIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaletteIndex = i;
                  _activeBlobs = AbstractMoodTileData.generateSeedBlobs(colors.length, patternStyle: _patternStyle);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? Colors.black : Colors.white,
                    width: isSel ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: isSel ? 0.5 : 0.2),
                      blurRadius: isSel ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  p['label'] as String,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 18),

        // 5. Active Color Selection & Emotion Association
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Active Paint Color: ', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMedium)),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(selectedHexes.length, (ci) {
                    final isSel = _activeColorIndex == ci;
                    final c = _hexToColor(selectedHexes[ci]);
                    return GestureDetector(
                      onTap: () => setState(() => _activeColorIndex = ci),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? AppColors.purple : Colors.white, width: isSel ? 3 : 1.5),
                          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4)],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Emotion Tag Chip with Customizer
            GestureDetector(
              onTap: () => _showEditColorMeaningDialog(activeHex, currentMeaning),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _hexToColor(activeHex).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _hexToColor(activeHex).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _hexToColor(activeHex), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Symbolizes: $currentMeaning',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 12, color: AppColors.purple),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 6. Inspiration Prompt & Quick Chips
        Text('What inspired these colors today?', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 6),
        // Quick Inspiration Chips
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              '☕ Quiet tea moment',
              '🌞 Sunny morning',
              '🎯 Achieved a goal',
              '🌊 Finding my calm',
              '🌿 Nature walk reset',
              '💖 Grateful heart',
            ].map((chip) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(chip, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.2)),
                onPressed: () {
                  setState(() {
                    if (_moodNoteController.text.isEmpty) {
                      _moodNoteController.text = chip;
                    } else {
                      _moodNoteController.text = '${_moodNoteController.text} · $chip';
                    }
                  });
                },
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Reflection Text Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: _moodNoteController,
            onChanged: (_) => setState(() {}), // Real-time live artwork canvas update!
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Add your note to display directly on your grid artwork...',
              hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  void _addSplashAt(Offset localPos, double canvasW, double canvasH, int numColors) {
    if (canvasW <= 0 || canvasH <= 0) return;
    final nx = (localPos.dx / canvasW).clamp(0.0, 1.0);
    final ny = (localPos.dy / canvasH).clamp(0.0, 1.0);

    int shapeStyle = 0;
    if (_patternStyle == 'geometric') shapeStyle = (math.Random().nextBool() ? 1 : 3);
    else if (_patternStyle == 'cosmic') shapeStyle = (math.Random().nextDouble() > 0.6 ? 2 : 0);
    else if (_patternStyle == 'marble') shapeStyle = 3;
    else if (_patternStyle == 'stained_glass') shapeStyle = 4;

    final newBlob = MoodSplashBlob(
      normalizedX: nx,
      normalizedY: ny,
      radius: 0.12 + math.Random().nextDouble() * 0.16,
      colorIndex: _activeColorIndex % math.max(1, numColors),
      opacity: 0.55 + math.Random().nextDouble() * 0.35,
      shapeStyle: shapeStyle,
      rotation: math.Random().nextDouble() * math.pi * 2,
    );

    setState(() {
      _activeBlobs.add(newBlob);
    });
  }

  Future<void> _showEditColorMeaningDialog(String hexColor, String currentMeaning) async {
    final controller = TextEditingController(text: currentMeaning);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: _hexToColor(hexColor), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text('Color Meaning', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What feeling or moment does this color represent to you today?',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Morning breeze, Peaceful tea...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Save Meaning'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _customColorMeanings[hexColor] = result;
        _customColorMeanings[hexColor.toUpperCase()] = result;
      });
    }
  }

  // ── Doodle Page ─────────────────────────────────────────────────────────────
  Widget _buildDoodleComposer() {
    final colors = [
      const Color(0xFF7C3AED), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFFF59E0B), // Yellow
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF1E293B), // Dark Slate
    ];

    final widths = [2.5, 5.0, 10.0];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Drawing Canvas Card
      Container(
        height: 380,
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              final localPos = details.localPosition;
              setState(() {
                _currentDoodleStroke = DoodleStroke(
                  points: [localPos],
                  color: _isDoodleEraser ? Colors.white : _activeDoodleColor,
                  strokeWidth: _isDoodleEraser ? 24.0 : _activeDoodleWidth,
                  isEraser: _isDoodleEraser,
                );
              });
            },
            onPanUpdate: (details) {
              final localPos = details.localPosition;
              if (_currentDoodleStroke != null) {
                setState(() {
                  _currentDoodleStroke!.points.add(localPos);
                });
              }
            },
            onPanEnd: (details) {
              if (_currentDoodleStroke != null) {
                setState(() {
                  _doodleStrokes.add(_currentDoodleStroke!);
                  _currentDoodleStroke = null;
                });
              }
            },
            child: CustomPaint(
              painter: DoodlePainter(
                strokes: _doodleStrokes,
                currentStroke: _currentDoodleStroke,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Tool Palette Container
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        ),
        child: Column(children: [
          // Colors Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: colors.map((c) {
              final isSelected = !_isDoodleEraser && _activeDoodleColor == c;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _isDoodleEraser = false;
                    _activeDoodleColor = c;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 34 : 28,
                  height: isSelected ? 34 : 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.4),
                        blurRadius: isSelected ? 8 : 4,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Tools Row: Stroke Widths, Eraser, Undo, Clear
          Row(children: [
            // Size Selection
            Row(
              children: widths.map((w) {
                final isSelected = !_isDoodleEraser && _activeDoodleWidth == w;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDoodleEraser = false;
                      _activeDoodleWidth = w;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.purple : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Container(
                        width: w * 1.6,
                        height: w * 1.6,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),

            // Eraser Toggle
            IconButton(
              tooltip: 'Eraser',
              onPressed: () {
                setState(() {
                  _isDoodleEraser = !_isDoodleEraser;
                });
              },
              icon: Icon(
                Icons.cleaning_services_rounded,
                color: _isDoodleEraser ? AppColors.purple : AppColors.textLight,
                size: 20,
              ),
            ),

            // Undo
            IconButton(
              tooltip: 'Undo',
              onPressed: _doodleStrokes.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _doodleStrokes.removeLast();
                      });
                    },
              icon: Icon(
                Icons.undo_rounded,
                color: _doodleStrokes.isNotEmpty ? AppColors.textDark : Colors.grey.shade300,
                size: 20,
              ),
            ),

            // Clear
            TextButton.icon(
              onPressed: _doodleStrokes.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _doodleStrokes.clear();
                        _currentDoodleStroke = null;
                      });
                    },
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: Text('Clear', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }

  // ── Voice Note ──────────────────────────────────────────────────────────────
  Widget _buildVoiceNoteComposer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFFFF1F2), const Color(0xFFFFF7ED)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDA4AF).withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        if (!_isRecording && _recordedPath == null) ...[
          const Text('🎤', style: TextStyle(fontSize: 60)).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.95, end: 1.05, duration: 1500.ms),
          const SizedBox(height: 16),
          Text('Tap to start recording', style: GoogleFonts.nunito(color: AppColors.textMedium, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Up to 90 seconds', style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 12)),
        ] else if (_isRecording) ...[
          const Text('🔴', style: TextStyle(fontSize: 40)).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms).then().fadeIn(duration: 800.ms),
          const SizedBox(height: 8),
          Text(_formatDuration(_recordingDuration),
            style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444))),
          const SizedBox(height: 8),
          _WaveformAnimated(),
        ] else ...[
          const Text('✅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text('Recording saved (${_formatDuration(_recordingDuration)})',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.success)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: _isPlayingBack ? _stopPlayback : _playback,
              icon: Icon(_isPlayingBack ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(_isPlayingBack ? 'Pause' : 'Play back'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() { _recordedPath = null; _recordingDuration = Duration.zero; }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-record'),
            ),
          ]),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : (_recordedPath == null ? _startRecording : null),
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 36),
          ),
        ),
      ]),
    );
  }

  // ── Photo Board ─────────────────────────────────────────────────────────────
  Widget _buildPhotoBoardComposer() {
    return Column(children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
        itemCount: _selectedPhotos.length < 4 ? _selectedPhotos.length + 1 : 4,
        itemBuilder: (_, i) {
          if (i == _selectedPhotos.length) {
            return GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textLight),
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_selectedPhotos[i], fit: BoxFit.cover),
          );
        },
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _textController,
        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Add a caption…',
          hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    ]);
  }

  // ── Video Diary Studio (GenZ / Snapchat Style) ─────────────────────────────
  Widget _buildVideoDiaryComposer() {
    final activeData = VideoDiaryData(
      videoPath: _videoPath,
      filterStyle: _videoFilterStyle,
      caption: _textController.text.trim(),
      vibeTag: _videoVibeTag,
      stickers: _videoStickers,
    );

    final filters = [
      {'id': 'golden_glow', 'label': '💫 Golden Hour'},
      {'id': 'cyber_neon', 'label': '🔮 Cyber Neon'},
      {'id': 'soft_dream', 'label': '🎀 Soft Dream'},
      {'id': 'vhs_retro', 'label': '📼 90s VHS'},
      {'id': 'clean', 'label': '✨ Clean'},
    ];

    final vibes = [
      'Daily Vibe ✨',
      'Main Character Energy 🔥',
      'Core Memory ☁️',
      'Soft Girl Era 🎀',
      'Unfiltered Thoughts 💬',
    ];

    final stickerStamps = ['🔥', '✨', '💖', '🥹', '💅', '☁️', '👑', '🌈'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 9:16 Vertical Snapchat Story Canvas Container
        Container(
          height: 340,
          width: double.infinity,
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
          child: Stack(
            children: [
              // Background Video Player / Camera Placeholder with Filter Overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Video Icon / Live Video Player Preview
                      Positioned.fill(
                        child: _videoPath != null
                            ? AppVideoPlayer(
                                videoPath: _videoPath!,
                                autoPlay: true,
                                loop: true,
                                showControls: true,
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
                                      Icon(
                                        Icons.videocam_rounded,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Tap record or choose video',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),

                      // Filter Gradient Sheen Tint
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: activeData.filterOverlayGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Header Bar (Progress bar segment + Vibe Tag + Video Review Controls)
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Column(
                  children: [
                    // Segmented Story Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _videoVibeTag,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (_videoPath != null) ...[
                              GestureDetector(
                                onTap: _pickVideo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.purple,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 12),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Re-record',
                                        style: GoogleFonts.nunito(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _videoPath = null;
                                  _videoDataUri = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                activeData.filterName,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Floating Reaction Stickers Overlay
              if (_videoStickers.isNotEmpty)
                Positioned(
                  top: 70,
                  right: 14,
                  child: Column(
                    children: _videoStickers.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 22)),
                      ).animate().scale(duration: 200.ms),
                    )).toList(),
                  ),
                ),

              // Center Record Ring & Pickers (Only visible when NO video is recorded)
              if (_videoPath == null)
                Positioned.fill(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Camera Record Button (Snapchat Pulsating Ring)
                        GestureDetector(
                          onTap: _pickVideo,
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
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Color(0xFFEC4899),
                                  size: 28,
                                ),
                              ),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.06, 1.06),
                            duration: 800.ms,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gallery Pick Button
                        GestureDetector(
                          onTap: _pickVideoFromGallery,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: const Center(
                              child: Icon(Icons.video_library_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom Text Banner Overlay (High Contrast & Clear Visibility)
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  child: TextField(
                    controller: _textController,
                    onChanged: (_) => setState(() {}),
                    cursorColor: const Color(0xFFFBBF24),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.85),
                      hintText: '✍️ Add caption banner here...',
                      hintStyle: GoogleFonts.nunito(
                        color: const Color(0xFFFBBF24),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Filter Selection Chips
        Text(
          'Aesthetic Filters',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: filters.map((f) {
              final isSel = _videoFilterStyle == f['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f['label']!),
                  selected: isSel,
                  selectedColor: AppColors.purple,
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.nunito(
                    color: isSel ? Colors.white : AppColors.textDark,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _videoFilterStyle = f['id']!),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Vibe Tag Chips
        Text(
          'Select Today\'s Vibe Tag',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: vibes.map((v) {
              final isSel = _videoVibeTag == v;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(v),
                  selected: isSel,
                  selectedColor: const Color(0xFFEC4899),
                  backgroundColor: Colors.white,
                  labelStyle: GoogleFonts.nunito(
                    color: isSel ? Colors.white : AppColors.textDark,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _videoVibeTag = v),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Reaction Sticker Stamps
        Text(
          'Snapchat Reaction Stamps',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stickerStamps.map((s) {
            final isSel = _videoStickers.contains(s);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSel) {
                    _videoStickers.remove(s);
                  } else {
                    _videoStickers.add(s);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? AppColors.purple : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(s, style: const TextStyle(fontSize: 18)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${appDocDir.path}/video_diaries');
        if (!await videoDir.exists()) {
          await videoDir.create(recursive: true);
        }
        final permFile = File('${videoDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await File(file.path).copy(permFile.path);

        setState(() {
          _videoPath = permFile.path;
          _videoDataUri = permFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error selecting gallery video: $e');
    }
  }

  // ── Blackout Poetry ─────────────────────────────────────────────────────────
  int _poemStyleIndex = 0;
  late final TextEditingController _poemTextController = TextEditingController();

  void _onBlackoutWordTapped(String word) {
    setState(() {
      if (_selectedBlackoutWords.contains(word)) {
        _selectedBlackoutWords.remove(word);
      } else {
        _selectedBlackoutWords.add(word);
      }
      final gen = PoetryGenerator.generate(_selectedBlackoutWords.toList(), styleIndex: _poemStyleIndex);
      _poemTextController.text = gen;
    });
  }

  void _onRegeneratePoem() {
    setState(() {
      _poemStyleIndex = (_poemStyleIndex + 1) % 3;
      final gen = PoetryGenerator.generate(_selectedBlackoutWords.toList(), styleIndex: _poemStyleIndex);
      _poemTextController.text = gen;
    });
  }

  Widget _buildBlackoutPoetryComposer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🖊️ Tap words to compose your poem',
            style: GoogleFonts.nunito(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_selectedBlackoutWords.isNotEmpty)
            Text('${_selectedBlackoutWords.length} words',
              style: GoogleFonts.nunito(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _blackoutWords.map((word) {
            final isSelected = _selectedBlackoutWords.contains(word);
            return GestureDetector(
              onTap: () => _onBlackoutWordTapped(word),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.purple : const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.4), blurRadius: 8)]
                      : null,
                ),
                child: Text(word,
                  style: GoogleFonts.nunito(
                    color: isSelected ? Colors.white : Colors.grey.shade300,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                    fontSize: 15,
                  )),
              ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 150.ms),
            );
          }).toList(),
        ),
        if (_selectedBlackoutWords.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(children: [
            Text('✨ For You', style: GoogleFonts.nunito(color: const Color(0xFFFBBF24), fontSize: 14, fontWeight: FontWeight.w800)),
            const Spacer(),
            InkWell(
              onTap: _onRegeneratePoem,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBF24), size: 14),
                  const SizedBox(width: 4),
                  Text('Magic 🪄', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _poemTextController,
              maxLines: null,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Color(0xFF0F172A),
                isDense: true,
                hintText: 'Your poem will appear here...',
                hintStyle: TextStyle(color: Colors.white60, fontSize: 15),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Mood Tag Row ────────────────────────────────────────────────────────────
  Widget _buildMoodTagRow() {
    const moodOptions = ['🌟', '😊', '😌', '🤔', '😔', '😤', '😰', '😴', '🔥', '💫'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How does this feel? (optional)', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMedium)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: moodOptions.map((m) {
            final isSelected = _moodTag == m;
            return GestureDetector(
              onTap: () => setState(() => _moodTag = isSelected ? null : m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.purple.withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.purple : Colors.transparent),
                ),
                child: Text(m, style: const TextStyle(fontSize: 20)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ── Time Capsule Toggle ─────────────────────────────────────────────────────
  Widget _buildCapsuleToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        Row(children: [
          const Text('🔮', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Seal as Time Capsule', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
            Text('Re-open it in the future', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight)),
          ])),
          Switch(
            value: _isSealedTimeCapsule,
            onChanged: (v) => setState(() => _isSealedTimeCapsule = v),
            activeThumbColor: AppColors.purple,
          ),
        ]),
        if (_isSealedTimeCapsule) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            _capsuleChip('3 months', DateTime.now().add(const Duration(days: 90))),
            _capsuleChip('6 months', DateTime.now().add(const Duration(days: 180))),
            _capsuleChip('1 year', DateTime.now().add(const Duration(days: 365))),
          ]),
        ],
      ]),
    );
  }

  Widget _capsuleChip(String label, DateTime date) {
    final isSelected = _capsuleRevealDate?.year == date.year &&
        _capsuleRevealDate?.month == date.month;
    return GestureDetector(
      onTap: () => setState(() => _capsuleRevealDate = date),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.nunito(
          color: isSelected ? Colors.white : AppColors.textMedium,
          fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ElevatedButton(
          onPressed: _isSaving ? null : () => _save(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _mode.gradient.first,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isSaving)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            else ...[
              const Icon(Icons.check_circle_outline_rounded),
              const SizedBox(width: 8),
              Text('Save Entry', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ]),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = Directory.systemTemp;
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() { _isRecording = true; _recordingDuration = Duration.zero; });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingDuration += const Duration(seconds: 1));
      if (_recordingDuration.inSeconds >= 90) _stopRecording();
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() { _isRecording = false; _recordedPath = path; });
  }

  Future<void> _playback() async {
    if (_recordedPath == null) return;
    setState(() => _isPlayingBack = true);
    await _audioPlayer.play(DeviceFileSource(_recordedPath!));
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingBack = false);
    });
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() => _isPlayingBack = false);
  }

  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= 4) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        _selectedPhotos.add(File(file.path));
        _selectedPhotoData.add(base64Str);
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );
      if (file != null) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${appDocDir.path}/video_diaries');
        if (!await videoDir.exists()) {
          await videoDir.create(recursive: true);
        }
        final permFile = File('${videoDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await File(file.path).copy(permFile.path);

        setState(() {
          _videoPath = permFile.path;
          _videoDataUri = permFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error recording camera video: $e');
    }
  }
}

class _WaveformAnimated extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(16, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .custom(
            duration: Duration(milliseconds: 300 + (i * 80) % 500),
            builder: (context, value, child) => SizedBox(
              height: 8 + 28 * ((i * 0.37).abs() % 1.0),
              child: child,
            ),
          ),
        )),
      ),
    );
  }
}

class PoetryGenerator {
  static final List<String Function(List<String>)> _templates = [
    (words) {
      if (words.isEmpty) return 'Select words to weave your poem ✨';
      final w = words;
      if (w.length == 1) {
        return "In the quiet space, a single truth vibrates:\n'${w[0]}'\nIt carries the silent strength of a thousand untold stories.";
      }
      if (w.length == 2) {
        return "Beneath the soft and starlit sky,\n${w[0]} whispers as the night passes by.\nHand in hand with ${w[1]},\nA quiet moment turns to light.";
      }
      if (w.length == 3) {
        return "In the calm of today,\n${w[0]} softly finds its way.\n${w[1]} illuminates the morning dew,\nWhile ${w[2]} paints your world anew.";
      }
      return "A quiet spark begins with ${w[0]},\nFlowing gently into ${w[1]}.\nWhere ${w[2]} guides the open heart,\nAnd ${w[3]} lights up a brand new start.";
    },
    (words) {
      if (words.isEmpty) return '';
      final w = words;
      if (w.length == 1) {
        return "Let '${w[0]}' be your anchor today,\nUnshakable, radiant, and true.";
      }
      if (w.length == 2) {
        return "With every step you take,\n${w[0]} leads the path you make.\nAnd through the morning storm,\n${w[1]} keeps your spirit warm.";
      }
      if (w.length == 3) {
        return "Standing tall against the tide,\n${w[0]} blooms with quiet pride.\nWith ${w[1]} in your steady hand,\nAnd ${w[2]} across the rising land.";
      }
      return "Rise with the courage of ${w[0]},\nWalking through the field of ${w[1]}.\nEmbrace the power of ${w[2]},\nAnd let ${w[3]} shine inside of you.";
    },
    (words) {
      if (words.isEmpty) return '';
      final w = words;
      if (w.length == 1) {
        return "Hold onto '${w[0]}' like a secret flame,\nGently lighting up the dark.";
      }
      if (w.length == 2) {
        return "Soft breezes whisper ${w[0]},\nAs twilight welcomes ${w[1]}.\nEverything settles into peace,\nAnd quiet brings release.";
      }
      if (w.length == 3) {
        return "Remember the warmth of ${w[0]},\nThe subtle beauty in ${w[1]}.\nWhere ${w[2]} rests in soft repose,\nAs a new morning gently grows.";
      }
      return "Hold close the memory of ${w[0]},\nAnd honor the strength of ${w[1]}.\nThrough ${w[2]} we learn to grow,\nWhile ${w[3]} brings a golden glow.";
    },
  ];

  static String generate(List<String> words, {int styleIndex = 0}) {
    if (words.isEmpty) return 'Select words above to craft your poem ✨';
    final index = styleIndex % _templates.length;
    return _templates[index](words);
  }
}
