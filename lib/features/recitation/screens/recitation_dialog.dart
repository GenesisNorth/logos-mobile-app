import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/speech/speech_recognizer.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/utils/scripture_verifier.dart';

class RecitationDialog extends StatefulWidget {
  final String verseText;
  final String reference;
  final int dayNumber;
  final int passNumber; // 1 or 2
  final int totalPasses;
  final bool memoryModeDefault;
  final Function(double score) onPassed;

  const RecitationDialog({
    super.key,
    required this.verseText,
    required this.reference,
    required this.dayNumber,
    this.passNumber = 1,
    this.totalPasses = 2,
    this.memoryModeDefault = false,
    required this.onPassed,
  });

  @override
  State<RecitationDialog> createState() => _RecitationDialogState();
}

class _RecitationDialogState extends State<RecitationDialog>
    with SingleTickerProviderStateMixin {
  late final SpeechRecognizer _recognizer;
  StreamSubscription<SpeechUpdate>? _speechSub;

  bool _isListening = false;
  bool _isEvaluating = false;
  bool _memoryMode = false;
  String _liveTranscript = '';
  double _audioLevel = 0.0;
  double? _score;
  bool _passed = false;
  String? _errorMessage;

  late AnimationController _pulseController;
  final TextEditingController _textFallbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _memoryMode = widget.memoryModeDefault;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _recognizer = SpeechRecognizer.create();
    _speechSub = _recognizer.updates.listen(_handleSpeechUpdate);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechSub?.cancel();
    _recognizer.dispose();
    _textFallbackController.dispose();
    super.dispose();
  }

  void _handleSpeechUpdate(SpeechUpdate update) {
    if (!mounted) return;
    setState(() {
      _liveTranscript = update.transcript;
      _audioLevel = update.level;
      if (update.error != null) {
        _errorMessage = update.error;
      }
      if (update.isFinal || update.phase == SpeechPhase.done) {
        _isListening = false;
        _evaluateTranscript(_liveTranscript);
      }
    });
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _score = null;
      _passed = false;
      _errorMessage = null;
      _liveTranscript = '';
    });

    try {
      await _recognizer.start();
    } catch (e) {
      setState(() {
        _isListening = false;
        _errorMessage = 'Could not access microphone: $e';
      });
    }
  }

  Future<void> _stopListening() async {
    setState(() {
      _isListening = false;
      _isEvaluating = true;
    });

    final finalTranscript = await _recognizer.stop();
    await _evaluateTranscript(finalTranscript.isNotEmpty ? finalTranscript : _liveTranscript);
  }

  Future<void> _evaluateTranscript(String transcript) async {
    setState(() => _isEvaluating = true);

    // Minor settling delay for contemplative feel
    await Future.delayed(const Duration(milliseconds: 300));

    final similarity = ScriptureVerifier.calculateSimilarity(
      widget.verseText,
      transcript,
    );

    final passed = similarity >= ScriptureVerifier.passingThreshold;

    if (passed) {
      await AudioService().playAmenChime();
    }

    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _score = similarity;
        _passed = passed;
      });

      if (passed) {
        widget.onPassed(similarity);
      }
    }
  }

  void _showFallbackInput(BuildContext context, Color surface, Color ink) {
    _textFallbackController.text = _liveTranscript;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Manual Speech Input', style: LogosTypography.label(color: ink)),
        content: TextField(
          controller: _textFallbackController,
          maxLines: 3,
          style: LogosTypography.body(color: ink),
          decoration: const InputDecoration(
            hintText: 'Type what was recited...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LogosColors.coral),
            onPressed: () {
              Navigator.pop(ctx);
              _evaluateTranscript(_textFallbackController.text);
            },
            child: const Text('Verify', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    // Calculate how many words have been reached
    final words = widget.verseText.split(' ');
    final matchedCount = ScriptureVerifier.matchedWordCount(widget.verseText, _liveTranscript);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Day ${widget.dayNumber} · Recitation ${widget.passNumber} of ${widget.totalPasses}',
              style: LogosTypography.label(color: LogosColors.coral),
            ),
            Text(
              widget.reference,
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Type recitation manually',
            icon: Icon(Icons.keyboard_alt_outlined, color: ink.withValues(alpha: 0.6)),
            onPressed: () => _showFallbackInput(context, surface, ink),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Verse text display with live word tracking
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LogosColors.taupe.withValues(alpha: 0.4)),
                ),
                child: _memoryMode && !_passed
                    ? Column(
                        children: [
                          const Icon(Icons.visibility_off_outlined, color: LogosColors.coral, size: 28),
                          const SizedBox(height: 10),
                          Text(
                            'Memory Mode Active',
                            style: LogosTypography.label(color: ink),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Recite from your memory. The scripture is locked in your heart.',
                            textAlign: TextAlign.center,
                            style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                          ),
                        ],
                      )
                    : RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: List.generate(words.length, (i) {
                            final isSpoken = i < matchedCount;
                            return TextSpan(
                              text: '${words[i]} ',
                              style: LogosTypography.scriptureHero(
                                color: isSpoken
                                    ? ink
                                    : ink.withValues(alpha: 0.35),
                              ).copyWith(
                                fontSize: 22,
                                fontWeight: isSpoken ? FontWeight.w700 : FontWeight.w400,
                              ),
                            );
                          }),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Live transcript feedback if any
              if (_liveTranscript.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: LogosColors.coral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '“$_liveTranscript”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LogosTypography.caption(color: ink.withValues(alpha: 0.8)),
                    ),
                  ),
                ),

              const Spacer(),

              // Pulsing Mic Ring Visualizer
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseScale = _isListening
                        ? 1.0 + (_pulseController.value * 0.15) + (_audioLevel * 0.25)
                        : 1.0;
                    return Transform.scale(
                      scale: pulseScale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? LogosColors.coral.withValues(alpha: 0.2)
                              : ink.withValues(alpha: 0.05),
                          border: Border.all(
                            color: _isListening ? LogosColors.coral : ink.withValues(alpha: 0.2),
                            width: _isListening ? 3 : 2,
                          ),
                          boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: LogosColors.coral.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: IconButton(
                          iconSize: 46,
                          icon: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: _isListening ? LogosColors.coral : ink,
                          ),
                          onPressed: _isEvaluating
                              ? null
                              : (_isListening ? _stopListening : _startListening),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              Center(
                child: Text(
                  _isListening
                      ? 'Listening... speak the verse aloud'
                      : (_isEvaluating
                          ? 'Calculating sacred match...'
                          : 'Tap mic and recite scripture aloud'),
                  style: LogosTypography.label(color: ink.withValues(alpha: 0.8)),
                ),
              ),

              const SizedBox(height: 16),

              // Memory mode toggle switch
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _memoryMode,
                      activeThumbColor: LogosColors.coral,
                      onChanged: (val) => setState(() => _memoryMode = val),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hide verse (memory mode)',
                      style: LogosTypography.caption(color: ink.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),

              // Error banner if any
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: LogosTypography.caption(color: Colors.redAccent),
                  ),
                ),
              ],

              // Score Card & Result
              if (_score != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _passed
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _passed ? Colors.green.shade400 : Colors.amber.shade400,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _passed ? Icons.check_circle : Icons.refresh,
                        color: _passed ? Colors.green : Colors.amber.shade800,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
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

              const Spacer(),

              // Engine indicator
              Center(
                child: Text(
                  '${_recognizer.engineLabel} · 80% match to pass',
                  style: LogosTypography.caption(color: ink.withValues(alpha: 0.45)),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _passed ? LogosColors.coral : ink.withValues(alpha: 0.1),
                    foregroundColor: _passed ? Colors.white : ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _passed ? 'Complete Ritual' : 'Close Studio',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
