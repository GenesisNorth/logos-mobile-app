import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../models/scripture_drop.dart';

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
    _startTimer();
  }

  void _startTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_currentLineIndex < widget.drop.encounterLines.length - 1) {
        setState(() => _currentLineIndex++);
      } else {
        _autoAdvanceTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _next() {
    if (_currentLineIndex < widget.drop.encounterLines.length - 1) {
      setState(() => _currentLineIndex++);
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_currentLineIndex > 0) {
      setState(() => _currentLineIndex--);
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.drop.encounterLines;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E383C), Color(0xFF2D5A60), Color(0xFF3B2E26)],
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'DAY 1 · ENCOUNTER SEQUENCE',
                        style: LogosTypography.caption(color: Colors.white).copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
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
                          style: LogosTypography.scriptureHero(color: Colors.white).copyWith(
                            fontSize: 28,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
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
                        color: isActive ? LogosColors.coral : Colors.white24,
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
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                        onPressed: _prev,
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2D5A60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          padding: const EdgeInsets.symmetric(horizontal: 32),
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
