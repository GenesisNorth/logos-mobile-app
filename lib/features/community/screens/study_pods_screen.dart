import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

class StudyPodsScreen extends StatefulWidget {
  const StudyPodsScreen({super.key});

  @override
  State<StudyPodsScreen> createState() => _StudyPodsScreenState();
}

class _StudyPodsScreenState extends State<StudyPodsScreen> {
  final TextEditingController _reflectionController = TextEditingController();

  final List<Map<String, dynamic>> _members = [
    {'name': 'Genesis A.', 'role': 'You', 'progress': 'Day 2', 'status': 'Abiding', 'isYou': true},
    {'name': 'Sarah K.', 'role': 'Member', 'progress': 'Day 3', 'status': 'In Stillness', 'isYou': false},
    {'name': 'David M.', 'role': 'Member', 'progress': 'Day 2', 'status': 'Studying Context', 'isYou': false},
    {'name': 'Hannah L.', 'role': 'Member', 'progress': 'Day 1', 'status': 'Reciting', 'isYou': false},
  ];

  final List<Map<String, String>> _discussionQuestions = [
    {
      'num': '1',
      'q': 'What does it look like in your modern daily schedule to "abide" (menō) rather than visit sporadically?',
    },
    {
      'num': '2',
      'q': 'Where in your career or relationships have you attempted to manufacture fruit by willpower instead of connection to the Vine?',
    },
    {
      'num': '3',
      'q': 'How does knowing Jesus is the True Vine reshape your prayers during dry seasons?',
    },
  ];

  final List<Map<String, String>> _reflections = [
    {
      'author': 'Sarah K.',
      'time': 'Yesterday at 9:15 PM',
      'text': 'Reading the exegesis card on "menō" really hit me. I realized my prayer life was like emergency visits to a doctor rather than residing in a home.',
    },
    {
      'author': 'David M.',
      'time': 'Today at 7:30 AM',
      'text': 'The reminder that branches don’t strain or sweat to produce fruit gave me so much peace this morning before entering the office.',
    },
  ];

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  void _postReflection() {
    final text = _reflectionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _reflections.insert(0, {
        'author': 'Genesis A.',
        'time': 'Just now',
        'text': text,
      });
      _reflectionController.clear();
    });
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
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('Study Pods', style: LogosTypography.label(color: LogosColors.studyPods)),
            Text('Intimate Exegesis Group', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  // Pod Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: LogosColors.studyPods,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    'Thu 8:00 PM EST',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              '4 / 6 Members',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Abiding in the Vine',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Walking through John 15 together with quiet contemplation and peer support.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pod Members Horizontal Row
                  Text('Pod Family', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 10),
                  Row(
                    children: _members.map((m) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: m['isYou'] == true ? LogosColors.studyPods : LogosColors.taupe,
                              width: m['isYou'] == true ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: LogosColors.studyPods.withValues(alpha: 0.2),
                                child: Text(
                                  (m['name'] as String)[0],
                                  style: TextStyle(fontWeight: FontWeight.bold, color: ink, fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                m['name'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LogosColors.coral.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m['progress'] as String,
                                  style: const TextStyle(color: LogosColors.coral, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Weekly Discussion Guide
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weekly Exegesis Guide', style: LogosTypography.label(color: ink)),
                      Text('Week 1', style: LogosTypography.caption(color: LogosColors.studyPods)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._discussionQuestions.map((q) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: LogosColors.taupe),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: LogosColors.studyPods.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                q['num']!,
                                style: const TextStyle(
                                  color: LogosColors.studyPods,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q['q']!,
                                style: LogosTypography.body(color: ink).copyWith(fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Pod Reflections Feed
                  Text('Shared Reflections', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 10),
                  ..._reflections.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: LogosColors.taupe),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r['author']!,
                                  style: LogosTypography.label(color: ink),
                                ),
                                Text(
                                  r['time']!,
                                  style: LogosTypography.caption(color: ink.withValues(alpha: 0.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r['text']!,
                              style: LogosTypography.body(color: ink.withValues(alpha: 0.85)).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // Bottom Post Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: LogosColors.taupe.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reflectionController,
                      style: LogosTypography.body(color: ink),
                      decoration: InputDecoration(
                        hintText: 'Share a thought with your pod...',
                        hintStyle: TextStyle(color: ink.withValues(alpha: 0.4), fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: ink.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: LogosColors.studyPods),
                    onPressed: _postReflection,
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
