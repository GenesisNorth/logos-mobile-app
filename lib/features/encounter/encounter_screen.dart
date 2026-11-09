import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/speech/speech_recognizer.dart';
import '../../core/services/verse_reader.dart';
import '../../core/utils/scripture_verifier.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/data/week_design.dart';
import '../journey/models/scripture_drop.dart';

enum _Phase { story, recite, done }

enum ReciteMode {
  full('Full text'),
  first('First letters'),
  fade('Fading'),
  blank('From memory');

  final String label;
  const ReciteMode(this.label);
}

/// Day 1 — Encounter: a short story at dusk, then speak the verse aloud.
class EncounterScreen extends StatefulWidget {
  final ScriptureDrop drop;

  /// Start straight in recitation (e.g. revisiting a finished day).
  final bool startWithRecitation;

  const EncounterScreen({super.key, required this.drop, this.startWithRecitation = false});

  @override
  State<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends State<EncounterScreen> {
  late final WeekDesign _design = weekDesignFor(widget.drop.weekNumber);
  late _Phase _phase = widget.startWithRecitation ? _Phase.recite : _Phase.story;
  int _line = 0;
  Timer? _storyTimer;

  // Recitation
  late final SpeechRecognizer _recognizer;
  StreamSubscription<SpeechUpdate>? _sub;
  ReciteMode _mode = ReciteMode.full;
  bool _listening = false;
  bool _evaluating = false;
  bool _stopRequested = false;
  bool _scored = false;
  bool _reported = false;
  String _transcript = '';
  String? _error;
  double? _score;
  List<int> _slips = const [];

  List<String> get _words => widget.drop.verseText.split(' ');
  bool get _passed => (_score ?? 0) >= ScriptureVerifier.passingThreshold;

  @override
  void initState() {
    super.initState();
    _recognizer = SpeechRecognizer.create(targetVerse: widget.drop.verseText);
    _sub = _recognizer.updates.listen(_onSpeech);
    if (_phase == _Phase.story) _scheduleLine();
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _sub?.cancel();
    _recognizer.dispose();
    VerseReader.instance.stop();
    super.dispose();
  }

  // ─── Story ───────────────────────────────────────────────────────────────

  void _scheduleLine() {
    _storyTimer?.cancel();
    _storyTimer = Timer(const Duration(milliseconds: 3400), _advance);
  }

  void _advance() {
    if (!mounted || _phase != _Phase.story) return;
    if (_line < _design.encounterLines.length - 1) {
      setState(() => _line++);
      _scheduleLine();
    }
  }

  void _toRecite() {
    _storyTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() => _phase = _Phase.recite);
  }

  // ─── Recitation ──────────────────────────────────────────────────────────

  void _onSpeech(SpeechUpdate u) {
    if (!mounted) return;
    if (u.phase == SpeechPhase.error) {
      setState(() {
        _listening = false;
        _evaluating = false;
        _error = u.error;
        if (u.transcript.isNotEmpty) _transcript = u.transcript;
      });
      return;
    }
    final before = ScriptureVerifier.matchedWordCount(widget.drop.verseText, _transcript);
    final after = ScriptureVerifier.matchedWordCount(widget.drop.verseText, u.transcript);
    if (after > before) AudioService().wordProgressTick();
    setState(() {
      if (u.transcript.isNotEmpty || u.phase == SpeechPhase.done) _transcript = u.transcript;
    });
    if (u.phase == SpeechPhase.done && !_stopRequested && _listening) {
      setState(() => _listening = false);
      _evaluate(_transcript);
      return;
    }
    final total = ScriptureVerifier.normalize(widget.drop.verseText).split(' ').length;
    if (_listening && !_stopRequested && after >= total) _stop();
  }

  Future<void> _start() async {
    await VerseReader.instance.stop();
    HapticFeedback.selectionClick();
    setState(() {
      _listening = true;
      _error = null;
      _transcript = '';
      _score = null;
      _scored = false;
      _stopRequested = false;
      _phase = _Phase.recite;
    });
    try {
      await _recognizer.start();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = e is StateError ? e.message : '$e';
      });
    }
  }

  Future<void> _stop() async {
    if (_stopRequested) return;
    _stopRequested = true;
    setState(() {
      _listening = false;
      _evaluating = true;
    });
    final finalText = await _recognizer.stop();
    await _evaluate(finalText.isNotEmpty ? finalText : _transcript);
  }

  Future<void> _evaluate(String transcript, {bool manual = false}) async {
    if (_scored && !manual) return;
    _scored = true;
    if (!mounted) return;
    if (transcript.trim().isEmpty) {
      setState(() {
        _evaluating = false;
        _error = 'No words came through. Hold the phone a little closer and try again — or type it instead.';
      });
      return;
    }
    final score = ScriptureVerifier.calculateSimilarity(widget.drop.verseText, transcript);
    final slips = ScriptureVerifier.slipWordIndices(widget.drop.verseText, transcript);
    if (score >= ScriptureVerifier.passingThreshold) AudioService().playAmenChime();
    setState(() {
      _evaluating = false;
      _error = null;
      _transcript = transcript;
      _score = score;
      _slips = slips;
      _phase = _Phase.done;
    });
    if (score >= ScriptureVerifier.passingThreshold && !_reported) {
      _reported = true;
      context.read<JourneyBloc>().add(CompleteDayRecitation(dayNumber: 1, score: score));
    }
  }

  Future<void> _typeInstead() async {
    final controller = TextEditingController(text: _transcript);
    final text = await showOSheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Type it from memory', style: OT.h3()),
          const SizedBox(height: 6),
          Text('If speaking aloud isn’t possible right now, type the verse as you remember it.', style: OT.small()),
          const SizedBox(height: 14),
          OInput(controller: controller, hint: 'Type the verse…', minLines: 3, maxLines: 5, autofocus: true),
          const SizedBox(height: 14),
          OButton('Check', onPressed: () => Navigator.pop(ctx, controller.text)),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      setState(() => _scored = false);
      _evaluate(text, manual: true);
    }
  }

  void _retry() => setState(() {
        _phase = _Phase.recite;
        _score = null;
        _transcript = '';
        _slips = const [];
        _error = null;
      });

  String _wordFor(int i) {
    final w = _words[i];
    switch (_mode) {
      case ReciteMode.full:
        return w;
      case ReciteMode.first:
        final letters = w.replaceAll(RegExp(r'[^A-Za-z]'), '');
        if (letters.isEmpty) return w;
        return letters[0] + w.replaceAll(RegExp(r'[A-Za-z]'), '').padLeft(0);
      case ReciteMode.fade:
        return i.isOdd && w.length > 2 ? '—' * (w.length.clamp(2, 5)) : w;
      case ReciteMode.blank:
        return '—' * (w.replaceAll(RegExp(r'[^A-Za-z]'), '').length.clamp(2, 6));
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.dusk;
    return OScreen(
      atmosphere: atm,
      child: Column(
        children: [
          OTopBar(
            kicker: 'Day 1 · Encounter',
            atmosphere: atm,
            trailing: ListenableBuilder(
              listenable: VerseReader.instance,
              builder: (context, _) {
                final reading = VerseReader.instance.isReading(widget.drop.verseText);
                return OCircleButton(
                  icon: reading ? OI.pause : OI.speaker,
                  tooltip: reading ? 'Stop reading' : 'Hear the verse',
                  background: Colors.white.withValues(alpha: 0.12),
                  foreground: OC.n100,
                  onTap: _listening
                      ? null
                      : () => reading ? VerseReader.instance.stop() : VerseReader.instance.speak(widget.drop.verseText),
                );
              },
            ),
          ),
          Expanded(child: _phase == _Phase.story ? _story() : _recite()),
        ],
      ),
    );
  }

  Widget _story() {
    final lines = _design.encounterLines;
    final last = _line >= lines.length - 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: last ? null : () {
        HapticFeedback.selectionClick();
        _advance();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i <= _line; i++)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: i == _line ? 1 : 0.42,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(lines[i], style: OT.display(28, color: OC.n100, height: 1.15)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (!last) Text('Tap to continue', textAlign: TextAlign.center, style: OT.small(color: OC.n100, alpha: 0.45)),
            const SizedBox(height: 12),
            last
                ? OButton('Speak it aloud', icon: OI.mic, onPressed: _toRecite)
                : Material(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _toRecite,
                      child: SizedBox(
                        height: 54,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const OIcon(OI.mic, size: 18, color: OC.n100),
                            const SizedBox(width: 8),
                            Text('Skip to recitation', style: OT.button(color: OC.n100)),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _recite() {
    final matched = _phase == _Phase.done
        ? _words.length
        : ScriptureVerifier.matchedWordCount(widget.drop.verseText, _transcript);
    final base = OT.verse(size: 27, color: OC.n100);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${widget.drop.reference} · ${widget.drop.translation}'.toUpperCase(), style: OT.kicker(color: OC.a400)),
          const SizedBox(height: 6),
          Text('Speak it aloud. Words light up as you say them.', style: OT.small(color: OC.n100, alpha: 0.7)),
          const SizedBox(height: 14),
          if (_phase != _Phase.done)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in ReciteMode.values)
                  OPill(m.label,
                      selected: m == _mode,
                      selectedBg: OC.n100,
                      selectedFg: OC.text,
                      bg: Colors.white.withValues(alpha: 0.1),
                      fg: OC.n100,
                      fontSize: 13,
                      onTap: () => setState(() => _mode = m)),
              ],
            ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Text.rich(TextSpan(children: [
                for (var i = 0; i < _words.length; i++)
                  TextSpan(
                    text: '${i < matched || _phase == _Phase.done ? _words[i] : _wordFor(i)} ',
                    style: _phase == _Phase.done && _slips.contains(i)
                        ? base.copyWith(
                            color: OC.a400,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.wavy,
                            decorationColor: OC.a400,
                          )
                        : base.copyWith(color: i < matched ? OC.n100 : OC.n100.withValues(alpha: 0.38)),
                  ),
              ])),
            ),
          ),
          if (_phase == _Phase.done) ..._result() else ..._micControls(),
        ],
      ),
    );
  }

  List<Widget> _micControls() {
    final status = _listening
        ? 'Listening… speak the verse'
        : _evaluating
            ? 'Listening back…'
            : _transcript.isEmpty
                ? 'Tap the mic and recite'
                : 'Paused — tap to continue';
    return [
      if (_error != null) ...[
        Text(_error!, textAlign: TextAlign.center, style: OT.small(color: OC.a300, alpha: 1)),
        const SizedBox(height: 12),
      ],
      Center(
        child: Semantics(
          button: true,
          label: _listening ? 'Stop and check' : 'Start reciting',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _evaluating ? null : (_listening ? _stop : _start),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: OC.accent,
                shape: BoxShape.circle,
                boxShadow: _listening ? [BoxShadow(color: OC.accent.withValues(alpha: 0.45), spreadRadius: 10, blurRadius: 18)] : null,
              ),
              child: Center(child: OIcon(_listening ? OI.pause : OI.mic, size: 34, color: OC.n100)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(status, textAlign: TextAlign.center, style: OT.label(size: 15, color: OC.n100.withValues(alpha: 0.85))),
      TextButton(
        onPressed: _listening ? null : _typeInstead,
        child: Text('Type it instead', style: OT.small(color: OC.a300, alpha: 1)),
      ),
    ];
  }

  List<Widget> _result() {
    final pct = ((_score ?? 0) * 100).round();
    final slipWords = _slips.take(3).map((i) => '“${_words[i].replaceAll(RegExp(r"[^\w’']"), '')}”').toList();
    final title = _passed ? 'Spoken by heart' : 'Not quite yet';
    final body = !_passed
        ? 'You need 80% to finish today. Try once more — the words are settling in.'
        : _slips.isEmpty
            ? 'Every word, by heart. The Word is taking root.'
            : '${_slips.length == 1 ? 'One small slip' : '${_slipCountWord(_slips.length)} small slips'} — ${slipWords.join(' and ')}. The Word is taking root.';
    return [
      const SizedBox(height: 10),
      OCard(
        color: OC.n800,
        radius: 28,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: _passed ? OC.s500 : OC.a700, shape: BoxShape.circle),
              child: Center(child: Text('$pct%', style: OT.display(22, color: OC.n100))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OT.display(21, color: OC.n100)),
                  const SizedBox(height: 4),
                  Text(body, style: OT.small(color: OC.n100, alpha: 0.78)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (_passed) ...[
        OButton('Complete Day 1', onPressed: () => Navigator.of(context).pop()),
        TextButton(onPressed: _retry, child: Text('Recite again', style: OT.small(color: OC.n100, alpha: 0.7))),
      ] else ...[
        OButton('Try again', icon: OI.mic, onPressed: () {
          _retry();
          _start();
        }),
        TextButton(onPressed: _typeInstead, child: Text('Type it instead', style: OT.small(color: OC.a300, alpha: 1))),
      ],
    ];
  }

  static String _slipCountWord(int n) => const ['Zero', 'One', 'Two', 'Three', 'Four', 'Five'][n.clamp(0, 5)];
}
