import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/theme/logos_icons.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double flutter;
  double flutterSpeed;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.flutter,
    required this.flutterSpeed,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Holy altar shockwave ripple
    if (progress < 0.65) {
      final waveProgress = progress / 0.65;
      final waveRadius = (size.width * 0.65) * waveProgress;
      final wavePaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: (1.0 - waveProgress) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - waveProgress);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), waveRadius, wavePaint);
    }

    for (final p in particles) {
      // Ambient holy aura glow
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity * 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * 2.6, glowPaint);

      // Core ember
      final corePaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size, corePaint);

      // Incandescent bright center
      final centerPaint = Paint()
        ..color = Colors.white.withValues(alpha: (p.opacity * 0.85).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.45, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

class ExchangeCanvas extends StatefulWidget {
  final String verseText;
  final String reference;
  final int weekNumber;
  final VoidCallback onExchangeCompleted;

  const ExchangeCanvas({
    super.key,
    required this.verseText,
    required this.reference,
    this.weekNumber = 1,
    required this.onExchangeCompleted,
  });

  @override
  State<ExchangeCanvas> createState() => _ExchangeCanvasState();
}

class _ExchangeCanvasState extends State<ExchangeCanvas>
    with SingleTickerProviderStateMixin {
  final TextEditingController _burdenController = TextEditingController(
    text: "Carrying chronic anxiety over finances and family burdens...",
  );

  bool _isDissolved = false;
  bool _isDraggingOver = false;
  int _lastHapticTick = 0;

  late AnimationController _dissolveController;
  final List<Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _dissolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..addListener(_updateParticles);
  }

  @override
  void dispose() {
    _dissolveController.dispose();
    _burdenController.dispose();
    super.dispose();
  }

  void _spawnParticles(Size zoneSize) {
    _particles.clear();
    const count = 160;
    final colors = [
      LogosColors.coral,
      const Color(0xFFF59E0B), // Warm amber gold
      const Color(0xFFFDE68A), // Incandescent pale gold
      const Color(0xFFE89070), // Terracotta flame
      const Color(0xFFDDD6FE), // Holy violet ember
      Colors.white,
    ];

    for (int i = 0; i < count; i++) {
      _particles.add(Particle(
        x: _rand.nextDouble() * zoneSize.width,
        y: _rand.nextDouble() * zoneSize.height,
        vx: (_rand.nextDouble() - 0.5) * 3.6,
        vy: -(_rand.nextDouble() * 3.8 + 1.8), // drift upwards
        size: _rand.nextDouble() * 3.8 + 1.4,
        opacity: 0.95,
        flutter: _rand.nextDouble() * 2 * pi,
        flutterSpeed: _rand.nextDouble() * 0.12 + 0.04,
        color: colors[_rand.nextInt(colors.length)],
      ));
    }
  }

  void _updateParticles() {
    final progress = _dissolveController.value;

    // Progressive ember crackle haptic feedback
    final currentTick = (progress * 4).floor();
    if (currentTick > _lastHapticTick && currentTick <= 3) {
      _lastHapticTick = currentTick;
      AudioService().emberPulse();
    }

    for (final p in _particles) {
      p.flutter += p.flutterSpeed;
      p.x += p.vx + sin(p.flutter) * 1.4;
      p.y += p.vy;
      p.vy -= 0.04; // Thermal updraft
      p.opacity = ((1.0 - progress) * 0.95).clamp(0.0, 1.0);
      p.size = (p.size * 0.993).clamp(0.6, 5.5);
    }
    setState(() {});
  }

  void _triggerExchangeDissolution(Size zoneSize) {
    _lastHapticTick = 0;
    AudioService().triggerExchangeHaptic();
    _spawnParticles(zoneSize);

    _dissolveController.forward().then((_) {
      setState(() {
        _isDissolved = true;
      });
      AudioService().playSanctuaryChime();
      widget.onExchangeCompleted();
    });
  }

  void _shareTearSheet() {
    final dateStr = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    final shareText = '''
✝ THE EXCHANGE · WEEK ${widget.weekNumber}
"${widget.verseText}"
— ${widget.reference}

A burden was laid down here.
$dateStr
LOGOS IN ME
''';
    SharePlus.instance.share(ShareParams(text: shareText, subject: 'The Exchange — ${widget.reference}'));
  }

  @override
  Widget build(BuildContext context) {
    const Color ink = LogosColors.examenInk;
    const Color surface = LogosColors.examenSurface;

    return Scaffold(
      backgroundColor: LogosColors.examenBg,
      appBar: AppBar(
        title: Text(
          'The Exchange',
          style: LogosTypography.label(color: ink),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const AppIcon(LogosIcons.arrowBack, color: ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isDissolved)
            IconButton(
              tooltip: 'Share Tear Sheet',
              icon: const AppIcon(LogosIcons.share, color: LogosColors.coral),
              onPressed: _shareTearSheet,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lay your heavy burden down. Drag the mastered Scripture over it to dissolve the burden.',
                textAlign: TextAlign.center,
                style: LogosTypography.body(color: ink.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),

              // Upper Zone: Burden Target
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final zoneSize = Size(constraints.maxWidth, constraints.maxHeight);

                    return Stack(
                      children: [
                        DragTarget<String>(
                          onWillAcceptWithDetails: (_) {
                            setState(() => _isDraggingOver = true);
                            return true;
                          },
                          onLeave: (_) {
                            setState(() => _isDraggingOver = false);
                          },
                          onAcceptWithDetails: (_) {
                            setState(() => _isDraggingOver = false);
                            _triggerExchangeDissolution(zoneSize);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _isDraggingOver
                                    ? LogosColors.coral.withValues(alpha: 0.2)
                                    : surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isDraggingOver
                                      ? LogosColors.coral
                                      : const Color(0xFF3E3730),
                                  width: _isDraggingOver ? 2 : 1,
                                ),
                              ),
                              child: _isDissolved
                                  ? _buildTearSheetView(surface, ink)
                                  : Opacity(
                                      opacity: 1.0 - _dissolveController.value,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const AppIcon(
                                                LogosIcons.editNote,
                                                size: 20,
                                                color: LogosColors.coral,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Your Burden:',
                                                style: LogosTypography.label(
                                                  color: LogosColors.coral,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: _burdenController,
                                              maxLines: null,
                                              expands: true,
                                              style: LogosTypography.scriptureBody(
                                                color: ink,
                                              ),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: 'Type your burden here...',
                                                hintStyle: TextStyle(
                                                  color: ink.withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              '↓ Drop Scripture Here to Dissolve ↓',
                                              style: LogosTypography.caption(
                                                color: LogosColors.coral,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            );
                          },
                        ),

                        // Dissolution particle overlay
                        if (_dissolveController.isAnimating)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ParticlePainter(_particles, _dissolveController.value),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Zone: Draggable Scripture or Action Button
              if (!_isDissolved)
                Draggable<String>(
                  data: widget.verseText,
                  feedback: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LogosColors.sanctuaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: LogosColors.coral.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.verseText,
                        style: LogosTypography.scriptureBody(color: Colors.white),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildDraggableCard(surface, ink),
                  ),
                  child: _buildDraggableCard(surface, ink),
                )
              else
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LogosColors.coral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const AppIcon(LogosIcons.share),
                    label: const Text(
                      'Share Tear Sheet & Return to Sanctuary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      _shareTearSheet();
                      Navigator.of(context).pop();
                    },
                  ),
                ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableCard(Color surface, Color ink) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LogosColors.coral, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LogosColors.coral.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mastered Scripture (Drag Upward)',
                  style: LogosTypography.label(color: LogosColors.coral),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const AppIcon(LogosIcons.dragIndicator, color: LogosColors.coral),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${widget.verseText}"',
            style: LogosTypography.scriptureBody(color: ink),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.reference,
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTearSheetView(Color surface, Color ink) {
    final now = DateTime.now();
    final dateStr = '${now.day} / ${now.month} / ${now.year}';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.scale(
            scale: 0.92 + (0.08 * animValue),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LogosColors.parchmentGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            ...LogosColors.relicShadow,
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LogosColors.purpleGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('✝', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(
              'THE SACRED EXCHANGE · WEEK ${widget.weekNumber}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: const Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '“${widget.verseText}”',
              textAlign: TextAlign.center,
              style: LogosTypography.scriptureHero(color: LogosColors.ink).copyWith(fontSize: 19.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.reference} · ESV',
              style: LogosTypography.scriptureCitation(color: LogosColors.coral),
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'A burden was laid down at the Cross.',
              style: GoogleFonts.sourceSerif4(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: LogosColors.ink.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: LogosColors.ink.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(LogosIcons.verifiedRounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(
                    'Sealed in your Prayer Altar',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F5132),
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
}
