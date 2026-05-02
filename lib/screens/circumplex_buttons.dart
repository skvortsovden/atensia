import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';

/// Two 3-button selectors for Russell's Circumplex Model.
/// Valence: Погано (−1) | Нормально (0) | Чудово (+1)
/// Arousal: Виснажено (−1) | Нормально (0) | Бадьоро (+1)
class CircumplexButtons extends StatefulWidget {
  const CircumplexButtons({
    super.key,
    this.title,
    required this.valence,
    required this.arousal,
    required this.onValenceChanged,
    required this.onArousalChanged,
    this.onValenceCleared,
    this.onArousalCleared,
  });

  /// Optional section title drawn as a row with the result pill on the right.
  final String? title;
  final double? valence;
  final double? arousal;
  final ValueChanged<double> onValenceChanged;
  final ValueChanged<double> onArousalChanged;
  final VoidCallback? onValenceCleared;
  final VoidCallback? onArousalCleared;

  static int? _snap(double? v) {
    if (v == null) return null;
    if (v <= -0.34) return 0;
    if (v >= 0.34) return 2;
    return 1;
  }

  @override
  State<CircumplexButtons> createState() => _CircumplexButtonsState();
}

class _CircumplexButtonsState extends State<CircumplexButtons> {
  String? _lastLabel;

  @override
  Widget build(BuildContext context) {
    final hasState = widget.valence != null && widget.arousal != null;
    final label = hasState ? S.circumplexQuadrant(widget.valence!, widget.arousal!) : null;
    if (label != null) _lastLabel = label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: Theme.of(context).textTheme.headlineLarge),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: label != null ? 1.0 : 0.0,
            child: Text(
              (_lastLabel ?? '').toLowerCase(),
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'FixelDisplay',
                fontWeight: FontWeight.w400,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _TripleSelector(
          label: S.todayValenceLabel,
          options: [S.todayValenceLow, S.todayValenceMid, S.todayValenceHigh],
          selectedIndex: CircumplexButtons._snap(widget.valence),
          onTap: (i) {
            HapticFeedback.mediumImpact();
            if (CircumplexButtons._snap(widget.valence) == i) {
              widget.onValenceCleared?.call();
            } else {
              widget.onValenceChanged(i == 0 ? -1.0 : (i == 2 ? 1.0 : 0.0));
            }
          },
        ),
        const SizedBox(height: 28),
        _TripleSelector(
          label: S.todayArousalLabel,
          options: [S.todayArousalLow, S.todayArousalMid, S.todayArousalHigh],
          selectedIndex: CircumplexButtons._snap(widget.arousal),
          onTap: (i) {
            HapticFeedback.mediumImpact();
            if (CircumplexButtons._snap(widget.arousal) == i) {
              widget.onArousalCleared?.call();
            } else {
              widget.onArousalChanged(i == 0 ? -1.0 : (i == 2 ? 1.0 : 0.0));
            }
          },
        ),
      ],
    );
  }
}

// ── Triple selector (segmented control) ──────────────────────────────────────

class _TripleSelector extends StatelessWidget {
  const _TripleSelector({
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onTap,
  });

  final String label;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < options.length; i++) ...[
                    if (i > 0) Container(width: 2, color: Colors.black),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          color: selectedIndex == i
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          child: Text(
                            options[i],
                            style: TextStyle(
                              color: selectedIndex == i
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
