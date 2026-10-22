import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/utils/scripture_verifier.dart';
import '../../../core/services/audio_service.dart';

class RecitationDialog extends StatefulWidget {
  final String verseText;
  final String reference;
  final int dayNumber;
  final Function(double score) onPassed;

  const RecitationDialog({
    super.key,
    required this.verseText,
    required this.reference,
    required this.dayNumber,
    required this.onPassed,
  });

  @override
  State<RecitationDialog> createState() => _RecitationDialogState();
}

class _RecitationDialogState extends State<RecitationDialog>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isEvaluating = false;
  double? _score;
  bool _passed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _score = null;
      _passed = false;
    });
  }

  Future<void> _stopAndVerify() async {
    setState(() {
      _isRecording = false;
      _isEvaluating = true;
    });

    // In Phase 0 Local-Only: simulate real speech stream transcription or verify text
    await Future.delayed(const Duration(milliseconds: 1200));

    // Simulated transcribed speech with high fidelity
    final transcribedSample = widget.verseText;
    final similarity = ScriptureVerifier.calculateSimilarity(
      widget.verseText,
      transcribedSample,
    );

    final passed = similarity >= ScriptureVerifier.passingThreshold;

    if (passed) {
      await AudioService().playAmenChime();
    }

    setState(() {
      _isEvaluating = false;
      _score = similarity;
      _passed = passed;
    });

    if (passed) {
      widget.onPassed(similarity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Recitation Ritual',
                  style: LogosTypography.label(color: LogosColors.coral),
                ),
                Text(
                  widget.reference,
                  style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '"${widget.verseText}"',
              textAlign: TextAlign.center,
              style: LogosTypography.scriptureBody(color: ink),
            ),
            const SizedBox(height: 28),

            // Pulsing Audio Wave Visualizer
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _isRecording
                      ? 1.0 + (_pulseController.value * 0.25)
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? LogosColors.coral.withValues(alpha: 0.2)
                            : ink.withValues(alpha: 0.05),
                        border: Border.all(
                          color: _isRecording
                              ? LogosColors.coral
                              : ink.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: IconButton(
                        iconSize: 42,
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: _isRecording ? LogosColors.coral : ink,
                        ),
                        onPressed: _isEvaluating
                            ? null
                            : (_isRecording ? _stopAndVerify : _startRecording),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isRecording
                  ? 'Reciting... Tap to verify'
                  : (_isEvaluating
                      ? 'Calculating Levenshtein match...'
                      : 'Tap mic and recite scripture aloud'),
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.7)),
            ),

            if (_score != null) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _passed
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _passed ? Icons.check_circle : Icons.refresh,
                      color: _passed ? Colors.green : Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Match: ${(_score! * 100).toInt()}% ${_passed ? "(Passed ✓)" : "(Try again, need 80%)"}',
                      style: LogosTypography.label(
                        color: _passed ? Colors.green.shade900 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  _passed ? 'Done' : 'Cancel',
                  style: LogosTypography.label(color: ink),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
