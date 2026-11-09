import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../data/community_repository.dart';
import '../data/moderation_store.dart';
import '../widgets/crisis_notice.dart';
import '../widgets/room_header.dart';

const _rooms = [
  ('Grief in the Psalms', 'Meditating on God’s nearness to the crushed in spirit.'),
  ('Corporate Workplace', 'Kingdom calm amidst deadlines and ethical stress.'),
  ('Digital Fatigue', 'Silence against algorithm fatigue and comparison.'),
];

const _phrases = [
  'The Lord is near to the brokenhearted',
  'Even though I walk through the valley',
  'Be still, and know that I am God',
  'My soul finds rest in God alone',
];

class _Post {
  final String id;
  final int room;
  final String author;
  final String anchor;
  final String body;
  int candles;
  final bool sample;
  bool lit = false;
  _Post(this.id, this.room, this.author, this.anchor, this.body, this.candles, {this.sample = false});
}

/// In the Valley — anonymous rooms for lament.
class ValleyScreen extends StatefulWidget {
  const ValleyScreen({super.key});

  @override
  State<ValleyScreen> createState() => _ValleyScreenState();
}

class _ValleyScreenState extends State<ValleyScreen> {
  final _moderation = ModerationStore();
  Set<String> _hidden = {};
  int _room = 0;
  final List<_Post> _posts = [
    _Post('valley-sample-1', 0, 'Pilgrim in Austin', 'The Lord is near to the brokenhearted',
        'Three months since we lost Mom. I still set two cups out some mornings.', 14, sample: true),
    _Post('valley-sample-2', 0, 'Brother in Nairobi', 'Even though I walk through the valley',
        'I thought weeping was a sign of weak faith. The Psalms taught me that lament is worship.', 22, sample: true),
    _Post('valley-sample-3', 1, 'Sister in London', 'Be still, and know that I am God',
        'Facing restructuring at work. Choosing not to spiral, but to rest as a branch in Christ.', 9, sample: true),
    _Post('valley-sample-4', 2, 'Seeker in Toronto', 'My soul finds rest in God alone',
        'Uninstalled my feeds. The minute of stillness on Day 3 was the first true quiet in months.', 11, sample: true),
  ];

  @override
  void initState() {
    super.initState();
    _moderation.hiddenIds().then((ids) {
      if (mounted) setState(() => _hidden = ids);
    });
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _report(_Post p) async {
    var choice = 0;
    final reason = await showOSheet<String>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Report this post', style: OT.h2()),
            const SizedBox(height: 6),
            Text('Reports are anonymous. The post is hidden for you and sent for review.', style: OT.small()),
            const SizedBox(height: 16),
            for (var i = 0; i < reportReasons.length; i++) ...[
              _Radio(label: reportReasons[i], selected: i == choice, onTap: () => set(() => choice = i)),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            OButton('Submit report', style: OButtonStyle.dark, onPressed: () => Navigator.pop(ctx, reportReasons[choice])),
            TextButton(
              onPressed: () => Navigator.pop(ctx, '__hide__'),
              child: Text('Just hide it for me', style: OT.small(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
    if (reason == null) return;
    if (reason == '__hide__') {
      await _moderation.hide(p.id);
    } else {
      await _moderation.report(p.id, reason);
    }
    if (!mounted) return;
    setState(() => _hidden = {..._hidden, p.id});
    _toast(reason == '__hide__' ? 'Post hidden.' : 'Thank you. It’s hidden and will be reviewed.');
  }

  Future<void> _compose() async {
    final body = TextEditingController();
    var phrase = 0;
    final posted = await showOSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pour out your heart', style: OT.h2()),
              const SizedBox(height: 6),
              Text('Posts are anonymous. Please be gentle — posts that break our guidelines are removed.', style: OT.small()),
              const SizedBox(height: 14),
              Text('Anchor phrase', style: OT.label(size: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _phrases.length; i++)
                    OPill(_phrases[i], selected: i == phrase, fontSize: 13, onTap: () => set(() => phrase = i)),
                ],
              ),
              const SizedBox(height: 14),
              OInput(controller: body, hint: 'Share your contemplation with this room…', minLines: 4, maxLines: 6, radius: 24),
              const SizedBox(height: 10),
              const CrisisNotice(compact: true),
              const SizedBox(height: 14),
              OButton('Post to the room', style: OButtonStyle.dark, onPressed: () {
                if (body.text.trim().isEmpty) return;
                setState(() => _posts.insert(
                      0,
                      _Post('valley-own-${DateTime.now().millisecondsSinceEpoch}', _room, 'You', _phrases[phrase], body.text.trim(), 0),
                    ));
                CommunityRepository().submitPrayer(room: 'valley', title: _phrases[phrase], content: body.text.trim(), authorName: 'Pilgrim');
                Navigator.pop(ctx, true);
              }),
            ],
          ),
        ),
      ),
    );
    if (posted == true) _toast('Posted anonymously to ${_rooms[_room].$1}.');
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.dusk;
    final posts = _posts.where((p) => p.room == _room && !_hidden.contains(p.id)).toList();
    return OScreen(
      atmosphere: atm,
      bottom: OButton('Leave a word in this room', style: OButtonStyle.light, onPressed: _compose),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const RoomHeader(
            atmosphere: atm,
            kicker: 'Quiet rooms',
            title: 'In the Valley',
            subtitle: 'Rooms for lament. Anonymous and gently moderated.',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => OPill(_rooms[i].$1,
                  selected: i == _room,
                  selectedBg: OC.n100,
                  selectedFg: OC.text,
                  bg: OC.n800,
                  fg: OC.n100,
                  onTap: () => setState(() => _room = i)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_rooms[_room].$2, style: OT.small(color: OC.n100, alpha: 0.7)),
                const SizedBox(height: 16),
                if (posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('This room is quiet. Leave the first word.', textAlign: TextAlign.center, style: OT.small(color: OC.n100)),
                  ),
                for (final p in posts) ...[_PostCard(post: p, onReport: () => _report(p), onCandle: () => _candle(p)), const SizedBox(height: 14)],
                const CrisisNotice(dark: true, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _candle(_Post p) {
    if (p.lit) return;
    setState(() {
      p.lit = true;
      p.candles++;
    });
    if (!p.sample) CommunityRepository().prayFor(room: 'valley', prayerId: p.id);
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  final VoidCallback onReport;
  final VoidCallback onCandle;
  const _PostCard({required this.post, required this.onReport, required this.onCandle});

  @override
  Widget build(BuildContext context) {
    return OCard(
      color: OC.n800,
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('“${post.anchor}”', style: OT.display(20, color: OC.a300, height: 1.2)),
          const SizedBox(height: 10),
          Text(post.body, style: OT.body(size: 16, color: OC.n100)),
          const SizedBox(height: 14),
          Row(
            children: [
              Flexible(
                child: Text('${post.author}${post.sample ? ' · Example' : ''}',
                    style: OT.small(color: OC.n100, alpha: 0.6)),
              ),
              if (post.author != 'You') ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onReport,
                  child: Text('Report',
                      style: OT.small(color: OC.n100, alpha: 0.6).copyWith(decoration: TextDecoration.underline)),
                ),
              ],
              const Spacer(),
              Semantics(
                button: true,
                label: 'Light a candle, ${post.candles} lit',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onCandle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: post.lit ? OC.a700 : OC.n700,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OIcon(OI.flame, size: 14, color: post.lit ? OC.a200 : OC.n100),
                        const SizedBox(width: 6),
                        Text('${post.candles}', style: OT.label(size: 13, color: OC.n100)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Radio({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: OCard(
          onTap: onTap,
          radius: 999,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: Border.all(color: selected ? OC.accent : Colors.transparent, width: 1.6),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? OC.accent : OC.n500, width: 2),
                ),
                child: selected
                    ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: OC.accent, shape: BoxShape.circle)))
                    : null,
              ),
              const SizedBox(width: 12),
              Text(label, style: OT.label(size: 15)),
            ],
          ),
        ),
      );
}
