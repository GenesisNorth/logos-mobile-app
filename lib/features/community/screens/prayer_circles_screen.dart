import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/pilgrim_name.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/theme/logos_icons.dart';
import '../data/community_repository.dart';
import '../data/voice_note_store.dart';

class PrayerCirclesScreen extends StatefulWidget {
  const PrayerCirclesScreen({super.key});

  @override
  State<PrayerCirclesScreen> createState() => _PrayerCirclesScreenState();
}

class _PrayerCirclesScreenState extends State<PrayerCirclesScreen> {
  static const _maxRecordSeconds = 120;

  bool _isRecording = false;
  bool _busy = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordingPath;
  String _selectedFixedPhrase = 'Praying with you';

  // Created lazily so merely opening the screen never touches audio plugins.
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  StreamSubscription<void>? _playerDoneSub;
  final VoiceNoteStore _store = VoiceNoteStore();

  final List<String> _fixedPhrases = [
    'Praying with you',
    'Standing in agreement',
    'Lifting you before the Father',
    'The peace of Christ guard you',
    'Amen',
  ];

  /// Example circle prayers shown until Prayer Circles sync with the cloud.
  /// They carry no audio, so they are labelled and cannot be played.
  static final List<Map<String, dynamic>> _samplePrayers = [
    {
      'id': 'sample-1',
      'author': 'Sarah K.',
      'phrase': 'Praying with you',
      'duration': '0:42',
      'expiresIn': 'Expires in 4 days',
      'isSample': true,
    },
    {
      'id': 'sample-2',
      'author': 'David M.',
      'phrase': 'The peace of Christ guard you',
      'duration': '1:15',
      'expiresIn': 'Expires in 5 days',
      'isSample': true,
    },
    {
      'id': 'sample-3',
      'author': 'Hannah L.',
      'phrase': 'Standing in agreement',
      'duration': '0:28',
      'expiresIn': 'Expires in 6 days',
      'isSample': true,
    },
  ];

  List<LocalVoiceNote> _myNotes = [];
  String? _playingId;

  List<Map<String, dynamic>> get _voiceNotes => [
    ..._myNotes.map((n) {
      final left =
          VoiceNoteStore.lifetime - DateTime.now().difference(n.createdAt);
      final days = (left.inMinutes / (24 * 60)).ceil(); // a fresh note reads "7 days"
      return {
        'id': n.id,
        'author': '${n.authorName} (You)',
        'phrase': n.phrase,
        'duration': _fmt(n.durationSeconds),
        'expiresIn': days >= 1
            ? 'Expires in $days day${days == 1 ? '' : 's'}'
            : 'Expires today',
        'path': n.path,
        'isSample': false,
      };
    }),
    ..._samplePrayers,
  ];

  static String _fmt(int secs) =>
      '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadMyNotes();
  }

  Future<void> _loadMyNotes() async {
    try {
      final notes = await _store.load();
      if (mounted) setState(() => _myNotes = notes);
    } catch (e) {
      debugPrint('[PrayerCircles] could not load voice notes: $e');
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerDoneSub?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_isRecording) {
        await _stopRecording();
      } else {
        await _startRecording();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _startRecording() async {
    await _stopPlayback();
    final recorder = _recorder ??= AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        _toast('Microphone access is needed to record a voice prayer.');
        return;
      }
      final path = await _store.newRecordingPath();
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000),
        path: path,
      );
      _recordingPath = path;
    } catch (e) {
      debugPrint('[PrayerCircles] start recording failed: $e');
      _toast('Could not start recording. Please try again.');
      return;
    }

    AudioService().selectionTick();
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= _maxRecordSeconds) _toggleRecording();
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    final seconds = _recordSeconds;
    String? path;
    try {
      path = await _recorder?.stop();
    } catch (e) {
      debugPrint('[PrayerCircles] stop recording failed: $e');
    }
    path ??= _recordingPath;
    _recordingPath = null;
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (path == null || seconds < 1 || !File(path).existsSync()) {
      if (path != null && File(path).existsSync()) File(path).deleteSync();
      _toast('Prayer too short — hold for at least a second.');
      return;
    }

    final author = pilgrimName(context);
    final note = LocalVoiceNote(
      id: const Uuid().v4(),
      path: path,
      phrase: _selectedFixedPhrase,
      authorName: author,
      durationSeconds: seconds,
      createdAt: DateTime.now(),
    );
    await _store.add(note);
    if (!mounted) return;
    setState(() => _myNotes = [note, ..._myNotes]);

    CommunityRepository().submitPrayer(
      room: 'prayer_circles',
      title: _selectedFixedPhrase,
      content: 'Voice note prayer: "$_selectedFixedPhrase"',
      authorName: author,
    );
    AudioService().playAmenChime();
    _toast('Voice prayer saved (purges in 7 days)');
  }

  Future<void> _stopPlayback() async {
    if (_playingId == null) return;
    await _player?.stop();
    if (mounted) setState(() => _playingId = null);
  }

  Future<void> _togglePlay(int index) async {
    final note = _voiceNotes[index];
    AudioService().selectionTick();

    if (note['isSample'] == true) {
      _toast(
        'Example prayer — circle voices will play once Prayer Circles go live.',
      );
      return;
    }
    if (_isRecording) return;

    final id = note['id'] as String;
    if (_playingId == id) {
      await _stopPlayback();
      return;
    }

    final player = _player ??= AudioPlayer();
    _playerDoneSub ??= player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    try {
      await player.stop();
      await player.play(DeviceFileSource(note['path'] as String));
      if (mounted) setState(() => _playingId = id);
    } catch (e) {
      debugPrint('[PrayerCircles] playback failed: $e');
      _toast('Could not play this prayer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcon(LogosIcons.arrowBack, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Prayer Circles',
              style: TextStyle(
                color: LogosColors.prayerCircles,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '7-Day Ephemeral Prayers',
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                children: [
                  // Circle Manifesto Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: LogosColors.prayerCircles,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppIcon(
                              LogosIcons.autoDeleteOutlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '7-DAY SACRED EPHEMERALITY',
                              style:
                                  LogosTypography.caption(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ).copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The Jerusalem Circle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voice prayers are automatically purged after 7 days to keep hearts focused on present intercession, free from digital hoarding.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fixed Phrase Quick Selector
                  Text(
                    'Encouragement Stance',
                    style: LogosTypography.label(color: ink),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fixedPhrases.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final phrase = _fixedPhrases[i];
                        final isSelected = phrase == _selectedFixedPhrase;
                        return ChoiceChip(
                          label: Text(
                            phrase,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : ink,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: LogosColors.prayerCircles,
                          backgroundColor: surface,
                          side: BorderSide(
                            color: isSelected
                                ? LogosColors.prayerCircles
                                : LogosColors.taupe,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedFixedPhrase = phrase);
                            }
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Circle Voice Prayers',
                        style: LogosTypography.label(color: ink),
                      ),
                      Text(
                        '${_voiceNotes.length} active',
                        style: LogosTypography.caption(
                          color: ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(_voiceNotes.length, (index) {
                    final note = _voiceNotes[index];
                    final isPlaying = note['id'] == _playingId;
                    final isSample = note['isSample'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPlaying
                              ? LogosColors.prayerCircles
                              : LogosColors.taupe,
                          width: isPlaying ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: LogosColors.prayerCircles
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      (note['author'] as String)[0],
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    note['author'] as String,
                                    style: LogosTypography.label(color: ink),
                                  ),
                                  if (isSample) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      'Example',
                                      style: LogosTypography.caption(
                                        color: ink.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  note['expiresIn'] as String,
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${note['phrase']}"',
                            style: LogosTypography.scriptureCitation(
                              color: LogosColors.prayerCircles,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Audio player bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: AppIcon(
                                    isPlaying
                                        ? LogosIcons.pauseCircleFilled
                                        : LogosIcons.playCircleFilled,
                                    color: isSample
                                        ? LogosColors.prayerCircles.withValues(
                                            alpha: 0.35,
                                          )
                                        : LogosColors.prayerCircles,
                                    size: 32,
                                  ),
                                  onPressed: () => _togglePlay(index),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Decorative waveform
                                      Row(
                                        children: List.generate(24, (barIndex) {
                                          final height = isPlaying
                                              ? (10 + (barIndex % 5) * 4)
                                                    .toDouble()
                                              : (6 + (barIndex % 3) * 3)
                                                    .toDouble();
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 1.5,
                                            ),
                                            width: 3,
                                            height: height,
                                            decoration: BoxDecoration(
                                              color: isPlaying
                                                  ? LogosColors.prayerCircles
                                                  : ink.withValues(alpha: 0.25),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  note['duration'] as String,
                                  style: LogosTypography.caption(
                                    color: ink.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bottom Audio Record Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  top: BorderSide(
                    color: LogosColors.taupe.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isRecording
                              ? 'Recording Prayer (${_recordSeconds}s / ${_maxRecordSeconds}s max)'
                              : 'Speak a voice prayer to your circle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? Colors.redAccent : ink,
                          ),
                        ),
                        Text(
                          'Phrase: $_selectedFixedPhrase',
                          style: LogosTypography.caption(
                            color: ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.redAccent
                            : LogosColors.prayerCircles,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? Colors.redAccent
                                        : LogosColors.prayerCircles)
                                    .withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: AppIcon(
                        _isRecording ? LogosIcons.stop : LogosIcons.mic,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
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
