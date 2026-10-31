import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../models/scripture_drop.dart';
import '../../../core/theme/logos_icons.dart';

class EncounterPlayerScreen extends StatefulWidget {
  final ScriptureDrop drop;
  const EncounterPlayerScreen({super.key, required this.drop});

  @override
  State<EncounterPlayerScreen> createState() => _EncounterPlayerScreenState();
}

class _EncounterPlayerScreenState extends State<EncounterPlayerScreen> {
  int _currentLineIndex = 0;
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    AudioService().playSanctuaryChime();
    _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      if (_currentLineIndex < widget.drop.encounterLines.length - 1) {
        setState(() {
          _currentLineIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _next() {
    AudioService().selectionTick();
    if (_currentLineIndex < widget.drop.encounterLines.length - 1) {
      setState(() => _currentLineIndex++);
      _startAutoAdvance();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    AudioService().selectionTick();
    if (_currentLineIndex > 0) {
      setState(() => _currentLineIndex--);
      _startAutoAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.drop.encounterLines;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: LogosColors.coralLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LogosColors.taupe),
                      ),
                      child: Text(
                        'DAY 1 · ENCOUNTER SEQUENCE',
                        style: LogosTypography.caption(color: LogosColors.coral).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const AppIcon(LogosIcons.close, color: LogosColors.ink),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Spacer(),

                // Animated Line Transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentLineIndex),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.drop.reference,
                          style: LogosTypography.caption(color: LogosColors.coral).copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          lines.isNotEmpty ? lines[_currentLineIndex] : widget.drop.verseText,
                          textAlign: TextAlign.center,
                          style: LogosTypography.scriptureHero(color: LogosColors.ink).copyWith(
                            fontSize: 28,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Progress Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(lines.length, (idx) {
                    final isActive = idx == _currentLineIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? LogosColors.coral : LogosColors.taupe,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // Controls Row
                Row(
                  children: [
                    if (_currentLineIndex > 0)
                      IconButton(
                        icon: const AppIcon(LogosIcons.arrowBackIos, color: LogosColors.ink, size: 20),
                        onPressed: _prev,
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LogosColors.coral,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: _next,
                        child: Text(
                          _currentLineIndex == lines.length - 1 ? 'Enter Sanctuary' : 'Next Thought',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
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
