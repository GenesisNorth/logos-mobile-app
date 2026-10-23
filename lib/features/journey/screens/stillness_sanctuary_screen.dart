import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
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
    } else {
      AudioService().startAmbient(widget.drop.ambientPreset);
    }
    setState(() => _isPlayingAudio = !_isPlayingAudio);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    AudioService().pauseAmbient();
    super.dispose();
  }

  String _getBreathingPrompt() {
    if (_isFinished) return 'Stillness Sealed in Christ';
    final progress = _breathController.value;
    final isForward = _breathController.status == AnimationStatus.forward;

    if (isForward) {
      if (progress < 0.7) return 'Inhale slowly... Draw near to God';
      return 'Hold softly... Abide in His peace';
    } else {
      if (progress > 0.3) return 'Exhale unhurried... Surrender control';
      return 'Rest in silence... He is with you';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2428),
      body: Stack(
        children: [
          // Ambient Gradient Base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF132F34),
                  Color(0xFF1E464E),
                  Color(0xFF28565F),
                  Color(0xFFB56A50),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
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
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () {
                          AudioService().selectionTick();
                          Navigator.pop(context);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.graphic_eq_rounded, size: 14, color: Color(0xFFE29578)),
                            const SizedBox(width: 8),
                            Text(
                              widget.drop.ambientLabel,
                              style: GoogleFonts.inter(
                                color: Colors.white,
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
                          color: Colors.white70,
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
                                color: const Color(0xFFE29578).withValues(alpha: glowAlpha * 0.4),
                              ),
                            ),

                            // Middle Breathing Halo
                            Container(
                              width: 175 * scale,
                              height: 175 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: glowAlpha),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE29578)),
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),

                            // Center Stillness Orb
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Color(0xFFF7EFE8)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isFinished
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF163E44),
                                      size: 42,
                                    )
                                  : Text(
                                      '${_secondsRemaining}s',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF163E44),
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
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Scripture Plaque in Sanctuary Light
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '“${widget.drop.verseText}”',
                              textAlign: TextAlign.center,
                              style: LogosTypography.scriptureHero(color: Colors.white).copyWith(
                                fontSize: 18.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${widget.drop.reference} · ${widget.drop.translation}',
                              style: LogosTypography.scriptureCitation(
                                color: const Color(0xFFF7D6C8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dismiss CTA
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF163E44),
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
