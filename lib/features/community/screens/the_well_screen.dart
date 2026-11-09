import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/pilgrim_name.dart';
import '../data/community_repository.dart';
import '../models/community_prayer.dart';
import '../widgets/crisis_notice.dart';
import '../widgets/room_header.dart';

const _room = 'the_well';
const _followUpPrefix = 'Follow-up · ';

bool _isFollowUp(CommunityPrayer p) => p.title.startsWith(_followUpPrefix);

/// The Well — private prayer requests read by the pastoral team.
class TheWellScreen extends StatefulWidget {
  const TheWellScreen({super.key});

  @override
  State<TheWellScreen> createState() => _TheWellScreenState();
}

class _TheWellScreenState extends State<TheWellScreen> {
  final _request = TextEditingController();
  final _repo = CommunityRepository();
  bool _sending = false;

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _request.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.submitPrayer(room: _room, title: 'Prayer request', content: text, authorName: pilgrimName(context));
      _request.clear();
      AudioService().playAmenChime();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Received. Our pastoral team will pray for you.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.sage;
    return OScreen(
      atmosphere: atm,
      child: StreamBuilder<List<CommunityPrayer>>(
        stream: _repo.watchPrayers(room: _room),
        builder: (context, snap) {
          final all = snap.data ?? const <CommunityPrayer>[];
          final requests = all.where((p) => !_isFollowUp(p)).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const RoomHeader(
                atmosphere: atm,
                kicker: 'Pastoral care',
                title: 'The Well',
                subtitle: 'Bring what you carry. Our pastoral team reads every request and prays for you.',
                kickerColor: OC.s800,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OCard(
                      radius: 28,
                      shadow: OShadow.sm,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('PRAYER REQUEST', style: OT.kicker(color: OC.s700)),
                          TextField(
                            controller: _request,
                            minLines: 4,
                            maxLines: 8,
                            textCapitalization: TextCapitalization.sentences,
                            style: OT.body(size: 16),
                            cursorColor: OC.s700,
                            decoration: InputDecoration(
                              hintText: 'Share whatever burden, doubt, or sorrow is weighing on you…',
                              hintStyle: OT.body(size: 16, color: OC.text.withValues(alpha: 0.4)),
                              border: InputBorder.none,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('Seen only by our pastoral team', style: OT.small(alpha: 0.65))),
                              OButton(_sending ? 'Sending…' : 'Bring to The Well',
                                  style: OButtonStyle.sage, expand: false, height: 46, onPressed: _sending ? null : _send),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const CrisisNotice(),
                    const SizedBox(height: 26),
                    Text('Your requests', style: OT.display(25, color: OC.s900)),
                    const SizedBox(height: 12),
                    if (requests.isEmpty)
                      Text('Requests you bring will rest here, with any reply from your pastor.', style: OT.small(color: OC.s900))
                    else
                      for (final p in requests) ...[
                        _RequestCard(prayer: p, onTap: () => _openThread(p)),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openThread(CommunityPrayer p) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => WellThreadScreen(request: p)));
}

class _RequestCard extends StatelessWidget {
  final CommunityPrayer prayer;
  final VoidCallback onTap;
  const _RequestCard({required this.prayer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final replied = prayer.pastorResponse != null && prayer.pastorResponse!.isNotEmpty;
    return OCard(
      radius: 28,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OTag(replied ? 'Replied' : 'Being prayed for', bg: replied ? OC.s200 : OC.n200, fg: replied ? OC.s900 : OC.n800),
              const Spacer(),
              Text(formatLogosDate(prayer.createdAt), style: OT.small(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 10),
          Text(prayer.content, style: OT.body(size: 16)),
          if (replied) ...[
            const SizedBox(height: 12),
            OCard(
              color: OC.s100,
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${prayer.pastorName ?? 'Your pastor'} replied', style: OT.label(size: 13, color: OC.s800)),
                  const SizedBox(height: 6),
                  Text(prayer.pastorResponse!, style: OT.display(18, color: OC.s900, height: 1.3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A request and its replies, as a quiet conversation.
class WellThreadScreen extends StatefulWidget {
  final CommunityPrayer request;
  const WellThreadScreen({super.key, required this.request});

  @override
  State<WellThreadScreen> createState() => _WellThreadScreenState();
}

class _WellThreadScreenState extends State<WellThreadScreen> {
  final _draft = TextEditingController();
  final _repo = CommunityRepository();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    _draft.clear();
    await _repo.submitPrayer(
      room: _room,
      title: '$_followUpPrefix${widget.request.id}',
      content: text,
      authorName: pilgrimName(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.sage;
    final r = widget.request;
    final pastor = r.pastorName ?? 'Pastoral team';
    return OScreen(
      atmosphere: atm,
      bottom: Row(
        children: [
          Expanded(
            child: OInput(controller: _draft, hint: 'Write to your pastor…', radius: 999, maxLines: 4),
          ),
          const SizedBox(width: 10),
          OCircleButton(icon: OI.send, tooltip: 'Send', background: OC.s700, foreground: OC.s100, size: 52, onTap: _send),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
            child: Row(
              children: [
                OCircleButton(
                  icon: OI.back,
                  tooltip: 'Back',
                  background: OC.s200,
                  foreground: OC.s900,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(pastor, style: OT.display(21, color: OC.s900)),
                      Text('The Well · replies appear here', style: OT.small(color: OC.s900)),
                    ],
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CommunityPrayer>>(
              stream: _repo.watchPrayers(room: _room),
              builder: (context, snap) {
                final followUps = (snap.data ?? const <CommunityPrayer>[])
                    .where((p) => p.title == '$_followUpPrefix${r.id}')
                    .toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
                  children: [
                    const CrisisNotice(compact: true),
                    const SizedBox(height: 16),
                    _Bubble(text: r.content, mine: true),
                    if (r.pastorResponse?.isNotEmpty == true) _Bubble(text: r.pastorResponse!, mine: false, author: pastor),
                    for (final f in followUps) _Bubble(text: f.content, mine: true),
                    if (r.pastorResponse?.isNotEmpty != true)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text('Your pastor’s reply will appear here.', textAlign: TextAlign.center, style: OT.small(color: OC.s900)),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool mine;
  final String? author;
  const _Bubble({required this.text, required this.mine, this.author});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: mine ? OC.s700 : OC.n100,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (author != null) ...[
              Text(author!, style: OT.label(size: 13, color: OC.s800)),
              const SizedBox(height: 4),
            ],
            Text(text, style: OT.body(size: 16, color: mine ? OC.s100 : OC.text)),
          ],
        ),
      ),
    );
  }
}
