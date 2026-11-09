import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../data/bible_translations.dart';

/// Copyright and licence notices for every translation offered in the app.
class TranslationNoticesScreen extends StatelessWidget {
  const TranslationNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.parchment;
    return OScreen(
      atmosphere: atm,
      child: Column(
        children: [
          const OTopBar(kicker: 'Translation notices', atmosphere: atm, back: true),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
              itemCount: bibleTranslations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = bibleTranslations[i];
                return OCard(
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t.name} (${t.key})', style: OT.label(size: 15)),
                      const SizedBox(height: 6),
                      Text(t.notice, style: OT.small(alpha: 0.75)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
