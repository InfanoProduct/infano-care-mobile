import 'package:flutter/material.dart';
import '../../models/circle.dart';
import '../../services/community_api.dart';
import 'package:provider/provider.dart';

class CircleSelectionDialog extends StatefulWidget {
  final List<Circle> initialCircles;
  const CircleSelectionDialog({super.key, required this.initialCircles});

  @override
  State<CircleSelectionDialog> createState() => _CircleSelectionDialogState();
}

class _CircleSelectionDialogState extends State<CircleSelectionDialog> {
  late Set<String> _selectedCircleIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCircleIds = widget.initialCircles
        .where((c) => c.isJoined)
        .map((c) => c.id)
        .toSet();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final api = Provider.of<CommunityApi>(context, listen: false);
      await api.joinCircles(_selectedCircleIds.toList());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final circles = widget.initialCircles.where((c) => !c.isAgeSpecific).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join Communities',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Select the circles you\'d like to join to see their posts in your feed.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: circles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final circle = circles[index];
                  final isSelected = _selectedCircleIds.contains(circle.id);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCircleIds.remove(circle.id);
                        } else {
                          _selectedCircleIds.add(circle.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pink.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected ? Colors.pink : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            circle.iconEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  circle.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.pink : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                if (circle.description != null)
                                  Text(
                                    circle.description!,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isSelected,
                            activeThumbColor: Colors.pink,
                            onChanged: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCircleIds.add(circle.id);
                                } else {
                                  _selectedCircleIds.remove(circle.id);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
