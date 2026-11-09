import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/theme/logos_theme.dart';
import '../data/bible_translations.dart';

/// Bottom sheet listing every Bible translation, grouped by reading style,
/// with a live preview of this week's verse. Reused by the home screen,
/// onboarding and settings.
Future<void> showTranslationPicker(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onSelected,
  Map<String, String>? previews,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _TranslationPicker(
      current: current,
      previews: previews,
      onSelected: (key) {
        HapticFeedback.selectionClick();
        Navigator.pop(ctx);
        onSelected(key);
      },
    ),
  );
}

class _TranslationPicker extends StatelessWidget {
  final String current;
  final Map<String, String>? previews;
  final ValueChanged<String> onSelected;

  const _TranslationPicker({required this.current, required this.onSelected, this.previews});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

    final available = bibleTranslations
        .where((t) => previews == null || previews!.containsKey(t.key))
        .toList();
    final children = <Widget>[];
    for (final style in TranslationStyle.values) {
      final group = available.where((t) => t.style == style).toList();
      if (group.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(
          style.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: ink.withValues(alpha: 0.55),
          ),
        ),
      ));
      for (final t in group) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TranslationTile(
            translation: t,
            preview: previews?[t.key],
            selected: t.key == current,
            ink: ink,
            onTap: () => onSelected(t.key),
          ),
        ));
      }
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: LogosColors.taupe),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Bible translation',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 2),
          Text(
            'You will read, hear and recite the verse in this translation.',
            style: GoogleFonts.inter(fontSize: 13, color: ink.withValues(alpha: 0.65)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: children,
            ),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TranslationNoticesScreen()),
                ),
                child: Text(
                  'Translation copyright notices',
                  style: GoogleFonts.inter(fontSize: 12, color: ink.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationTile extends StatelessWidget {
  final BibleTranslation translation;
  final String? preview;
  final bool selected;
  final Color ink;
  final VoidCallback onTap;

  const _TranslationTile({
    required this.translation,
    required this.preview,
    required this.selected,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${translation.name}${selected ? ', selected' : ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? LogosColors.coral.withValues(alpha: 0.08) : ink.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? LogosColors.coral : LogosColors.taupe.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? LogosColors.coral : ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  translation.key,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(translation.name,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 2),
                    Text(translation.description,
                        style: GoogleFonts.inter(fontSize: 12, color: ink.withValues(alpha: 0.65))),
                    if (preview != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '“$preview”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.newsreader(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: ink.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(
                selected ? LogosIcons.checkCircleRounded : LogosIcons.radioButtonUncheckedRounded,
                color: selected ? LogosColors.coral : ink.withValues(alpha: 0.35),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Copyright and licence notices for every translation offered in the app.
class TranslationNoticesScreen extends StatelessWidget {
  const TranslationNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    return Scaffold(
      appBar: AppBar(title: const Text('Translation notices')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: bibleTranslations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final t = bibleTranslations[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.name} (${t.key})',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 4),
              Text(t.notice, style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: ink.withValues(alpha: 0.75))),
            ],
          );
        },
      ),
    );
  }
}
