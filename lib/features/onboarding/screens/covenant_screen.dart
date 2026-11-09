import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';
import '../../journey/data/bible_translations.dart';
import '../../today/today_sheets.dart';

/// First run: the covenant (step 1), when to chime (step 2), translation (step 3).
/// The covenant is sealed only when setup finishes.
class CovenantScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const CovenantScreen({super.key, required this.onCompleted});

  @override
  State<CovenantScreen> createState() => _CovenantScreenState();
}

class _CovenantScreenState extends State<CovenantScreen> {
  final _name = TextEditingController();
  int _step = 0; // 0 covenant · 1 chimes · 2 translation
  String _translation = 'ESV';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _sign() {
    if (_name.text.trim().isEmpty) {
      _toast('Write your name to sign the covenant.');
      return;
    }
    FocusScope.of(context).unfocus();
    AudioService().playAmenChime();
    setState(() => _step = 1);
  }

  Future<void> _afterChimes() async {
    final n = NotificationService.instance;
    final anyOn = LiturgicalHour.values.any(n.isChimeOn);
    if (anyOn) await n.toggleNotifications(true);
    if (mounted) setState(() => _step = 2);
  }

  void _begin() {
    final bloc = context.read<JourneyBloc>();
    bloc.add(SelectTranslation(_translation));
    bloc.add(SignCovenant(_name.text.trim()));
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: switch (_step) {
        0 => _covenant(),
        1 => _setup(
            key: const ValueKey(1),
            title: 'When should we chime?',
            body: 'Gentle bells at the old hours of prayer. Change them anytime.',
            content: const ChimeList(),
            action: 'Continue',
            onAction: _afterChimes,
          ),
        _ => _setup(
            key: const ValueKey(2),
            title: 'Choose your translation',
            body: 'You’ll recite in this one. Switch whenever you like.',
            content: _translations(),
            action: 'Begin Week 1',
            onAction: _begin,
          ),
      },
    );
  }

  Widget _covenant() {
    const atm = Atmosphere.ember;
    return OScreen(
      key: const ValueKey(0),
      atmosphere: atm,
      bottom: OButton('Sign the covenant', style: OButtonStyle.light, onPressed: _sign),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ODecor(big: OC.a600, small: OC.a500, bigSize: 260, bigOffset: Offset(-80, -110), smallOffset: Offset(60, 120), smallSize: 50),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LOGOS IN ME', style: OT.kicker(color: OC.a100)),
                const SizedBox(height: 110),
                Text('A covenant\nof returning.', style: OT.display(44, color: OC.n100, height: 1.02)),
                const SizedBox(height: 26),
                _point('1', 'One verse a week. Nothing more to master.'),
                _point('4', 'Four days of dwelling — each opens at midnight, never early.'),
                _point('3', 'Three grace tokens. Grace over guilt, always.'),
                const SizedBox(height: 40),
                Text('SIGN WITH YOUR NAME', style: OT.kicker(color: OC.a100)),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  style: OT.display(32, color: OC.n100),
                  cursorColor: OC.a200,
                  onSubmitted: (_) => _sign(),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: OT.display(32, color: OC.n100.withValues(alpha: 0.4)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: OC.a200.withValues(alpha: 0.8), width: 1.5)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: OC.a100, width: 2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(String n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: OC.n100, shape: BoxShape.circle),
              child: Center(child: Text(n, style: OT.display(15, color: OC.a800))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: OT.body(size: 16, color: OC.n100, height: 1.45))),
          ],
        ),
      );

  Widget _setup({
    required Key key,
    required String title,
    required String body,
    required Widget content,
    required String action,
    required VoidCallback onAction,
  }) {
    return OScreen(
      key: key,
      atmosphere: Atmosphere.parchment,
      bottom: OButton(action, onPressed: onAction),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        children: [
          Text('STEP ${_step + 1} OF 3', style: OT.kicker()),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= _step ? OC.accent : OC.n300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: OT.display(36, height: 1.05)),
          const SizedBox(height: 8),
          Text(body, style: OT.body(color: OC.text.withValues(alpha: 0.75))),
          const SizedBox(height: 22),
          content,
        ],
      ),
    );
  }

  Widget _translations() {
    return Column(
      children: [
        for (final t in bibleTranslations) ...[
          OCard(
            color: t.key == _translation ? OC.a100 : OC.n100,
            border: Border.all(color: t.key == _translation ? OC.accent : Colors.transparent, width: 1.6),
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            onTap: () => setState(() => _translation = t.key),
            child: Row(
              children: [
                SizedBox(width: 56, child: Text(t.key, style: OT.label(size: 16))),
                Expanded(child: Text(t.name, style: OT.small(alpha: 0.75))),
                if (t.key == _translation) const OIcon(OI.check, size: 18, color: OC.accent),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
