import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/design/share_card.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_state.dart';
import '../journey/data/week_design.dart';
import '../journey/models/scripture_drop.dart';

/// Shown when a week's four days are kept.
class RecapScreen extends StatelessWidget {
  final ScriptureDrop drop;
  const RecapScreen({super.key, required this.drop});

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.ember;
    final design = weekDesignFor(drop.weekNumber);
    final root = design.roots.length > 1 ? design.roots[1] : design.roots.first;
    final rootParts = root.transliteration.split(' · ');

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, s) {
        final kept = s.dayCompletionStatus.values.where((d) => d).length;
        final score = s.weekBestScore;
        return OScreen(
          atmosphere: atm,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OButton('Share this week', style: OButtonStyle.light, onPressed: () {
                shareCardImage(
                  context,
                  ShareCard(
                    kicker: 'Week ${drop.weekNumber} kept · ${drop.reference}',
                    verse: drop.verseText,
                    reference: '${drop.reference} · ${drop.translation}',
                    closing: design.rest,
                  ),
                  fallbackText: 'This week I carried ${drop.reference} by heart.\n\n“${drop.verseText}”\n\n${design.rest}\n— LOGOS IN ME',
                );
              }),
              const SizedBox(height: 10),
              OButton('Return to Today',
                  style: OButtonStyle.outline,
                  outlineColor: OC.a300,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
            ],
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: ODecor(big: OC.a600, small: OC.a500, bigSize: 260, bigOffset: Offset(-90, -90), smallOffset: Offset(70, 150), smallSize: 54),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                children: [
                  Text('WEEK ${drop.weekNumber} KEPT · ${drop.reference.toUpperCase()}', style: OT.kicker(color: OC.a200)),
                  const SizedBox(height: 12),
                  Text(design.rest, style: OT.display(44, color: OC.n100, height: 1.05)),
                  const SizedBox(height: 22),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _stat(score > 0 ? '${(score * 100).round()}%' : '—', 'spoken by heart'),
                      _stat('$kept / 4', 'days kept'),
                      _stat(s.dayCompletionStatus[3] == true ? '1 min' : '—', 'of stillness'),
                      _stat('${s.rootsPlanted}', 'roots planted'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OCard(
                    color: OC.s700,
                    radius: 28,
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR ROOT WORD', style: OT.kicker(color: OC.s200)),
                        const SizedBox(height: 8),
                        Text(rootParts.first, style: OT.display(32, color: OC.s100)),
                        Text.rich(TextSpan(children: [
                          if (rootParts.length > 1) TextSpan(text: '${rootParts[1]} · ', style: OT.display(18, color: OC.s200, height: 1.3)),
                          TextSpan(text: root.original, style: OT.original(size: 18, color: OC.s200)),
                        ])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String value, String label) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: OC.a800, borderRadius: BorderRadius.circular(ORadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: OT.display(30, color: OC.n100))),
            const SizedBox(height: 6),
            Text(label, style: OT.small(color: OC.n100, alpha: 0.85)),
          ],
        ),
      );
}
