import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

class ValleyScreen extends StatefulWidget {
  const ValleyScreen({super.key});

  @override
  State<ValleyScreen> createState() => _ValleyScreenState();
}

class _ValleyScreenState extends State<ValleyScreen> {
  int _selectedRoomIndex = 0;

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
        'author': 'Pilgrim in Austin',
        'fixedPhrase': 'The Lord is near to the brokenhearted',
        'body': 'Lost my father three weeks ago. Sitting in Psalm 34 today. Just knowing I don’t have to perform faith right now is carrying me.',
        'time': '3 hours ago',
      },
      {
        'author': 'Brother in Nairobi',
        'fixedPhrase': 'Even though I walk through the valley',
        'body': 'I thought weeping was a sign of weak faith. The Psalms taught me that lament is worship.',
        'time': 'Yesterday',
      },
    ],
    [
      {
        'author': 'Sister in London',
        'fixedPhrase': 'Not by might, nor by power, but by my Spirit',
        'body': 'Facing severe restructuring at work. Choosing not to gossip or spiral into panic, but resting as a branch in Christ.',
        'time': '5 hours ago',
      },
    ],
    [
      {
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
                'Posts are anonymous and covenant-moderated for peace.',
                style: LogosTypography.caption(color: LogosColors.ink.withValues(alpha: 0.6)),
              ),
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
                      'author': 'Pilgrim (You)',
                      'fixedPhrase': selectedPhrase,
                      'body': text,
                      'time': 'Just now',
                    });
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Post to Sanctuary Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final posts = _postsByRoom[_selectedRoomIndex];

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('In the Valley', style: TextStyle(color: LogosColors.valleyRooms, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Themed Quiet Rooms', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LogosColors.valleyRooms,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note),
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                itemCount: posts.length,
                itemBuilder: (context, idx) {
                  final p = posts[idx];
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
                            Text(p['author']!, style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
                            Text(p['time']!, style: LogosTypography.caption(color: ink.withValues(alpha: 0.4))),
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Covenant Protected · Pastoral Oversight',
                              style: TextStyle(fontSize: 10, color: Colors.green.shade800),
                            ),
                          ],
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
