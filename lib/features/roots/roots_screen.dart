import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/audio_service.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/data/week_design.dart';
import '../journey/models/scripture_drop.dart';

/// Day 2 — Roots: the original words, one reading at a time.
class RootsScreen extends StatefulWidget {
  final ScriptureDrop drop;
  const RootsScreen({super.key, required this.drop});

  @override
  State<RootsScreen> createState() => _RootsScreenState();
}

class _RootsScreenState extends State<RootsScreen> {
  late final WeekDesign _design = weekDesignFor(widget.drop.weekNumber);
  final _pager = PageController();
  int _index = 0;

  List<RootReading> get _roots => _design.roots;
  bool get _last => _index >= _roots.length - 1;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _go(int i) {
    HapticFeedback.selectionClick();
    _pager.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _complete() {
    AudioService().playAmenChime();
    context.read<JourneyBloc>().add(const CompleteDay(2));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.sage;
    return OScreen(
      atmosphere: atm,
      bottom: Row(
        children: [
          ODots(count: _roots.length, index: _index, active: OC.s700, inactive: OC.s300),
          const Spacer(),
          if (_index > 0) ...[
            Material(
              color: Colors.transparent,
              shape: CircleBorder(side: BorderSide(color: OC.s700.withValues(alpha: 0.35))),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _go(_index - 1),
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Center(child: OIcon(OI.back, size: 20, color: OC.s900)),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          OButton(
            _last ? 'Complete Day 2' : 'Next reading',
            style: OButtonStyle.sage,
            expand: false,
            icon: OI.next,
            trailingIcon: true,
            onPressed: _last ? _complete : () => _go(_index + 1),
          ),
        ],
      ),
      child: Column(
        children: [
          OTopBar(
            kicker: 'Day 2 · Roots',
            atmosphere: atm,
            trailing: Text('${_index + 1}/${_roots.length}', style: OT.label(size: 15, color: OC.s900)),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pager,
              itemCount: _roots.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _RootPage(root: _roots[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RootPage extends StatelessWidget {
  final RootReading root;
  const _RootPage({required this.root});

  @override
  Widget build(BuildContext context) {
    final parts = root.transliteration.split(' · ');
    final word = parts.first;
    final gloss = parts.length > 1 ? parts.sublist(1).join(' · ') : '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: double.infinity,
              height: 230,
              color: OC.s700,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ODecor(
                      big: OC.s600,
                      small: OC.s500,
                      bigSize: 280,
                      bigOffset: Offset(-90, 80),
                      smallOffset: Offset(40, 30),
                      smallSize: 40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(root.subtitle.toUpperCase(), style: OT.kicker(color: OC.s100.withValues(alpha: 0.85))),
                        const Spacer(),
                        Text(word, style: OT.display(48, color: OC.s100, height: 1.0)),
                        const SizedBox(height: 6),
                        Text.rich(TextSpan(children: [
                          if (gloss.isNotEmpty) TextSpan(text: '$gloss · ', style: OT.display(19, color: OC.s200, height: 1.3)),
                          TextSpan(text: root.original, style: OT.original(size: 19, color: OC.s200)),
                        ])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(root.title, style: OT.display(26, color: OC.s900)),
          const SizedBox(height: 10),
          Text(root.body, style: OT.body(size: 16, color: OC.s900, height: 1.65)),
        ],
      ),
    );
  }
}
