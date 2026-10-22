import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    // 4s inhale, 4s exhale breathing cycle
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Start 432 Hz ambient pad
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B3B40), Color(0xFF2D5A60), Color(0xFFC98468)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top control bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            widget.drop.ambientLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isPlayingAudio ? Icons.volume_up : Icons.volume_off, color: Colors.white70),
                      onPressed: _toggleAudio,
                    ),
                  ],
                ),

                const Spacer(),

                // Pulsing Breathing Halo Visualizer
                Center(
                  child: AnimatedBuilder(
                    animation: _breathController,
                    builder: (context, child) {
                      final scale = 1.0 + (_breathController.value * 0.28);
                      final alpha = 0.15 + (_breathController.value * 0.25);

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 180 * scale,
                            height: 180 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: alpha * 0.5),
                            ),
                          ),
                          Container(
                            width: 130 * scale,
                            height: 130 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: alpha),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            alignment: Alignment.center,
                            child: _isFinished
                                ? const Icon(Icons.check, color: Color(0xFF2D5A60), size: 40)
                                : Text(
                                    '${_secondsRemaining}s',
                                    style: const TextStyle(
                                      color: Color(0xFF2D5A60),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Text(
                    _isFinished ? 'Stillness Contemplation Sealed' : 'Inhale slowly... Abide in the Vine',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(),

                // Scripture Card in Sanctuary Light
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"${widget.drop.verseText}"',
                        textAlign: TextAlign.center,
                        style: LogosTypography.scriptureHero(color: Colors.white).copyWith(
                          fontSize: 19,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${widget.drop.reference} · ${widget.drop.translation}',
                        style: LogosTypography.scriptureCitation(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D5A60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      _isFinished ? 'Return to Sanctuary' : 'Rest Complete',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
