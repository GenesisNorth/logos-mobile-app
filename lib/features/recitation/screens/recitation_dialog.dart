import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/speech/speech_recognizer.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/utils/scripture_verifier.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/services/verse_reader.dart';
import '../../../core/widgets/logos_dialog.dart';

enum ScaffoldingMode {
  full('Full Text', LogosIcons.visibilityOutlined),
  partial('50% Clue', LogosIcons.blurOnRounded),
  firstLetters('Initials', LogosIcons.shortTextRounded),
  memory('Heart Recall', LogosIcons.favoriteOutlineRounded);

  final String label;
  final LogosIconData icon;
  const ScaffoldingMode(this.label, this.icon);
}

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
  ScaffoldingMode _scaffoldingMode = ScaffoldingMode.full;
  String _liveTranscript = '';
  double _audioLevel = 0.0;
  double? _score;
  bool _passed = false;
  String? _errorMessage;

  /// True once the current attempt has been scored (prevents double scoring
  /// when both the engine's auto-finish and the stop button fire).
  bool _attemptScored = false;
  bool _stopRequested = false;
  bool _passReported = false;

  late AnimationController _pulseController;
  final TextEditingController _textFallbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scaffoldingMode = widget.memoryModeDefault
        ? ScaffoldingMode.memory
        : ScaffoldingMode.full;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _recognizer = SpeechRecognizer.create(targetVerse: widget.verseText);
    _speechSub = _recognizer.updates.listen(_handleSpeechUpdate);
  }

  @override
  void dispose() {
    VerseReader.instance.stop();
    _pulseController.dispose();
    _speechSub?.cancel();
    _recognizer.dispose();
    _textFallbackController.dispose();
    super.dispose();
  }

  int get _targetWordCount =>
      ScriptureVerifier.normalize(widget.verseText)
          .split(' ')
          .where((w) => w.isNotEmpty)
          .length;

  void _handleSpeechUpdate(SpeechUpdate update) {
    if (!mounted) return;

    // Engine failed (permission, unavailable, network…): reset to idle, don't score.
    if (update.phase == SpeechPhase.error) {
      setState(() {
        _isListening = false;
        _isEvaluating = false;
        _errorMessage = update.error;
        if (update.transcript.isNotEmpty) _liveTranscript = update.transcript;
      });
      return;
    }

    final prevCount = ScriptureVerifier.matchedWordCount(
      widget.verseText,
      _liveTranscript,
    );
    final newCount = ScriptureVerifier.matchedWordCount(
      widget.verseText,
      update.transcript,
    );
    if (newCount > prevCount) {
      AudioService().wordProgressTick();
    }

    setState(() {
      if (update.transcript.isNotEmpty || update.phase == SpeechPhase.done) {
        _liveTranscript = update.transcript;
      }
      _audioLevel = update.level;
    });

    // Engine finished on its own (session limit) while user hadn't pressed stop.
    if (update.phase == SpeechPhase.done && !_stopRequested && _isListening) {
      setState(() => _isListening = false);
      _evaluateTranscript(_liveTranscript);
      return;
    }

    // Auto-stop as soon as every word of the verse has been heard.
    if (_isListening &&
        !_stopRequested &&
        _targetWordCount > 0 &&
        newCount >= _targetWordCount) {
      _stopListening();
    }
  }

  Future<void> _startListening() async {
    await VerseReader.instance.stop();
    AudioService().selectionTick();
    setState(() {
      _isListening = true;
      _score = null;
      _passed = false;
      _errorMessage = null;
      _liveTranscript = '';
      _attemptScored = false;
      _stopRequested = false;
    });

    try {
      await _recognizer.start();
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : e.toString();
      setState(() {
        _isListening = false;
        _errorMessage = msg;
      });
    }
  }

  Future<void> _stopListening() async {
    if (_stopRequested) return;
    _stopRequested = true;
    AudioService().selectionTick();
    setState(() {
      _isListening = false;
      _isEvaluating = true;
    });

    final finalTranscript = await _recognizer.stop();
    await _evaluateTranscript(
      finalTranscript.isNotEmpty ? finalTranscript : _liveTranscript,
    );
  }

  Future<void> _evaluateTranscript(
    String transcript, {
    bool manual = false,
  }) async {
    if (_attemptScored && !manual) return;
    _attemptScored = true;
    if (!mounted) return;

    if (transcript.trim().isEmpty) {
      setState(() {
        _isEvaluating = false;
        _errorMessage = 'No speech was heard. Hold the phone closer, tap the mic and recite again — or use the keyboard.';
      });
      return;
    }

    setState(() {
      _isEvaluating = true;
      _liveTranscript = transcript;
      _errorMessage = null; // A transcript arrived, so any earlier "no speech" error is stale.
    });
    await Future.delayed(const Duration(milliseconds: 350));

    final similarity = ScriptureVerifier.calculateSimilarity(
      widget.verseText,
      transcript,
    );

    final passed = similarity >= ScriptureVerifier.passingThreshold;

    if (passed) {
      AudioService().playAmenChime();
    }

    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _score = similarity;
        _passed = passed;
      });

      if (passed && !_passReported) {
        _passReported = true;
        widget.onPassed(similarity);
      }
    }
  }

  Future<void> _showFallbackInput(
    BuildContext context,
    Color surface,
    Color ink,
  ) async {
    _textFallbackController.text = _liveTranscript;
    final text = await showLogosDialog<String>(
      context,
      title: 'Type your recitation',
      message: 'If speaking aloud isn’t possible right now, type the verse from memory.',
      content: TextField(
        controller: _textFallbackController,
        autofocus: true,
        maxLines: 4,
        minLines: 3,
        style: LogosTypography.body(color: ink),
        decoration: InputDecoration(
          hintText: 'Type the verse…',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      confirmLabel: 'Check',
      onConfirm: () => _textFallbackController.text,
    );
    if (text != null && text.trim().isNotEmpty) {
      _evaluateTranscript(text, manual: true);
    }
  }

  Future<void> _toggleHearVerse() async {
    final reader = VerseReader.instance;
    if (reader.isReading(widget.verseText)) {
      await reader.stop();
      return;
    }
    if (_isListening) return; // don't let the speaker feed the microphone
    if (!await reader.speak(widget.verseText) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reading voice is available on this phone.'),
        ),
      );
    }
  }

  String _formatScaffoldedWord(String word, int index, ScaffoldingMode mode) {
    switch (mode) {
      case ScaffoldingMode.full:
        return word;
      case ScaffoldingMode.partial:
        if (index % 2 == 1 && word.length > 2) {
          return '—' * math.min(word.length, 5);
        }
        return word;
      case ScaffoldingMode.firstLetters:
        final clean = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        final punct = word.replaceAll(RegExp(r'[a-zA-Z0-9]'), '');
        if (clean.isEmpty) return word;
        return '${clean[0]}$punct';
      case ScaffoldingMode.memory:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    final words = widget.verseText.split(' ');
    final matchedCount = ScriptureVerifier.matchedWordCount(
      widget.verseText,
      _liveTranscript,
    );

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close',
          icon: AppIcon(LogosIcons.closeRounded, color: ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: LogosColors.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Day ${widget.dayNumber} · Recitation ${widget.passNumber} of ${widget.totalPasses}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: LogosColors.coral,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.reference,
              style: LogosTypography.scriptureCitation(
                color: ink.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: VerseReader.instance,
            builder: (context, _) {
              final reading = VerseReader.instance.isReading(widget.verseText);
              return IconButton(
                tooltip: reading ? 'Stop reading' : 'Hear the verse',
                icon: AppIcon(
                  reading ? LogosIcons.stopRounded : LogosIcons.volumeUpRounded,
                  color: reading
                      ? LogosColors.coral
                      : ink.withValues(alpha: 0.6),
                ),
                onPressed: _toggleHearVerse,
              );
            },
          ),
          IconButton(
            tooltip: 'Type your recitation',
            icon: AppIcon(
              LogosIcons.keyboardAltOutlined,
              color: ink.withValues(alpha: 0.6),
            ),
            onPressed: () => _showFallbackInput(context, surface, ink),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cognitive Scaffolding Modern Segmented Pill Dock
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ink.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: LogosColors.taupe.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: ScaffoldingMode.values.map((mode) {
                    final isSelected = _scaffoldingMode == mode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          AudioService().selectionTick();
                          setState(() => _scaffoldingMode = mode);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xFF2E2620)
                                      : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                mode.icon,
                                size: 13,
                                color: isSelected
                                    ? LogosColors.coral
                                    : ink.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  mode.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? ink
                                        : ink.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Illuminated Scripture Recitation Sanctuary Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: LogosColors.coral.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: LogosColors.relicShadow,
                  ),
                  // Scale the verse down to fit the card so no words are ever clipped
                  // when the transcript, error and score rows take vertical space.
                  child: LayoutBuilder(
                    builder: (context, constraints) => Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child:
                              _scaffoldingMode == ScaffoldingMode.memory &&
                                  !_passed
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: LogosColors.coral.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: LogosColors.coral.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: const AppIcon(
                                        LogosIcons.favoriteRounded,
                                        color: LogosColors.coral,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sacred Heart Recall',
                                      style: LogosTypography.sacredHeader(
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'The Word is veiled. Close your eyes and recite from deep within your memory.',
                                      textAlign: TextAlign.center,
                                      style: LogosTypography.body(
                                        color: ink.withValues(alpha: 0.68),
                                      ),
                                    ),
                                  ],
                                )
                              : RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: List.generate(words.length, (i) {
                                      final isSpoken = i < matchedCount;
                                      final formattedWord =
                                          _formatScaffoldedWord(
                                            words[i],
                                            i,
                                            _scaffoldingMode,
                                          );

                                      return TextSpan(
                                        text: '$formattedWord ',
                                        style:
                                            LogosTypography.scriptureHero(
                                              color: isSpoken
                                                  ? (isDark
                                                        ? const Color(
                                                            0xFFFDE8DF,
                                                          )
                                                        : LogosColors.ink)
                                                  : ink.withValues(alpha: 0.32),
                                            ).copyWith(
                                              fontSize: 22,
                                              fontWeight: isSpoken
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              backgroundColor: isSpoken
                                                  ? LogosColors.coral
                                                        .withValues(alpha: 0.14)
                                                  : null,
                                            ),
                                      );
                                    }),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Live Spoken Bubble / Transcript
              if (_liveTranscript.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: LogosColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: LogosColors.coral.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(
                          LogosIcons.graphicEq,
                          size: 16,
                          color: LogosColors.coral,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '“$_liveTranscript”',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.sourceSerif4(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              color: ink.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Multi-Ring Audio Visualizer & Mic Button
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Concentric Pulsing Wave Rings
                      if (_isListening) ...[
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final scale =
                                1.0 +
                                (_pulseController.value * 0.3) +
                                (_audioLevel * 0.4);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: LogosColors.coral.withValues(
                                      alpha:
                                          (0.4 - _pulseController.value * 0.2)
                                              .clamp(0.05, 0.4),
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final scale =
                                1.15 +
                                (_pulseController.value * 0.15) +
                                (_audioLevel * 0.2);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: LogosColors.coral.withValues(
                                    alpha:
                                        (0.12 - _pulseController.value * 0.06)
                                            .clamp(0.02, 0.15),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      // Core Mic Button
                      Semantics(
                        button: true,
                        label: _isListening
                            ? 'Stop and check recitation'
                            : 'Start reciting',
                        child: GestureDetector(
                          onTap: _isEvaluating
                              ? null
                              : (_isListening
                                    ? _stopListening
                                    : _startListening),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _isListening
                                  ? LogosColors.purpleGradient
                                  : LinearGradient(
                                      colors: isDark
                                          ? [
                                              const Color(0xFF241445),
                                              const Color(0xFF160B30),
                                            ]
                                          : [
                                              Colors.white,
                                              const Color(0xFFFAF5FF),
                                            ],
                                    ),
                              border: Border.all(
                                color: _isListening
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : LogosColors.taupe,
                                width: 1.5,
                              ),
                              boxShadow: _isListening
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : LogosColors.softShadow,
                            ),
                            child: AppIcon(
                              _isListening
                                  ? LogosIcons.stopRounded
                                  : LogosIcons.micRounded,
                              size: 38,
                              color: _isListening
                                  ? Colors.white
                                  : LogosColors.coral,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  _isListening
                      ? 'Listening... speak the verse aloud'
                      : (_isEvaluating
                            ? 'Checking your recitation…'
                            : 'Tap microphone and speak aloud'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ink.withValues(alpha: 0.75),
                  ),
                ),
              ),

              // Error banner if any
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _passed
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _passed
                          ? Colors.green.shade400
                          : Colors.amber.shade400,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        _passed
                            ? LogosIcons.checkCircleRounded
                            : LogosIcons.refreshRounded,
                        color: _passed ? Colors.green : Colors.amber.shade800,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Match: ${(_score! * 100).toInt()}% ${_passed ? "(Sacred Pass ✓)" : "(Need 80% to seal day)"}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _passed
                              ? Colors.green.shade900
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Engine & Pass Rules
              Center(
                child: Text(
                  'Recite at least 80% of the verse correctly to pass',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: ink.withValues(alpha: 0.4),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Bottom Dismiss / Complete Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _passed
                        ? LogosColors.coral
                        : ink.withValues(alpha: 0.08),
                    foregroundColor: _passed ? Colors.white : ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    AudioService().selectionTick();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    _passed ? 'Complete Sacred Recitation' : 'Close Studio',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
