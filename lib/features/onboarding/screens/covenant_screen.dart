import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/logos_theme.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';

class CovenantScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const CovenantScreen({super.key, required this.onCompleted});

  @override
  State<CovenantScreen> createState() => _CovenantScreenState();
}

class _CovenantScreenState extends State<CovenantScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Genesis A.');
  int _step = 0; // 0: Welcome / Manifesto, 1: 4-Day Rhythm, 2: The Covenant Signature

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSignAndEnter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.read<JourneyBloc>().add(SignCovenant(name));
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B3B3F), Color(0xFF2D5A60), Color(0xFFD48B6E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Brand Mark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: LogosColors.coral,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '✝',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LOGOS IN ME',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    if (_step < 2)
                      TextButton(
                        onPressed: () => setState(() => _step = 2),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                // Step Pages
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _buildCurrentStep(),
                ),

                const Spacer(),

                // Bottom Navigation & Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isActive = _step == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Primary CTA
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D5A60),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _onSignAndEnter();
                      }
                    },
                    child: Text(
                      _step < 2 ? 'Continue' : 'Sign & Enter the Sanctuary',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: const Color(0xFFB86646),
                      ),
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'One Verse.\nFour Sacred Days.',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Not a content feed. Not a skimming app.\nA digital cloister designed to carve eternal Scripture into your neural pathways and soul.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );

      case 1:
        return KeyedSubtree(
          key: const ValueKey(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The 4-Day Rhythm',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildRhythmRow('Day 1', 'Encounter & Oral Recitation', 'Listen, watch, recite twice aloud.'),
              const SizedBox(height: 12),
              _buildRhythmRow('Day 2', 'Context & Exegesis', 'Theological roots & historical depth.'),
              const SizedBox(height: 12),
              _buildRhythmRow('Day 3', 'Logos & Stillness', '432 Hz sanctuary contemplation.'),
              const SizedBox(height: 12),
              _buildRhythmRow('Day 4', 'Mastery & The Exchange', 'Lay your heaviest burdens at the Cross.'),
            ],
          ),
        );

      case 2:
      default:
        return KeyedSubtree(
          key: const ValueKey(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Covenant',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'I commit to walk slowly with the Word — one verse, four days, no rushing ahead.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              _buildCommitmentBullet('I will recite aloud, not skim.'),
              _buildCommitmentBullet('I will abide in stillness for 60 seconds.'),
              _buildCommitmentBullet('I will lay my burdens down into the Word.'),
              const SizedBox(height: 20),

              // Frosted glass signature card
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type your full name to sign',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: GoogleFonts.caveat(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            hintText: 'Your name...',
                            hintStyle: GoogleFonts.caveat(
                              fontSize: 24,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.lock_outline, size: 12, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  'SHA-256 Verified',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildCommitmentBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhythmRow(String day, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
