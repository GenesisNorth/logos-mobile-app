import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_event.dart';
import '../models/scripture_drop.dart';

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

  @override
  void initState() {
    super.initState();
    // 4s Inhale, 4s Exhale
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

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

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    AudioService().stopAmbient();
    super.dispose();
  }

  String _getBreathingPrompt() {
    if (_isFinished) return 'Sanctuary Sealed · Walk in Peace';
    final progress = _breathController.value;
    final status = _breathController.status;

    if (status == AnimationStatus.forward) {
      if (progress < 0.2) return 'Prepare to breathe in...';
      return 'Breathe In... Receive the Spirit';
    } else {
      if (progress > 0.8) return 'Hold gently in His peace...';
      return 'Exhale slowly... Release all striving';
    }
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
                        icon: const Icon(Icons.close_rounded, color: LogosColors.ink),
                        onPressed: () {
                          AudioService().selectionTick();
                          Navigator.pop(context);
                        },
                      ),
                      Container(
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
                            const Icon(Icons.graphic_eq_rounded, size: 14, color: LogosColors.coral),
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
                      IconButton(
                        icon: Icon(
                          _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: LogosColors.ink,
                        ),
                        onPressed: _toggleAudio,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Multi-Layered Luminous Breathing Halo Visualizer
                  Center(
                    child: AnimatedBuilder(
                      animation: _breathController,
                      builder: (context, child) {
                        final scale = 1.0 + (_breathController.value * 0.32);
                        final glowAlpha = 0.12 + (_breathController.value * 0.22);
                        final percentDone = (60 - _secondsRemaining) / 60.0;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outermost Ambient Glow Ring
                            Container(
                              width: 240 * scale,
                              height: 240 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF8B5CF6).withValues(alpha: glowAlpha * 0.18),
                              ),
                            ),

                            // Middle Breathing Halo
                            Container(
                              width: 175 * scale,
                              height: 175 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: glowAlpha * 0.6),
                                border: Border.all(
                                  color: const Color(0xFFDDD6FE).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                            ),

                            // Circular 60s Progress Arc
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: percentDone,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(LogosColors.coral),
                                backgroundColor: const Color(0xFFEDE9FE),
                              ),
                            ),

                            // Center Stillness Orb
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
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: LogosColors.coral,
                                      size: 42,
                                    )
                                  : Text(
                                      '${_secondsRemaining}s',
                                      style: GoogleFonts.inter(
                                        color: LogosColors.coral,
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

                  const SizedBox(height: 32),

                  // Dynamic Breathing Directive Prompt
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _getBreathingPrompt(),
                        key: ValueKey(_getBreathingPrompt()),
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
