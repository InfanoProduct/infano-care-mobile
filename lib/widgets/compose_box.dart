import 'dart:async';
import 'package:flutter/material.dart';
import 'package:infano_care_mobile/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComposeBox extends StatefulWidget {
  final String placeholder;
  final Function(String, {bool isChallengeResponse}) onSubmitted;
  final String? draftKey;
  final String? initialText;
  final bool isChallengeMode;
  final String? challengePrompt;

  const ComposeBox({
    Key? key,
    required this.placeholder,
    required this.onSubmitted,
    this.draftKey,
    this.initialText,
    this.isChallengeMode = false,
    this.challengePrompt,
  }) : super(key: key);

  @override
  State<ComposeBox> createState() => _ComposeBoxState();
}

class _ComposeBoxState extends State<ComposeBox> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _canSubmit = false;
  Timer? _debounce;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
      _canSubmit = widget.initialText!.trim().isNotEmpty;
    }
    _controller.addListener(_updateCanSubmit);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    if (widget.isChallengeMode) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(ComposeBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChallengeMode && !oldWidget.isChallengeMode) {
      _slideController.forward();
    } else if (!widget.isChallengeMode && oldWidget.isChallengeMode) {
      _slideController.reverse();
    }
  }

  void _updateCanSubmit() {
    final text = _controller.text.trim();
    if (mounted) {
      setState(() {
        _canSubmit = text.isNotEmpty;
      });
      
      // Autosave draft
      if (widget.draftKey != null) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(seconds: 3), () async {
          final prefs = await SharedPreferences.getInstance();
          if (text.isNotEmpty) {
            await prefs.setString(widget.draftKey!, text);
          } else {
            await prefs.remove(widget.draftKey!);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_updateCanSubmit);
    _controller.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_canSubmit) {
      widget.onSubmitted(_controller.text.trim(), isChallengeResponse: widget.isChallengeMode);
      _controller.clear();
      FocusScope.of(context).unfocus();
      
      if (widget.draftKey != null) {
        _debounce?.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(widget.draftKey!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int maxLength = widget.isChallengeMode ? 280 : 500;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Ensures sliding header doesn't spill out
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isChallengeMode && widget.challengePrompt != null)
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.purple.withOpacity(0.05),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.purple, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.challengePrompt!,
                        style: TextStyle(
                          color: AppColors.purple.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: maxLength,
                  decoration: InputDecoration(
                    hintText: widget.isChallengeMode ? 'Type your challenge response...' : widget.placeholder,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_controller.text.length}/$maxLength',
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: _controller.text.length >= 480
                                ? Colors.red
                                : (_controller.text.length >= 400 ? Colors.orange : Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            // Show guidelines
                          },
                          child: Text(
                            'Community Guidelines',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.purple.withOpacity(0.7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _handleSubmit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pinkLight,  // Lighter pink shade
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          widget.isChallengeMode ? 'Respond' : 'Share',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
