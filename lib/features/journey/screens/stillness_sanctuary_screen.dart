import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_event.dart';
import '../models/scripture_drop.dart';
import '../../../core/theme/logos_icons.dart';

enum BreathPhase { inhale, hold, exhale, rest }

class StillnessSanctuaryScreen extends StatefulWidget {
  final ScriptureDrop drop;
  const StillnessSanctuaryScreen({super.key, required this.drop});

  @override
  State<StillnessSanctuaryScreen> createState() => _StillnessSanctuaryScreenState();
}

class _StillnessSanctuaryScreenState extends State<StillnessSanctuaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _isFinished = false;
  bool _isPlayingAudio = true;
  int _lastPhaseIndex = -1;

  @override
  void initState() {
    super.initState();
    // 16s complete loop: 4s Inhale, 4s Hold, 4s Exhale, 4s Rest
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(_onBreathTick)..repeat();

    // 432 Hz Ambient Pad
    AudioService().startAmbient(widget.drop.ambientPreset);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _onCompleteStillness();
      }
    });
  }

  void _onBreathTick() {
    final phaseIndex = (_breathController.value * 4).floor() % 4;
    if (phaseIndex != _lastPhaseIndex) {
      _lastPhaseIndex = phaseIndex;
      AudioService().breathTick();
    }
  }

  void _onCompleteStillness() {
    setState(() => _isFinished = true);
    AudioService().playSanctuaryChime();
    context.read<JourneyBloc>().add(const CompleteDayStillness(3));
  }

  void _toggleAudio() {
    AudioService().selectionTick();
    if (_isPlayingAudio) {
      AudioService().pauseAmbient();
      setState(() => _isPlayingAudio = false);
    } else {
      AudioService().startAmbient(widget.drop.ambientPreset);
      setState(() => _isPlayingAudio = true);
    }
  }

  void _showSoundscapeConsole(BuildContext context) {
    AudioService().selectionTick();
    final audio = AudioService();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final surface = isDark ? LogosColors.examenSurface : Colors.white;
            final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: LogosColors.taupe),
                boxShadow: LogosColors.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: LogosColors.coral.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const AppIcon(LogosIcons.graphicEqRounded, color: LogosColors.coral, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sacred Soundscape Console',
                                    style: LogosTypography.headline(color: ink).copyWith(fontSize: 16),
                                  ),
                                  Text(
                                    'Contemplative Multi-Track Ambient Stems',
                                    style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: audio.isMuted ? 'Unmute' : 'Mute',
                        icon: AppIcon(
                          audio.isMuted ? LogosIcons.volumeOffRounded : LogosIcons.volumeUpRounded,
                          color: audio.isMuted ? Colors.grey : LogosColors.coral,
                        ),
                        onPressed: () {
                          audio.selectionTick();
                          audio.toggleMute();
                          setSheetState(() {});
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preset Chips Row
                  Text('Atmospheric Presets:', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPresetChip(
                        label: 'Sanctuary Dawn',
                        presetKey: 'sanctuary_dawn',
                        activePreset: audio.activePreset,
                        onTap: () {
                          audio.selectionTick();
                          audio.applyPreset('sanctuary_dawn');
                          setSheetState(() {});
                          setState(() {});
                        },
                        ink: ink,
                      ),
                      _buildPresetChip(
                        label: 'Cloister Rain',
                        presetKey: 'cloister_rain',
                        activePreset: audio.activePreset,
                        onTap: () {
                          audio.selectionTick();
                          audio.applyPreset('cloister_rain');
                          setSheetState(() {});
                          setState(() {});
                        },
                        ink: ink,
                      ),
                      _buildPresetChip(
                        label: 'Gregorian Choir',
                        presetKey: 'gregorian_cathedral',
                        activePreset: audio.activePreset,
                        onTap: () {
                          audio.selectionTick();
                          audio.applyPreset('gregorian_cathedral');
                          setSheetState(() {});
                          setState(() {});
                        },
                        ink: ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Multi-Track Stem Sliders
                  _buildStemSlider(
                    label: 'Convent 432 Hz Drone',
                    description: 'Warm grounding harmonic floor',
                    icon: LogosIcons.spaRounded,
                    value: audio.droneVolume,
                    activeColor: LogosColors.coral,
                    ink: ink,
                    onChanged: (val) {
                      audio.setDroneVolume(val);
                      setSheetState(() {});
                    },
                  ),
                  _buildStemSlider(
                    label: 'Cloister Rainfall',
                    description: 'Natural soothing rainfall on sanctuary stones',
                    icon: LogosIcons.waterDrop,
                    value: audio.rainVolume,
                    activeColor: const Color(0xFF0284C7),
                    ink: ink,
                    onChanged: (val) {
                      audio.setRainVolume(val);
                      setSheetState(() {});
                    },
                  ),
                  _buildStemSlider(
                    label: 'Gregorian Vocal Resonance',
                    description: 'Celestial open-fifths sacred resonance',
                    icon: LogosIcons.menuBook,
                    value: audio.resonanceVolume,
                    activeColor: const Color(0xFF8B5CF6),
                    ink: ink,
                    onChanged: (val) {
                      audio.setResonanceVolume(val);
                      setSheetState(() {});
                    },
                  ),

                  const SizedBox(height: 6),

                  // Master Intensity Slider
                  Row(
                    children: [
                      Text(
                        'Master Intensity: ${(audio.masterVolume * 100).toInt()}%',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
                      ),
                      const Spacer(),
                      if (audio.isMuted)
                        Text(
                          'MUTED',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange.shade800),
                        ),
                    ],
                  ),
                  Slider(
                    value: audio.masterVolume,
                    activeColor: LogosColors.coral,
                    inactiveColor: LogosColors.taupe,
                    onChanged: (val) {
                      audio.setAmbientVolume(val);
                      setSheetState(() {});
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required String presetKey,
    required String activePreset,
    required VoidCallback onTap,
    required Color ink,
  }) {
    final isSelected = activePreset == presetKey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? LogosColors.coral : ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LogosColors.coral : LogosColors.taupe,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : ink,
          ),
        ),
      ),
    );
  }

  Widget _buildStemSlider({
    required String label,
    required String description,
    required LogosIconData icon,
    required double value,
    required ValueChanged<double> onChanged,
    required Color activeColor,
    required Color ink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LogosColors.taupe.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 15, color: activeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: activeColor),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 10, color: ink.withValues(alpha: 0.6)),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withValues(alpha: 0.18),
              thumbColor: activeColor,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  BreathPhase _getPhase() {
    final v = _breathController.value;
    if (v < 0.25) return BreathPhase.inhale;
    if (v < 0.50) return BreathPhase.hold;
    if (v < 0.75) return BreathPhase.exhale;
    return BreathPhase.rest;
  }

  String _getBreathingPrompt() {
    if (_isFinished) return 'Sanctuary Sealed · Walk in Peace';
    switch (_getPhase()) {
      case BreathPhase.inhale:
        return 'Breathe In... Receive the Holy Spirit';
      case BreathPhase.hold:
        return 'Hold gently in His unbroken peace...';
      case BreathPhase.exhale:
        return 'Exhale slowly... Release all striving & fear';
      case BreathPhase.rest:
        return 'Rest empty... Be still before the Lord';
    }
  }

  String _getPhaseLabel() {
    if (_isFinished) return 'SANCTUARY SEALED';
    switch (_getPhase()) {
      case BreathPhase.inhale:
        return 'INHALE · 4 SECONDS';
      case BreathPhase.hold:
        return 'HOLD · 4 SECONDS';
      case BreathPhase.exhale:
        return 'EXHALE · 4 SECONDS';
      case BreathPhase.rest:
        return 'REST · 4 SECONDS';
    }
  }

  Color _getPhaseColor() {
    if (_isFinished) return const Color(0xFF10B981);
    switch (_getPhase()) {
      case BreathPhase.inhale:
        return LogosColors.coral;
      case BreathPhase.hold:
        return const Color(0xFFD4AF37); // Warm gold
      case BreathPhase.exhale:
        return const Color(0xFF8B5CF6); // Liturgical purple
      case BreathPhase.rest:
        return const Color(0xFF0284C7); // Quiet blue
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    AudioService().stopAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ambient Clean White & Soft Blended Purple Gradient Base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFAF7FE),
                  Color(0xFFF3EBFC),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Liturgical Control Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const AppIcon(LogosIcons.closeRounded, color: LogosColors.ink),
                        onPressed: () {
                          AudioService().selectionTick();
                          Navigator.pop(context);
                        },
                      ),
                      GestureDetector(
                        key: const Key('soundscape_console_button'),
                        onTap: () => _showSoundscapeConsole(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: LogosColors.taupe),
                            boxShadow: LogosColors.softShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(LogosIcons.graphicEqRounded, size: 14, color: LogosColors.coral),
                              const SizedBox(width: 8),
                              Text(
                                widget.drop.ambientLabel,
                                style: GoogleFonts.inter(
                                  color: LogosColors.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: AppIcon(
                          _isPlayingAudio ? LogosIcons.volumeUpRounded : LogosIcons.volumeOffRounded,
                          color: LogosColors.ink,
                        ),
                        onPressed: _toggleAudio,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Multi-Layered Luminous Sacred Breathing Halo Visualizer
                  Center(
                    child: AnimatedBuilder(
                      animation: _breathController,
                      builder: (context, child) {
                        final v = _breathController.value;
                        double scale;
                        double glowAlpha;

                        if (v < 0.25) {
                          // Inhale: 0.0 -> 0.25
                          final t = Curves.easeInOutCubic.transform(v / 0.25);
                          scale = 1.0 + (0.35 * t);
                          glowAlpha = 0.12 + (0.24 * t);
                        } else if (v < 0.50) {
                          // Hold: 0.25 -> 0.50
                          final subT = (v - 0.25) / 0.25;
                          scale = 1.35 + (0.025 * sin(subT * 2 * pi));
                          glowAlpha = 0.36;
                        } else if (v < 0.75) {
                          // Exhale: 0.50 -> 0.75
                          final t = Curves.easeInOutCubic.transform((v - 0.50) / 0.25);
                          scale = 1.35 - (0.35 * t);
                          glowAlpha = 0.36 - (0.24 * t);
                        } else {
                          // Rest: 0.75 -> 1.00
                          scale = 1.0;
                          glowAlpha = 0.12;
                        }

                        final percentDone = (60 - _secondsRemaining) / 60.0;
                        final activeColor = _getPhaseColor();

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outermost Ambient Violet & Gold Glow Ring
                            Container(
                              width: 250 * scale,
                              height: 250 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeColor.withValues(alpha: glowAlpha * 0.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withValues(alpha: glowAlpha * 0.3),
                                    blurRadius: 36 * scale,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                            // Middle Resonant Breathing Halo
                            Container(
                              width: 180 * scale,
                              height: 180 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: glowAlpha * 0.7),
                                border: Border.all(
                                  color: activeColor.withValues(alpha: 0.45),
                                  width: 1.6,
                                ),
                              ),
                            ),

                            // Circular 60s Progress Arc
                            SizedBox(
                              width: 124,
                              height: 124,
                              child: CircularProgressIndicator(
                                value: percentDone,
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                                backgroundColor: const Color(0xFFEDE9FE),
                              ),
                            ),

                            // Center Sacred Stillness Orb
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: LogosColors.taupe, width: 1.5),
                                boxShadow: LogosColors.softShadow,
                              ),
                              alignment: Alignment.center,
                              child: _isFinished
                                  ? const AppIcon(
                                      LogosIcons.checkRounded,
                                      color: Color(0xFF10B981),
                                      size: 42,
                                    )
                                  : Text(
                                      '${_secondsRemaining}s',
                                      style: GoogleFonts.inter(
                                        color: activeColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Liturgical Phase Badge Pill
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_getPhaseLabel()),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getPhaseColor().withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _getPhaseColor().withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getPhaseLabel(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: _getPhaseColor(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Dynamic Breathing Directive Prompt
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _getBreathingPrompt(),
                        key: ValueKey(_getBreathingPrompt()),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sourceSerif4(
                          color: LogosColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Scripture Plaque in Clean White Sanctuary Light
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: LogosColors.taupe,
                        width: 1,
                      ),
                      boxShadow: LogosColors.softShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '“${widget.drop.verseText}”',
                          textAlign: TextAlign.center,
                          style: LogosTypography.scriptureHero(color: LogosColors.ink).copyWith(
                            fontSize: 18.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${widget.drop.reference} · ${widget.drop.translation}',
                          style: LogosTypography.scriptureCitation(
                            color: LogosColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dismiss CTA
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LogosColors.coral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      onPressed: () {
                        AudioService().selectionTick();
                        Navigator.pop(context);
                      },
                      child: Text(
                        _isFinished ? 'Seal Sanctuary & Return' : 'Leave Stillness',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
