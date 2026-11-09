import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'organic.dart';

/// Icon set for the Organic redesign (Hugeicons stroke-rounded, drawn heavier
/// to match the design's 2.75px Lucide strokes).
class OI {
  OI._();
  static const home = HugeIcons.strokeRoundedHome03;
  static const community = HugeIcons.strokeRoundedUserGroup;
  static const flame = HugeIcons.strokeRoundedFire;
  static const bell = HugeIcons.strokeRoundedNotification03;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const next = HugeIcons.strokeRoundedArrowRight01;
  static const down = HugeIcons.strokeRoundedArrowDown01;
  static const video = HugeIcons.strokeRoundedVideo01;
  static const mic = HugeIcons.strokeRoundedMic01;
  static const play = HugeIcons.strokeRoundedPlay;
  static const pause = HugeIcons.strokeRoundedPause;
  static const check = HugeIcons.strokeRoundedTick02;
  static const lock = HugeIcons.strokeRoundedSquareLock02;
  static const heart = HugeIcons.strokeRoundedFavourite;
  static const sprout = HugeIcons.strokeRoundedPlant02;
  static const search = HugeIcons.strokeRoundedSearch01;
  static const send = HugeIcons.strokeRoundedSent;
  static const moon = HugeIcons.strokeRoundedMoon02;
  static const sun = HugeIcons.strokeRoundedSun03;
  static const droplet = HugeIcons.strokeRoundedDroplet;
  static const book = HugeIcons.strokeRoundedBookOpen01;
  static const mountain = HugeIcons.strokeRoundedMountain;
  static const wave = HugeIcons.strokeRoundedAudioWave01;
  static const share = HugeIcons.strokeRoundedShare08;
  static const pen = HugeIcons.strokeRoundedPencilEdit02;
  static const mail = HugeIcons.strokeRoundedMail01;
  static const flag = HugeIcons.strokeRoundedFlag02;
  static const speaker = HugeIcons.strokeRoundedVolumeHigh;
  static const phone = HugeIcons.strokeRoundedCallRinging01;
  static const alert = HugeIcons.strokeRoundedAlert02;
}

class OIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final double size;
  final Color? color;
  const OIcon(this.icon, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) =>
      HugeIcon(icon: icon, size: size, color: color ?? IconTheme.of(context).color ?? OC.text, strokeWidth: 2.2);
}

/// Screen scaffold with an atmosphere (background + status-bar contrast).
class OScreen extends StatelessWidget {
  final Atmosphere atmosphere;
  final Widget child;
  final Widget? bottom;
  final bool safeTop;
  final Color? background;

  const OScreen({
    super.key,
    required this.atmosphere,
    required this.child,
    this.bottom,
    this.safeTop = true,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: atmosphere.overlay,
      child: Scaffold(
        backgroundColor: background ?? atmosphere.bg,
        body: SafeArea(top: safeTop, bottom: false, child: child),
        bottomNavigationBar: bottom == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(22, 8, 22, 14), child: bottom),
              ),
      ),
    );
  }
}

/// Round 40px button used for close/back in the top bar.
class OCircleButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final String tooltip;
  final double size;

  const OCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.background = OC.n100,
    this.foreground = OC.text,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: Center(child: OIcon(icon, size: 19, color: foreground))),
        ),
      ),
    );
  }
}

/// "×   DAY 2 · ROOTS   1/3" — the header used by every practice screen.
class OTopBar extends StatelessWidget {
  final String kicker;
  final Atmosphere atmosphere;
  final VoidCallback? onLeading;
  final bool back;
  final Widget? trailing;
  final Color? kickerColor;

  const OTopBar({
    super.key,
    required this.kicker,
    required this.atmosphere,
    this.onLeading,
    this.back = false,
    this.trailing,
    this.kickerColor,
  });

  @override
  Widget build(BuildContext context) {
    final ink = atmosphere.ink;
    final buttonBg = atmosphere.dark ? Colors.white.withValues(alpha: 0.12) : ink.withValues(alpha: 0.07);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            OCircleButton(
              icon: back ? OI.back : OI.close,
              tooltip: back ? 'Back' : 'Close',
              background: buttonBg,
              foreground: ink,
              onTap: onLeading ?? () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(kicker.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: OT.kicker(color: kickerColor ?? ink.withValues(alpha: atmosphere.dark ? 0.7 : 0.75), size: 13)),
            ),
            SizedBox(width: 44, child: Align(alignment: Alignment.centerRight, child: trailing)),
          ],
        ),
      ),
    );
  }
}

enum OButtonStyle { primary, light, sage, dark, outline, paleSage }

/// Full-width pill button.
class OButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final OButtonStyle style;
  final List<List<dynamic>>? icon;
  final bool trailingIcon;
  final bool expand;
  final double height;
  final Color? outlineColor;

  const OButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.style = OButtonStyle.primary,
    this.icon,
    this.trailingIcon = false,
    this.expand = true,
    this.height = 54,
    this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (style) {
      OButtonStyle.primary => (OC.accent, OC.n100),
      OButtonStyle.light => (OC.n100, OC.a800),
      OButtonStyle.sage => (OC.s700, OC.s100),
      OButtonStyle.paleSage => (OC.s200, OC.s900),
      OButtonStyle.dark => (OC.n800, OC.n100),
      OButtonStyle.outline => (Colors.transparent, outlineColor ?? OC.text),
    };
    final disabled = onPressed == null;
    final iconW = icon == null ? null : OIcon(icon!, size: 18, color: fg);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconW != null && !trailingIcon) ...[iconW, const SizedBox(width: 8)],
        Flexible(child: Text(label, style: OT.button(color: fg), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
        if (iconW != null && trailingIcon) ...[const SizedBox(width: 8), iconW],
      ],
    );
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: style == OButtonStyle.outline
              ? BorderSide(color: (outlineColor ?? OC.text).withValues(alpha: 0.4))
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: expand ? Alignment.center : null,
            child: expand ? content : Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}

/// Rounded selectable chip ("Week 1 · The Vine ▾", "Full text", stances…).
class OPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color selectedBg;
  final Color selectedFg;
  final Color bg;
  final Color fg;
  final Color? border;
  final bool chevron;
  final double fontSize;

  const OPill(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.selectedBg = OC.accent,
    this.selectedFg = OC.n100,
    this.bg = OC.n100,
    this.fg = OC.text,
    this.border,
    this.chevron = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final b = selected ? selectedBg : bg;
    final f = selected ? selectedFg : fg;
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: b,
        shape: StadiumBorder(side: border != null && !selected ? BorderSide(color: border!) : BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: OT.body(size: fontSize, color: f, weight: FontWeight.w600, height: 1.2)),
                if (chevron) ...[const SizedBox(width: 4), OIcon(OI.down, size: 15, color: f)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paper card.
class OCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? shadow;

  const OCard({
    super.key,
    required this.child,
    this.color = OC.n100,
    this.padding = const EdgeInsets.all(20),
    this.radius = ORadius.card,
    this.onTap,
    this.border,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: box),
    );
  }
}

/// Sage toggle from the design.
class OToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;
  const OToggle({super.key, required this.value, required this.onChanged, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? OC.s500 : OC.n400,
            borderRadius: BorderRadius.circular(ORadius.pill),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: OC.n100, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// Letter avatar (P, S, D…).
class OAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color bg;
  final Color fg;
  const OAvatar(this.name, {super.key, this.size = 48, this.bg = OC.a200, this.fg = OC.a800});

  static const _palette = [OC.a200, OC.s300, OC.n300, OC.a300, OC.s200];

  /// Stable colour per name, as in the design's streak family.
  factory OAvatar.auto(String name, {double size = 48}) =>
      OAvatar(name, size: size, bg: _palette[name.isEmpty ? 0 : name.codeUnitAt(0) % _palette.length], fg: OC.text);

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(letter, style: OT.display(size * 0.42, color: fg)),
    );
  }
}

/// The large soft circles that sit in the corner of hero cards & screens.
class ODecor extends StatelessWidget {
  final Color big;
  final Color small;
  final double bigSize;
  final Offset bigOffset; // from top-right
  final Offset smallOffset;
  final double smallSize;
  const ODecor({
    super.key,
    required this.big,
    required this.small,
    this.bigSize = 220,
    this.bigOffset = const Offset(-50, -70),
    this.smallOffset = const Offset(40, 60),
    this.smallSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: bigOffset.dy,
            right: bigOffset.dx,
            child: Container(width: bigSize, height: bigSize, decoration: BoxDecoration(color: big, shape: BoxShape.circle)),
          ),
          Positioned(
            top: smallOffset.dy,
            right: smallOffset.dx,
            child: Container(width: smallSize, height: smallSize, decoration: BoxDecoration(color: small, shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

/// Filled text field in the design's style.
class OInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final Color fill;
  final Color ink;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final bool autofocus;
  final double radius;

  const OInput({
    super.key,
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.fill = OC.n100,
    this.ink = OC.text,
    this.style,
    this.keyboardType,
    this.autofocus = false,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: style ?? OT.body(size: 16, color: ink),
      cursorColor: OC.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: (style ?? OT.body(size: 16)).copyWith(color: ink.withValues(alpha: 0.4)),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Opens an Organic bottom sheet (parchment, 40px top radius, grab handle).
Future<T?> showOSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  Color background = OC.bg,
  bool scrollable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: OC.n900.withValues(alpha: 0.45),
    builder: (ctx) {
      final inner = Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: OC.n400, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Flexible(child: builder(ctx)),
          ],
        ),
      );
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: SafeArea(top: false, child: inner),
      );
    },
  );
}

/// Small rounded tag ("Answered", "Day 2 · Roots").
class OTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const OTag(this.label, {super.key, this.bg = OC.n200, this.fg = OC.n800});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: OT.body(size: 12, color: fg, weight: FontWeight.w700, height: 1.2)),
      );
}

/// Row of page dots (● ● ▬).
class ODots extends StatelessWidget {
  final int count;
  final int index;
  final Color active;
  final Color inactive;
  const ODots({super.key, required this.count, required this.index, required this.active, required this.inactive});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final on = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(right: 6),
            width: on ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(color: on ? active : inactive, borderRadius: BorderRadius.circular(4)),
          );
        }),
      );
}

/// Dashed circle painter for future/locked rhythm seeds.
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const DashedCirclePainter({required this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - strokeWidth;
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const dashes = 22;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter old) => old.color != color;
}
