import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/utils/pilgrim_name.dart';
import '../widgets/room_header.dart';

/// Study Pods — four pilgrims, one verse, every Thursday.
/// (Behind the `room_study_pods` flag until pods sync with the cloud.)
class StudyPodsScreen extends StatefulWidget {
  const StudyPodsScreen({super.key});

  @override
  State<StudyPodsScreen> createState() => _StudyPodsScreenState();
}

class _StudyPodsScreenState extends State<StudyPodsScreen> {
  final _draft = TextEditingController();
  final _reflections = <(String, String, String)>[
    ('David M.', 'Yesterday at 9:15 PM', 'Dry seasons used to feel like failure. A branch in winter is still attached.'),
    ('Sarah K.', 'Today at 7:30 AM', 'I’ve stopped asking for more fruit and started asking to stay close.'),
  ];

  static const _pod = [
    ('David M.', 'Day 2 · Studying context'),
    ('Sarah K.', 'Day 3 · Stillness'),
    ('Hannah L.', 'Day 1 · Encounter'),
  ];

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.parchment;
    return OScreen(
      atmosphere: atm,
      bottom: Row(
        children: [
          Expanded(child: OInput(controller: _draft, hint: 'Share a thought with your pod…', radius: 999)),
          const SizedBox(width: 10),
          OCircleButton(
            icon: OI.send,
            tooltip: 'Send',
            background: OC.accent,
            foreground: OC.n100,
            size: 52,
            onTap: () {
              final t = _draft.text.trim();
              if (t.isEmpty) return;
              setState(() => _reflections.add((pilgrimName(context), 'Just now', t)));
              _draft.clear();
            },
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const RoomHeader(atmosphere: atm, kicker: 'Community', title: 'Study Pods', subtitle: 'Four pilgrims. One verse. Every Thursday.', kickerColor: OC.a700),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OCard(
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THU 8:00 PM', style: OT.kicker()),
                      const SizedBox(height: 8),
                      Text('Abiding in the Vine', style: OT.display(26)),
                      const SizedBox(height: 6),
                      Text('Walking through John 15 together with quiet contemplation and peer support.', style: OT.small(alpha: 0.8)),
                      const SizedBox(height: 14),
                      OButton('Remind me Thursday', expand: false, height: 44, onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We’ll remind you on Thursday.')));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('Pod family', style: OT.label(size: 15)),
                const SizedBox(height: 10),
                _member(pilgrimName(context), 'You', OC.a200),
                for (final m in _pod) _member(m.$1, m.$2, null),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    color: OC.s700,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: ODecor(big: OC.s600, small: Colors.transparent, bigSize: 140, bigOffset: Offset(-40, 80), smallSize: 0)),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('THIS WEEK’S QUESTION', style: OT.kicker(color: OC.s200)),
                              const SizedBox(height: 8),
                              Text('How does knowing Jesus is the True Vine reshape your prayers during dry seasons?',
                                  style: OT.display(21, color: OC.s100, height: 1.2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Shared reflections', style: OT.label(size: 15)),
                const SizedBox(height: 10),
                for (final r in _reflections) ...[
                  OCard(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${r.$1} · ${r.$2}', style: OT.label(size: 13, color: OC.n700)),
                        const SizedBox(height: 4),
                        Text(r.$3, style: OT.body(size: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _member(String name, String status, Color? bg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            bg == null ? OAvatar.auto(name, size: 44) : OAvatar(name, size: 44, bg: bg, fg: OC.a800),
            const SizedBox(width: 12),
            Expanded(child: Text(status == 'You' ? 'You' : name, style: OT.label(size: 15))),
            OTag(status == 'You' ? 'Your rhythm' : status, bg: OC.surface, fg: OC.text),
          ],
        ),
      );
}
