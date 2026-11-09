import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/theme/logos_icons.dart';
import '../data/community_repository.dart';
import '../data/moderation_store.dart';
import '../widgets/crisis_notice.dart';

class ValleyScreen extends StatefulWidget {
  const ValleyScreen({super.key});

  @override
  State<ValleyScreen> createState() => _ValleyScreenState();
}

class _ValleyScreenState extends State<ValleyScreen> {
  int _selectedRoomIndex = 0;
  final ModerationStore _moderation = ModerationStore();
  Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _moderation.hiddenIds().then((ids) {
      if (mounted) setState(() => _hidden = ids);
    });
  }

  Future<void> _hidePost(String id) async {
    await _moderation.hide(id);
    if (!mounted) return;
    setState(() => _hidden = {..._hidden, id});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post hidden.')));
  }

  Future<void> _reportPost(String id) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Why are you reporting this?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            for (final r in reportReasons)
              ListTile(title: Text(r), onTap: () => Navigator.pop(ctx, r)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await _moderation.report(id, reason);
    if (!mounted) return;
    setState(() => _hidden = {..._hidden, id});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Thank you. The post is hidden and will be reviewed.'),
    ));
  }

  final List<Map<String, String>> _rooms = [
    {
      'title': 'Grief in the Psalms',
      'desc': 'Meditating on God’s nearness to the crushed in spirit.',
    },
    {
      'title': 'Corporate Workplace',
      'desc': 'Kingdom calm amidst deadlines and ethical stress.',
    },
    {
      'title': 'Digital Fatigue',
      'desc': 'Silence against algorithm fatigue and comparison.',
    },
  ];

  final List<List<Map<String, String>>> _postsByRoom = [
    [
      {
        'id': 'valley-sample-1',
        'isSample': 'true',
        'author': 'Pilgrim in Austin',
        'fixedPhrase': 'The Lord is near to the brokenhearted',
        'body': 'Lost my father three weeks ago. Sitting in Psalm 34 today. Just knowing I don’t have to perform faith right now is carrying me.',
        'time': '3 hours ago',
      },
      {
        'id': 'valley-sample-2',
        'isSample': 'true',
        'author': 'Brother in Nairobi',
        'fixedPhrase': 'Even though I walk through the valley',
        'body': 'I thought weeping was a sign of weak faith. The Psalms taught me that lament is worship.',
        'time': 'Yesterday',
      },
    ],
    [
      {
        'id': 'valley-sample-3',
        'isSample': 'true',
        'author': 'Sister in London',
        'fixedPhrase': 'Not by might, nor by power, but by my Spirit',
        'body': 'Facing severe restructuring at work. Choosing not to gossip or spiral into panic, but resting as a branch in Christ.',
        'time': '5 hours ago',
      },
    ],
    [
      {
        'id': 'valley-sample-4',
        'isSample': 'true',
        'author': 'Seeker in Toronto',
        'fixedPhrase': 'Be still, and know that I am God',
        'body': 'Uninstalled all feeds. The 60-second stillness in Day 3 was the first true silence my mind has felt in months.',
        'time': '1 day ago',
      },
    ],
  ];

  void _showComposeDialog(BuildContext context) {
    final bodyController = TextEditingController();
    String selectedPhrase = 'The Lord is near to the brokenhearted';
    final phrases = [
      'The Lord is near to the brokenhearted',
      'Even though I walk through the valley',
      'Be still, and know that I am God',
      'My soul finds rest in God alone',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pour Out Your Heart', style: LogosTypography.headline(color: LogosColors.ink)),
              const SizedBox(height: 6),
              Text(
                'Posts are anonymous. Please be gentle — posts that break our community guidelines are removed.',
                style: LogosTypography.caption(color: LogosColors.ink.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 12),
              const CrisisNotice(compact: true),
              const SizedBox(height: 14),
              const Text('Anchor Scripture Phrase:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedPhrase,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: phrases.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedPhrase = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your contemplation with this valley room...',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LogosColors.valleyRooms,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final text = bodyController.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    _postsByRoom[_selectedRoomIndex].insert(0, {
                      'id': 'valley-own-${DateTime.now().millisecondsSinceEpoch}',
                      'author': 'You',
                      'fixedPhrase': selectedPhrase,
                      'body': text,
                      'time': 'Just now',
                    });
                  });
                  CommunityRepository().submitPrayer(
                    room: 'valley',
                    title: selectedPhrase,
                    content: text,
                    authorName: 'Pilgrim',
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Post anonymously', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;
    final posts = _postsByRoom[_selectedRoomIndex].where((p) => !_hidden.contains(p['id'])).toList();

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: AppIcon(LogosIcons.arrowBack, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('In the Valley', style: TextStyle(color: LogosColors.valleyRooms, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Quiet rooms of lament', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LogosColors.valleyRooms,
        foregroundColor: Colors.white,
        icon: const AppIcon(LogosIcons.editNote),
        label: const Text('Leave a Word'),
        onPressed: () => _showComposeDialog(context),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Room Selection Tabs
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _rooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final r = _rooms[i];
                  final isSelected = _selectedRoomIndex == i;
                  return ChoiceChip(
                    label: Text(r['title']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : ink)),
                    selected: isSelected,
                    selectedColor: LogosColors.valleyRooms,
                    backgroundColor: surface,
                    side: BorderSide(color: isSelected ? LogosColors.valleyRooms : LogosColors.taupe),
                    onSelected: (val) {
                      if (val) setState(() => _selectedRoomIndex = i);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Description bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LogosColors.valleyRooms.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _rooms[_selectedRoomIndex]['desc']!,
                  style: LogosTypography.caption(color: ink.withValues(alpha: 0.8)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                itemCount: posts.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == posts.length) {
                    return const Padding(padding: EdgeInsets.only(top: 6), child: CrisisNotice(compact: true));
                  }
                  final p = posts[idx];
                  final isSample = p['isSample'] == 'true';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LogosColors.taupe),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isSample ? '${p['author']!} · Example' : p['author']!,
                                style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                              ),
                            ),
                            Text(p['time']!, style: LogosTypography.caption(color: ink.withValues(alpha: 0.4))),
                            if (p['author'] != 'You')
                              PopupMenuButton<String>(
                                tooltip: 'Post options',
                                icon: AppIcon(LogosIcons.more, size: 18, color: ink.withValues(alpha: 0.5)),
                                onSelected: (v) => v == 'hide' ? _hidePost(p['id']!) : _reportPost(p['id']!),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'report', child: Text('Report post')),
                                  PopupMenuItem(value: 'hide', child: Text('Hide post')),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LogosColors.valleyRooms.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['fixedPhrase']!,
                            style: const TextStyle(
                              color: LogosColors.valleyRooms,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p['body']!,
                          style: LogosTypography.body(color: ink).copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
