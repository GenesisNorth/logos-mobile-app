import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/audio_service.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/data/week_design.dart';
import '../journey/models/scripture_drop.dart';

const _presets = [
  ('Sanctuary Dawn', 'sanctuary_dawn'),
  ('Cloister Rain', 'cloister_rain'),
  ('Gregorian Choir', 'gregorian_cathedral'),
  ('Midnight Examen', 'midnight_examen'),
  ('Apostolic Sabbath', 'apostolic_sabbath'),
];

const _phases = ['Breathe in', 'Hold', 'Breathe out', 'Rest'];

/// Day 3 — Stillness: a minute of paced breath beneath the Word.
class StillnessScreen extends StatefulWidget {
  final ScriptureDrop drop;
  final int? seconds;
  const StillnessScreen({super.key, required this.drop, this.seconds});

  @override
  State<StillnessScreen> createState() => _StillnessScreenState();
}

class _StillnessScreenState extends State<StillnessScreen>
    with SingleTickerProviderStateMixin {
  late final int _total = widget.seconds ?? AppConfig.stillnessSeconds;
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..addListener(_onBreath);
  Timer? _timer;
  double _elapsed = 0;
  bool _running = false;
  bool _done = false;
  int _preset = 0;
  int _lastPhase = -1;

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    AudioService().stopAmbient();
    super.dispose();
  }

  int get _phase => (_elapsed ~/ 4) % 4;
  int get _remaining => (_total - _elapsed).ceil().clamp(0, _total);

  void _onBreath() {
    if (_phase != _lastPhase && _running) {
      _lastPhase = _phase;
      AudioService().breathTick();
    }
  }

  void _toggle() {
    if (_done) {
      context.read<JourneyBloc>().add(const CompleteDay(3));
      AudioService().playAmenChime();
      Navigator.of(context).pop();
      return;
    }
    if (_running) {
      _timer?.cancel();
      _breath.stop();
      AudioService().pauseAmbient();
      setState(() => _running = false);
      return;
    }
    AudioService().startAmbient(_presets[_preset].$2);
    _breath.repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _elapsed += 0.1);
      if (_elapsed >= _total) {
        _timer?.cancel();
        _breath.stop();
        AudioService().pauseAmbient();
        AudioService().playSanctuaryChime();
        setState(() {
          _running = false;
          _done = true;
        });
      }
    });
    setState(() => _running = true);
  }

  void _choosePreset(int i) {
    setState(() => _preset = i);
    if (_running) {
      AudioService().startAmbient(_presets[i].$2);
    } else {
      AudioService().applyPreset(_presets[i].$2);
    }
  }

  /// Inner ring scale: grows on the in-breath, holds, shrinks, rests.
  double get _scale {
    if (!_running && !_done) return 0.82;
    final t = (_elapsed % 4) / 4;
    return switch (_phase) {
      0 => 0.72 + 0.28 * Curves.easeInOut.transform(t),
      1 => 1.0,
      2 => 1.0 - 0.28 * Curves.easeInOut.transform(t),
      _ => 0.72,
    };
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.night;
    final design = weekDesignFor(widget.drop.weekNumber);
    final mm = _remaining ~/ 60,
        ss = (_remaining % 60).toString().padLeft(2, '0');

    final String label;
    final String sub;
    if (_done) {
      label = 'Be still';
      sub = 'and know';
    } else if (!_running && _elapsed == 0) {
      label = 'Ready';
      sub = 'Begin when you’re settled';
    } else if (!_running) {
      label = 'Paused';
      sub = 'Continue when you’re ready';
    } else {
      label = _phases[_phase];
      sub = '${4 - (_elapsed % 4).floor()}';
    }

    return OScreen(
      atmosphere: atm,
      bottom: OButton(
        _done
            ? 'Complete Day 3'
            : _running
            ? 'Pause'
            : (_elapsed == 0 ? 'Begin · ${_total}s' : 'Continue'),
        style: OButtonStyle.paleSage,
        onPressed: _toggle,
      ),
      child: Column(
        children: [
          OTopBar(
            kicker: 'Day 3 · Stillness',
            atmosphere: atm,
            trailing: Text(
              '$mm:$ss',
              style: OT.label(size: 16, color: OC.s100),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Semantics(
                        liveRegion: true,
                        label: '$label. $sub',
                        excludeSemantics: true,
                        child: SizedBox(
                          width: 230,
                          height: 230,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _ring(230, OC.s800),
                              _ring(170, OC.s700.withValues(alpha: 0.7)),
                              AnimatedScale(
                                scale: _scale,
                                duration: const Duration(milliseconds: 120),
                                child: _ring(
                                  120,
                                  OC.s600.withValues(alpha: 0.8),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: OT.display(32, color: OC.s100),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      sub,
                                      textAlign: TextAlign.center,
                                      style: OT.body(
                                        size: 14,
                                        color: OC.s200,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        design.still,
                        textAlign: TextAlign.center,
                        style: OT.display(22, color: OC.s100, height: 1.25),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'SOUNDSCAPE',
                                  style: OT.kicker(color: OC.s200),
                                ),
                              ),
                              OPill(
                                'Mix stems',
                                bg: Colors.transparent,
                                fg: OC.s100,
                                border: OC.s300.withValues(alpha: 0.5),
                                fontSize: 13,
                                onTap: () => _showMixer(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var i = 0; i < _presets.length; i++)
                                  OPill(
                                    _presets[i].$1,
                                    selected: i == _preset,
                                    selectedBg: OC.s200,
                                    selectedFg: OC.s900,
                                    bg: Colors.white.withValues(alpha: 0.08),
                                    fg: OC.s100,
                                    fontSize: 13,
                                    onTap: () => _choosePreset(i),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double size, Color c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  void _showMixer(BuildContext context) {
    final audio = AudioService();
    showOSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final stems = <(String, double, Future<void> Function(double))>[
            ('Convent Drone', audio.droneVolume, audio.setDroneVolume),
            ('Cloister Rainfall', audio.rainVolume, audio.setRainVolume),
            (
              'Gregorian Vocal Resonance',
              audio.resonanceVolume,
              audio.setResonanceVolume,
            ),
            (
              'Night Cloister Breeze',
              audio.breezeVolume,
              audio.setBreezeVolume,
            ),
            ('Holy Sanctuary Bells', audio.bellsVolume, audio.setBellsVolume),
          ];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Soundscape', style: OT.h2()),
                Text(_presets[_preset].$1, style: OT.small()),
                const SizedBox(height: 12),
                for (final s in stems)
                  _slider(s.$1, s.$2, OC.s600, (v) async {
                    await s.$3(v);
                    setSheet(() {});
                  }),
                const SizedBox(height: 8),
                OCard(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                  child: _slider(
                    'Master intensity',
                    audio.masterVolume,
                    OC.accent,
                    (v) async {
                      await audio.setAmbientVolume(v);
                      setSheet(() {});
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: OT.label(size: 14))),
            Text('${(value * 100).round()}', style: OT.small()),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: OC.n300,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.12),
            trackHeight: 5,
          ),
          child: Slider(
            value: value.clamp(0, 1),
            onChanged: onChanged,
            semanticFormatterCallback: (v) => '$label ${(v * 100).round()}',
          ),
        ),
      ],
    );
  }
}
