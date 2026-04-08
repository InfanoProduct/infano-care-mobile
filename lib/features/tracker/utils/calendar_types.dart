/// Domain types for the calendar day cell.
/// Import this file wherever PhaseInfo, PhaseType or FlowLevel are needed.

// ── PhaseType ─────────────────────────────────────────────────────────────────

enum PhaseType {
  menstrual,
  follicular,
  fertile,
  ovulation,
  luteal,
  unknown,
}

// ── FlowLevel ─────────────────────────────────────────────────────────────────

enum FlowLevel {
  none,
  spotting,
  light,
  medium,
  heavy,
  ended,
}

// ── PhaseInfo ──────────────────────────────────────────────────────────────────

class PhaseInfo {
  final PhaseType phase;
  final bool isPredicted;

  /// Background opacity override for predicted phases (0.0–1.0).
  final double opacity;

  const PhaseInfo({
    required this.phase,
    this.isPredicted = false,
    this.opacity = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhaseInfo &&
          other.phase == phase &&
          other.isPredicted == isPredicted &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(phase, isPredicted, opacity);
}

// ── Helpers ────────────────────────────────────────────────────────────────────

/// Convert a raw flow string (from the API) to [FlowLevel].
FlowLevel flowLevelFromString(String? raw) {
  switch (raw) {
    case 'spotting':
      return FlowLevel.spotting;
    case 'light':
      return FlowLevel.light;
    case 'medium':
      return FlowLevel.medium;
    case 'heavy':
      return FlowLevel.heavy;
    case 'ended':
      return FlowLevel.ended;
    case 'none':
    case null:
    default:
      return FlowLevel.none;
  }
}
