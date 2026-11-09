import 'package:flutter/material.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/audio_service.dart';
import 'examen_store.dart';

/// Evening Examen — three questions before rest. Kept only on this phone.
class ExamenScreen extends StatefulWidget {
  const ExamenScreen({super.key});

  @override
  State<ExamenScreen> createState() => _ExamenScreenState();
}

class _ExamenScreenState extends State<ExamenScreen> {
  int _step = 0;
  final _controllers = List.generate(examenQuestions.length, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < examenQuestions.length - 1) {
      setState(() => _step++);
      return;
    }
    await ExamenStore.instance.save(_controllers.map((c) => c.text.trim()).toList());
    AudioService().playSanctuaryChime();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rest well. He keeps watch.')));
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.dusk;
    final last = _step == examenQuestions.length - 1;
    return OScreen(
      atmosphere: atm,
      bottom: Row(
        children: [
          ODots(count: examenQuestions.length, index: _step, active: OC.accent, inactive: OC.n700),
          const Spacer(),
          if (_step > 0) ...[
            TextButton(
              onPressed: () => setState(() => _step--),
              child: Text('Back', style: OT.label(size: 15, color: OC.n100.withValues(alpha: 0.7))),
            ),
            const SizedBox(width: 6),
          ],
          OButton(last ? 'Rest' : 'Next', expand: false, onPressed: _next),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -60,
            bottom: -40,
            child: _Glow(),
          ),
          Column(
            children: [
              OTopBar(
                kicker: 'Evening examen',
                atmosphere: atm,
                kickerColor: OC.a300,
                trailing: Text('${_step + 1}/${examenQuestions.length}', style: OT.label(size: 15, color: OC.n100)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(examenQuestions[_step], style: OT.display(34, color: OC.n100, height: 1.1)),
                      const SizedBox(height: 14),
                      Text('A sentence is enough. No one else will read this.', style: OT.small(color: OC.n100, alpha: 0.7)),
                      const SizedBox(height: 22),
                      OInput(
                        key: ValueKey(_step),
                        controller: _controllers[_step],
                        hint: examenHints[_step],
                        minLines: 5,
                        maxLines: 8,
                        fill: Colors.white.withValues(alpha: 0.1),
                        ink: OC.n100,
                        style: OT.display(20, color: OC.n100, height: 1.3),
                        radius: 26,
                      ),
                    ],
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

class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: [
              Container(decoration: const BoxDecoration(color: Color(0xFF42200F), shape: BoxShape.circle)),
              Positioned(
                right: 50,
                top: -10,
                child: Container(width: 46, height: 46, decoration: const BoxDecoration(color: OC.a800, shape: BoxShape.circle)),
              ),
            ],
          ),
        ),
      );
}
