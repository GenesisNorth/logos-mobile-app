import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/logos_icons.dart';
import '../../core/theme/logos_theme.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color ink;
  const SettingsSection(this.title, {super.key, required this.children, required this.ink});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(title.toUpperCase(),
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: ink.withValues(alpha: 0.55))),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? LogosColors.examenSurface : LogosColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LogosColors.taupe),
            ),
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 52, color: LogosColors.taupe.withValues(alpha: 0.7)),
                children[i],
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final LogosIconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;
  final Color ink;
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.ink,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : ink;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AppIcon(icon, size: 22, color: destructive ? color : LogosColors.coral),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: GoogleFonts.inter(fontSize: 13, color: ink.withValues(alpha: 0.6))),
                  ],
                  if (below != null) ...[const SizedBox(height: 10), below!],
                ],
              ),
            ),
            if (trailing != null) trailing! else if (onTap != null)
              AppIcon(LogosIcons.chevronRight, size: 18, color: ink.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}
