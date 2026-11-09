import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/services/notification_service.dart';
import '../../journey/data/bible_translations.dart';
import '../../journey/data/content_repository.dart';
import '../../journey/screens/translation_picker_sheet.dart';

class CovenantScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const CovenantScreen({super.key, required this.onCompleted});

  @override
  State<CovenantScreen> createState() => _CovenantScreenState();
}

class _CovenantScreenState extends State<CovenantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  // 0: Welcome, 1: The 4-day rhythm, 2: Your practice, 3: Covenant signature
  int _step = 0;
  static const _lastStep = 3;
  static const _practiceStep = 2;

  String _translation = 'ESV';
  bool _remind = true;
  int _reminderMinutes = NotificationService.defaultReminderMinutes;

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

  /// Leaving "Your practice": apply the translation and, if wanted, ask for
  /// notification permission now that the user knows why.
  Future<void> _applyPractice() async {
    context.read<JourneyBloc>().add(SelectTranslation(_translation));
    if (_remind) {
      await NotificationService.instance.setReminderMinutes(_reminderMinutes);
      await NotificationService.instance.toggleNotifications(true);
    }
  }

  Future<void> _next() async {
    AudioService().selectionTick();
    if (_step == _practiceStep) await _applyPractice();
    if (mounted) setState(() => _step++);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderMinutes ~/ 60,
        minute: _reminderMinutes % 60,
      ),
      helpText: 'Daily reminder',
    );
    if (picked != null) {
      setState(() => _reminderMinutes = picked.hour * 60 + picked.minute);
    }
  }

  void _onSignAndEnter() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write your name to sign the covenant.')),
      );
      return;
    }

    AudioService().selectionTick();
    _sealController.forward(from: 0.0);
    AudioService().playAmenChime();

    if (mounted) {
      context.read<JourneyBloc>().add(SignCovenant(name));
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Luminous White & Subtle Purple Aura Base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xFFFAF8FE),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Luminous Soft Radial Whispers
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
                    const Color(0xFF8B5CF6).withValues(alpha: 0.06),
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
                    const Color(0xFFA78BFA).withValues(alpha: 0.05),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 26.0,
                vertical: 16.0,
              ),
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
                              gradient: LogosColors.purpleGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
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
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: LogosColors.ink,
                                ),
                              ),
                              Text(
                                'Getting started · Step ${_step + 1} of ${_lastStep + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: LogosColors.coral,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_step < _practiceStep)
                        TextButton(
                          onPressed: () {
                            AudioService().selectionTick();
                            setState(() => _step = _practiceStep);
                          },
                          child: Text(
                            'Skip',
                            style: GoogleFonts.inter(
                              color: LogosColors.coral,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Animated Step Content Transition (scrolls on small screens / with keyboard)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AnimatedSwitcher(
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
                      ),
                    ),
                  ),

                  // Step Progression Pill Indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: LogosColors.taupe, width: 1),
                        boxShadow: LogosColors.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_lastStep + 1, (index) {
                          final isActive = _step == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 26 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? LogosColors.purpleGradient
                                  : null,
                              color: isActive ? null : LogosColors.taupe,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.45),
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
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_step < _lastStep) {
                        _next();
                      } else {
                        _onSignAndEnter();
                      }
                    },
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LogosColors.purpleGradient,
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED)
                                .withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _step < _lastStep ? 'Continue' : 'Sign & begin',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppIcon(
                            _step < _lastStep
                                ? LogosIcons.arrowForwardRounded
                                : LogosIcons.checkCircleRounded,
                            size: 18,
                            color: Colors.white,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: LogosColors.coralLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LogosColors.taupe),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(
                      LogosIcons.autoAwesome,
                      size: 13,
                      color: LogosColors.coral,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'WELCOME',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: LogosColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'One verse.\nFour unhurried days.',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.6,
                  color: LogosColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Not an endless feed. Each week you live with one passage of Scripture — hearing it, understanding it, resting in it, and carrying it by heart.',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  height: 1.55,
                  color: LogosColors.inkSecondary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 24),
              // White Card Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: LogosColors.taupe),
                  boxShadow: LogosColors.softShadow,
                ),
                child: Row(
                  children: [
                    const AppIcon(
                      LogosIcons.shieldOutlined,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'One step opens each day, so the Word has time to take root.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: LogosColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                'The 4-day rhythm',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: LogosColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every week follows the same gentle pattern:',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: LogosColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _buildRhythmCard(
                icon: LogosIcons.playCircleFillRounded,
                day: 'Day 1',
                title: 'Encounter',
                desc: 'Meet the verse and recite it aloud twice.',
                accentColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 10),
              _buildRhythmCard(
                icon: LogosIcons.autoStoriesRounded,
                day: 'Day 2',
                title: 'Context',
                desc: 'Discover its background and the original words.',
                accentColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 10),
              _buildRhythmCard(
                icon: LogosIcons.spaRounded,
                day: 'Day 3',
                title: 'Stillness',
                desc: 'Rest with the verse in a guided minute of quiet.',
                accentColor: const Color(0xFF9333EA),
              ),
              const SizedBox(height: 10),
              _buildRhythmCard(
                icon: LogosIcons.localFireDepartmentRounded,
                day: 'Day 4',
                title: 'The Exchange',
                desc: 'Recite from memory and lay a burden down.',
                accentColor: const Color(0xFF5B21B6),
              ),
            ],
          ),
        );

      case 2:
        return KeyedSubtree(
          key: const ValueKey(2),
          child: _buildPracticeStep(),
        );

      case 3:
      default:
        return KeyedSubtree(
          key: const ValueKey(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your covenant',
                style: GoogleFonts.sourceSerif4(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: LogosColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A simple promise before you begin.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: LogosColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Crisp White Luxury Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: LogosColors.taupe, width: 1.2),
                  boxShadow: LogosColors.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MY PROMISE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: LogosColors.coral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCommitmentBullet(
                      'I will speak the Word aloud with reverence.',
                    ),
                    _buildCommitmentBullet(
                      'I will take one step each day, unhurried.',
                    ),
                    _buildCommitmentBullet(
                      'I will bring my burdens to Christ.',
                    ),
                    const SizedBox(height: 18),

                    // Signature Pad in Purple Lilac Tint
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LogosColors.taupe),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign with your name',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: LogosColors.inkSecondary,
                            ),
                          ),
                          TextField(
                            controller: _nameController,
                            style: GoogleFonts.caveat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5B21B6),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              border: InputBorder.none,
                              hintText: 'Your name',
                              hintStyle: GoogleFonts.caveat(
                                fontSize: 24,
                                color: const Color(0xFFC084FC)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPracticeStep() {
    final translation = translationByKey(_translation);
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: _reminderMinutes ~/ 60, minute: _reminderMinutes % 60),
    );
    final firstWeek = const ContentRepository().drops.first;
    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: LogosColors.taupe),
      boxShadow: LogosColors.softShadow,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your practice',
          style: GoogleFonts.sourceSerif4(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: LogosColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change these any time in Settings.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: LogosColors.inkSecondary,
          ),
        ),
        const SizedBox(height: 18),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showTranslationPicker(
            context,
            current: _translation,
            previews: firstWeek.translations,
            onSelected: (key) => setState(() => _translation = key),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration,
            child: Row(
              children: [
                const AppIcon(
                  LogosIcons.bookOpen,
                  color: LogosColors.coral,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bible translation',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: LogosColors.inkSecondary,
                        ),
                      ),
                      Text(
                        translation?.name ?? _translation,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: LogosColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LogosColors.coral,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIcon(
                    LogosIcons.notificationsActive,
                    color: LogosColors.coral,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Daily reminder',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: LogosColors.ink,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _remind,
                    activeTrackColor: LogosColors.coral,
                    onChanged: (v) => setState(() => _remind = v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'One gentle nudge a day so the rhythm isn’t lost. Your phone will ask for permission next.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: LogosColors.inkSecondary,
                ),
              ),
              if (_remind) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LogosColors.coral,
                    side: BorderSide(
                      color: LogosColors.coral.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const AppIcon(
                    LogosIcons.clock,
                    size: 18,
                    color: LogosColors.coral,
                  ),
                  label: Text(
                    'Remind me at $timeLabel',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  onPressed: _pickReminderTime,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRhythmCard({
    required LogosIconData icon,
    required String day,
    required String title,
    required String desc,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LogosColors.taupe, width: 1),
        boxShadow: LogosColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: AppIcon(icon, size: 18, color: accentColor),
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
                    Expanded(
                      child: Text(
                        '· $title',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LogosColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: LogosColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(
            LogosIcons.checkCircleRounded,
            size: 15,
            color: LogosColors.coral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LogosColors.ink,
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
        ..color = const Color(0xFF8B5CF6).withValues(
          alpha:
              (mote.opacity *
                      (0.4 +
                          0.3 *
                              math.sin((progress * 4 * math.pi) + mote.phase)))
                  .clamp(0.05, 0.5),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(Offset(px, py), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MotePainter oldDelegate) => true;
}
