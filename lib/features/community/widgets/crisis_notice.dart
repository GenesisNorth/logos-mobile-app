import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_flags.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/theme/logos_theme.dart';

/// Shown wherever people may share grief or distress. Crisis numbers come from
/// remote config so the admin can localise them per country.
class CrisisNotice extends StatelessWidget {
  final bool compact;
  const CrisisNotice({super.key, this.compact = false});

  Future<void> _open(BuildContext context, String uri) async {
    if (uri.isEmpty) return;
    final ok = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final flags = AppFlags.instance;
    final lineLabel = flags.text(AppFlags.crisisLineLabel);
    final lineUri = flags.text(AppFlags.crisisLineUri);
    final directory = flags.text(AppFlags.crisisDirectoryUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.16 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(LogosIcons.alert, size: 18, color: Color(0xFFB91C1C)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  compact
                      ? 'Not an emergency service. If you are in danger or thinking of harming yourself, get help now.'
                      : 'This is a place of prayer, not an emergency service. If you are in danger or thinking about harming yourself, please contact local emergency services or a crisis line now.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: ink.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: [
              if (lineUri.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const AppIcon(LogosIcons.phoneCall, size: 16, color: Color(0xFFB91C1C)),
                  label: Text(lineLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: () => _open(context, lineUri),
                ),
              if (directory.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _open(context, directory),
                  child: Text('Find a helpline in your country',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
