import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';

class CovenantScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const CovenantScreen({super.key, required this.onCompleted});

  @override
  State<CovenantScreen> createState() => _CovenantScreenState();
}

class _CovenantScreenState extends State<CovenantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController =
      TextEditingController(text: 'Genesis A.');
  int _step = 0; // 0: Manifesto, 1: 4-Day Rhythm, 2: The Covenant Signature

  late AnimationController _ambientController;
  late AnimationController _sealController;
  final List<_Mote> _motes = [];

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _sealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final rng = math.Random(42);
    for (int i = 0; i < 28; i++) {
      _motes.add(
        _Mote(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: 1.5 + rng.nextDouble() * 2.5,
          speed: 0.08 + rng.nextDouble() * 0.12,
          opacity: 0.2 + rng.nextDouble() * 0.45,
          phase: rng.nextDouble() * 2 * math.pi,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _sealController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onSignAndEnter() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    AudioService().selectionTick();
    await _sealController.forward(from: 0.0);
    await AudioService().playAmenChime();

    if (mounted) {
      context.read<JourneyBloc>().add(SignCovenant(name));
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C191B),
      body: Stack(
        children: [
          // Ambient Gradient Base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2428),
                  Color(0xFF16363C),
                  Color(0xFF234B52),
                  Color(0xFF8F4D35),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // Luminous Radial Glows
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE29578).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2D5A60).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animated Sacred Light Motes
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _MotePainter(
                  motes: _motes,
                  progress: _ambientController.value,
                ),
              );
            },
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Liturgical Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE29578), Color(0xFFD4AF37)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE29578).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '✝',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOGOS IN ME',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'SACRED SCRIPTURE CLOISTER',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.4,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_step < 2)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            AudioService().selectionTick();
                            setState(() => _step = 2);
                          },
                          child: Text(
                            'Skip to Seal',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Dynamic Step View with Smooth Transitions
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentStep(),
                  ),

                  const Spacer(flex: 3),

                  // Silicon Valley Liquid Pill Step Indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final isActive = _step == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 26 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? const LinearGradient(
                                      colors: [Color(0xFFE29578), Color(0xFFD4AF37)],
                                    )
                                  : null,
                              color: isActive ? null : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFE29578).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary Magnetic Action Button
                  GestureDetector(
                    onTap: () {
                      if (_step < 2) {
                        AudioService().selectionTick();
                        setState(() => _step++);
                      } else {
                        _onSignAndEnter();
                      }
                    },
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF7EFE8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFFE29578).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _step < 2 ? 'Continue' : 'Sign & Seal the Covenant',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: const Color(0xFF203B40),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _step < 2 ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded,
                            size: 18,
                            color: const Color(0xFF203B40),
                          ),
                        ],
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

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE29578).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE29578).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 13, color: Color(0xFFE29578)),
                    const SizedBox(width: 6),
                    Text(
                      'THE LITURGICAL MANIFESTO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: const Color(0xFFF7D6C8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'One Verse.\nFour Sacred Days.',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Not an endless scroll. Not a skimming app.\nA digital cloister designed to carve eternal Scripture into your neural pathways and soul.',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.88),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 24),
              // Glass Relic Pill
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pace-locked: One step per calendar day to protect true contemplation.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A scientifically structured spiritual cadence for eternal neural imprint:',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 18),
              _buildRhythmCard(
                icon: Icons.play_circle_fill_rounded,
                day: 'Day 1',
                title: 'Encounter & Oral Recitation',
                desc: 'Cinematic visual immersion & first 2 spoken recitation passes.',
                accentColor: const Color(0xFFE29578),
              ),
              const SizedBox(height: 10),
              _buildRhythmCard(
                icon: Icons.auto_stories_rounded,
                day: 'Day 2',
                title: 'Exegesis & Context',
                desc: 'Greek/Hebrew root depth & historical background cards.',
                accentColor: const Color(0xFF5AB4B8),
              ),
              const SizedBox(height: 10),
              _buildRhythmCard(
                icon: Icons.spa_rounded,
                day: 'Day 3',
                title: 'Stillness & Lectio Divina',
                desc: '60-second breathing sanctuary with 432 Hz ambient pad.',
                accentColor: const Color(0xFF8FD5A6),
              ),
              const SizedBox(height: 10),
              _buildRhythmCard(
                icon: Icons.local_fire_department_rounded,
                day: 'Day 4',
                title: 'Master Recitation & The Exchange',
                desc: 'Memory verification & burden dissolution into the Light.',
                accentColor: const Color(0xFFD4AF37),
              ),
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
                'The Sacred Covenant',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Before entering the cloister, seal your pledge before God to walk unhurried.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),

              // Frosted Glass Parchment Card
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PLEDGE OF THE DISCIPLE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Immutable',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCommitmentBullet('I will speak the Word aloud with reverence.'),
                        _buildCommitmentBullet('I will honor the midnight pace-lock.'),
                        _buildCommitmentBullet('I will surrender heavy burdens into Christ.'),
                        const SizedBox(height: 18),

                        // Signature Pad
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Name (Sacred Signature)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              TextField(
                                controller: _nameController,
                                style: GoogleFonts.caveat(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFF2DC),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  border: InputBorder.none,
                                  hintText: 'Type your name...',
                                  hintStyle: GoogleFonts.caveat(
                                    fontSize: 24,
                                    color: Colors.white30,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Monastic Seal Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_outlined, size: 14, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 5),
                                Text(
                                  'SHA-256 Cloister Seal',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFFD4AF37),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Day 1 Ready',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
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

  Widget _buildRhythmCard({
    required IconData icon,
    required String day,
    required String title,
    required String desc,
    required Color accentColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $title',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommitmentBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mote {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;
  final double phase;

  _Mote({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _MotePainter extends CustomPainter {
  final List<_Mote> motes;
  final double progress;

  _MotePainter({required this.motes, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final mote in motes) {
      final currentY = (mote.y - (progress * mote.speed)) % 1.0;
      final waveX = math.sin((progress * 2 * math.pi) + mote.phase) * 0.02;
      final currentX = (mote.x + waveX).clamp(0.0, 1.0);

      final px = currentX * size.width;
      final py = currentY * size.height;

      final paint = Paint()
        ..color = const Color(0xFFFFF2DC).withValues(
          alpha: (mote.opacity * (0.6 + 0.4 * math.sin((progress * 4 * math.pi) + mote.phase))).clamp(0.05, 0.7),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(px, py), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter oldDelegate) => true;
}
