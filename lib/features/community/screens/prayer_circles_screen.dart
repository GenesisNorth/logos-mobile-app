import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/pilgrim_name.dart';
import '../data/community_repository.dart';
import '../data/voice_note_store.dart';
import '../widgets/room_header.dart';

const _stances = ['Praying with you', 'Standing in agreement', 'Lifting you before the Father', 'The peace of Christ guard you'];

class _Note {
  final String id;
  final String phrase;
  final String author;
  final int seconds;
  final String expires;
  final String? path;
  final bool sample;
  const _Note(this.id, this.phrase, this.author, this.seconds, this.expires, {this.path, this.sample = false});
}

/// Example prayers shown until circles sync with the cloud (no audio).
const _samples = [
  _Note('sample-1', 'Praying with you', 'Sarah K.', 24, 'Expires in 4 days', sample: true),
  _Note('sample-2', 'The peace of Christ guard you', 'David M.', 41, 'Expires in 5 days', sample: true),
  _Note('sample-3', 'Standing in agreement', 'Hannah L.', 18, 'Expires in 6 days', sample: true),
];

/// Prayer Circles — spoken prayers that fade after seven days.
class PrayerCirclesScreen extends StatefulWidget {
  const PrayerCirclesScreen({super.key});

  @override
  State<PrayerCirclesScreen> createState() => _PrayerCirclesScreenState();
}

class _PrayerCirclesScreenState extends State<PrayerCirclesScreen> {
  static const _maxSeconds = 120;
  final _store = VoiceNoteStore();
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  StreamSubscription<void>? _done;
  StreamSubscription<Duration>? _pos;
  Timer? _timer;

  int _stance = 0;
  bool _recording = false;
  bool _starting = false;
  int _seconds = 0;
  String? _path;
  List<LocalVoiceNote> _mine = [];
  String? _playing;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _store.load().then((n) {
      if (mounted) setState(() => _mine = n);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _done?.cancel();
    _pos?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  List<_Note> get _notes => [
        for (final n in _mine)
          _Note(n.id, n.phrase, '${n.authorName} (you)', n.durationSeconds, _expiry(n.createdAt), path: n.path),
        ..._samples,
      ];

  String _expiry(DateTime created) {
    final days = ((VoiceNoteStore.lifetime - DateTime.now().difference(created)).inMinutes / 1440).ceil();
    return days >= 1 ? 'Expires in $days day${days == 1 ? '' : 's'}' : 'Expires today';
  }

  Future<void> _startRecording() async {
    if (_recording || _starting) return;
    _starting = true;
    await _stopPlayback();
    final rec = _recorder ??= AudioRecorder();
    try {
      if (!await rec.hasPermission()) {
        _toast('Microphone access is needed to record a prayer.');
        return;
      }
      final path = await _store.newRecordingPath();
      await rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000), path: path);
      _path = path;
      HapticFeedback.mediumImpact();
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= _maxSeconds) _stopRecording();
      });
    } catch (_) {
      _toast('Could not start recording. Please try again.');
    } finally {
      _starting = false;
    }
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _timer?.cancel();
    final seconds = _seconds;
    String? path;
    try {
      path = await _recorder?.stop();
    } catch (_) {}
    path ??= _path;
    setState(() {
      _recording = false;
      _seconds = 0;
    });
    if (path == null || seconds < 1 || !File(path).existsSync()) {
      if (path != null && File(path).existsSync()) File(path).deleteSync();
      _toast('Hold the mic a little longer to record.');
      return;
    }
    if (!mounted) return;
    final author = pilgrimName(context);
    final note = LocalVoiceNote(
      id: const Uuid().v4(),
      path: path,
      phrase: _stances[_stance],
      authorName: author,
      durationSeconds: seconds,
      createdAt: DateTime.now(),
    );
    await _store.add(note);
    if (!mounted) return;
    setState(() => _mine = [note, ..._mine]);
    CommunityRepository().submitPrayer(
      room: 'prayer_circles',
      title: _stances[_stance],
      content: 'Voice prayer: “${_stances[_stance]}”',
      authorName: author,
    );
    AudioService().playAmenChime();
    _toast('Your prayer is with the circle for 7 days.');
  }

  Future<void> _stopPlayback() async {
    await _player?.stop();
    if (mounted) {
      setState(() {
        _playing = null;
        _progress = 0;
      });
    }
  }

  Future<void> _play(_Note n) async {
    if (n.sample) {
      _toast('Example prayer — circle voices will play once Prayer Circles go live.');
      return;
    }
    if (_playing == n.id) return _stopPlayback();
    final p = _player ??= AudioPlayer();
    _done ??= p.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = null;
          _progress = 0;
        });
      }
    });
    _pos ??= p.onPositionChanged.listen((d) {
      final n = _notes.where((x) => x.id == _playing).firstOrNull;
      if (n != null && mounted) setState(() => _progress = (d.inMilliseconds / (n.seconds * 1000)).clamp(0, 1));
    });
    try {
      await p.stop();
      await p.play(DeviceFileSource(n.path!));
      setState(() => _playing = n.id);
    } catch (_) {
      _toast('Could not play this prayer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.blush;
    return OScreen(
      atmosphere: atm,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const RoomHeader(
            atmosphere: atm,
            kicker: 'Community',
            title: 'Prayer Circles',
            subtitle: 'Voice prayers that fade after 7 days.',
            kickerColor: OC.a700,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CircleCard(onInvite: () => SharePlus.instance.share(ShareParams(
                      text: 'Pray with me on LOGOS IN ME — one verse a week, and a circle that prays together.',
                    ))),
                const SizedBox(height: 22),
                Text('Encouragement stance', style: OT.label(size: 15, color: OC.a900)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _stances.length; i++)
                      OPill(_stances[i],
                          selected: i == _stance, bg: OC.n100, fg: OC.text, fontSize: 13, onTap: () => setState(() => _stance = i)),
                  ],
                ),
                const SizedBox(height: 26),
                Center(child: _HoldMic(recording: _recording, onStart: _startRecording, onStop: _stopRecording)),
                const SizedBox(height: 12),
                Text(
                  _recording ? 'Recording… ${_seconds}s — release to share' : 'Hold to speak a prayer',
                  textAlign: TextAlign.center,
                  style: OT.label(size: 15, color: _recording ? OC.a600 : OC.a800),
                ),
                const SizedBox(height: 28),
                Text('Circle voice prayers', style: OT.display(25, color: OC.a900)),
                const SizedBox(height: 12),
                for (final n in _notes) ...[
                  _NoteRow(note: n, playing: _playing == n.id, progress: _playing == n.id ? _progress : 0, onPlay: () => _play(n)),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final VoidCallback onInvite;
  const _CircleCard({required this.onInvite});

  @override
  Widget build(BuildContext context) {
    const members = ['Sarah K.', 'David M.', 'Hannah L.', 'Grace E.'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        color: OC.a700,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ODecor(big: OC.a600, small: Colors.transparent, bigSize: 190, bigOffset: Offset(-50, -50), smallSize: 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR CIRCLE', style: OT.kicker(color: OC.a200)),
                  const SizedBox(height: 8),
                  Text('The Jerusalem Circle', style: OT.display(26, color: OC.n100)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 34.0 + 24 * (members.length - 1),
                        height: 36,
                        child: Stack(
                          children: [
                            for (var i = 0; i < members.length; i++)
                              Positioned(
                                left: i * 24.0,
                                child: Container(
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: OC.a700, width: 2)),
                                  child: OAvatar.auto(members[i], size: 34),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Example circle', style: OT.small(color: OC.n100, alpha: 0.85))),
                      OButton('Invite', style: OButtonStyle.light, expand: false, height: 40, onPressed: onInvite),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldMic extends StatelessWidget {
  final bool recording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  const _HoldMic({required this.recording, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: recording ? 'Stop and share prayer' : 'Record a voice prayer',
      hint: 'Press and hold to speak',
      onTap: recording ? onStop : onStart,
      excludeSemantics: true,
      child: GestureDetector(
        onLongPressStart: (_) => onStart(),
        onLongPressEnd: (_) => onStop(),
        onTap: recording ? onStop : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: recording ? 112 : 100,
          height: recording ? 112 : 100,
          decoration: BoxDecoration(
            color: recording ? OC.a600 : OC.accent,
            shape: BoxShape.circle,
            boxShadow: recording ? [BoxShadow(color: OC.a300.withValues(alpha: 0.8), spreadRadius: 12)] : OShadow.md,
          ),
          child: const Center(child: OIcon(OI.mic, size: 34, color: OC.n100)),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final _Note note;
  final bool playing;
  final double progress;
  final VoidCallback onPlay;
  const _NoteRow({required this.note, required this.playing, required this.progress, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final dur = '${note.seconds ~/ 60}:${(note.seconds % 60).toString().padLeft(2, '0')}';
    return OCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: playing ? 'Pause prayer' : 'Play prayer',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: note.sample ? OC.a100 : OC.a200, shape: BoxShape.circle),
                child: Center(child: OIcon(playing ? OI.pause : OI.play, size: 18, color: note.sample ? OC.a400 : OC.a700)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.phrase, style: OT.display(18, height: 1.2)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: progress, minHeight: 4, color: OC.accent, backgroundColor: OC.a200),
                ),
                const SizedBox(height: 6),
                Text('${note.author} · $dur · ${note.expires}${note.sample ? ' · Example' : ''}', style: OT.small(alpha: 0.65)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
