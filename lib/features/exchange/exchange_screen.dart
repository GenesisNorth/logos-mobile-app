import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/date_format.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/models/scripture_drop.dart';
import '../recap/recap_screen.dart';

/// Day 4 — The Exchange: write what you carry, hold to lay it down,
/// receive the Word instead. Only you ever see what you write.
class ExchangeScreen extends StatefulWidget {
  final ScriptureDrop drop;
  const ExchangeScreen({super.key, required this.drop});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen>
    with SingleTickerProviderStateMixin {
  final _burden = TextEditingController();
  late final AnimationController _hold =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )
        ..addListener(_onHoldTick)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _layDown();
        });
  bool _received = false;
  int _lastTick = 0;

  @override
  void dispose() {
    _hold.dispose();
    _burden.dispose();
    super.dispose();
  }

  void _onHoldTick() {
    final tick = (_hold.value * 4).floor();
    if (tick > _lastTick && tick < 4) {
      _lastTick = tick;
      AudioService().emberPulse();
    }
    setState(() {});
  }

  bool _ready() {
    if (_burden.text.trim().isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'First write what you’re carrying — a few words is enough.',
        ),
      ),
    );
    return false;
  }

  void _startHold() {
    if (_received || !_ready()) return;
    FocusScope.of(context).unfocus();
    _lastTick = 0;
    _hold.forward(from: 0);
  }

  void _cancelHold() {
    if (_hold.isAnimating) _hold.reverse();
  }

  void _layDown() {
    AudioService().triggerExchangeHaptic();
    AudioService().playSanctuaryChime();
    setState(() => _received = true);
  }

  void _keep() {
    context.read<JourneyBloc>().add(
      CompleteExchange(burdenSummary: _burden.text.trim()),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RecapScreen(drop: widget.drop)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.paper;
    return OScreen(
      atmosphere: atm,
      bottom: _received
          ? OButton('Keep tear sheet · Complete Day 4', onPressed: _keep)
          : _holdButton(),
      child: Column(
        children: [
          const OTopBar(
            kicker: 'Day 4 · Exchange',
            atmosphere: atm,
            kickerColor: OC.a700,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              child: _received ? _receivedView() : _writeView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _writeView() {
    final p = _hold.value;
    return GestureDetector(
      key: const ValueKey('write'),
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What are you carrying today?', style: OT.display(30)),
            const SizedBox(height: 8),
            Text(
              'Write it plainly. Then hold to lay it on the altar. Only you will ever see it.',
              style: OT.small(alpha: 0.75),
            ),
            const SizedBox(height: 22),
            Opacity(
              opacity: 1 - p * 0.6,
              child: Transform.scale(
                scale: 1 - p * 0.08,
                child: Transform.rotate(
                  angle: -0.03 + p * 0.05,
                  child: OCard(
                    shadow: OShadow.lg,
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEAR SHEET · ${formatLogosDate(DateTime.now()).toUpperCase()}',
                          style: OT.kicker(color: OC.a700, size: 11),
                        ),
                        TextField(
                          controller: _burden,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          minLines: 4,
                          maxLines: 7,
                          textCapitalization: TextCapitalization.sentences,
                          style: OT.display(22, height: 1.3),
                          cursorColor: OC.accent,
                          decoration: InputDecoration(
                            hintText: 'The conversation I keep replaying…',
                            hintStyle: OT.display(
                              22,
                              color: OC.n500,
                              height: 1.3,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _holdButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Lay it down',
          hint: 'Press and hold',
          onTap: () {
            // Screen-reader double-tap: lay it down without holding.
            if (_ready()) _layDown();
          },
          excludeSemantics: true,
          child: GestureDetector(
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: OC.a200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: CircularProgressIndicator(
                      value: _hold.value,
                      strokeWidth: 5,
                      color: OC.a600,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: OC.a700,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: OIcon(OI.flame, size: 32, color: OC.n100),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _hold.isAnimating ? 'Keep holding…' : 'Hold to lay it down',
          style: OT.label(size: 15, color: OC.a800),
        ),
      ],
    );
  }

  Widget _receivedView() {
    return SingleChildScrollView(
      key: const ValueKey('received'),
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: OC.s500,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: OIcon(OI.sprout, size: 26, color: OC.n100),
            ),
          ),
          const SizedBox(height: 22),
          Text('LAID DOWN. RECEIVED INSTEAD', style: OT.kicker(color: OC.s700)),
          const SizedBox(height: 12),
          Text(widget.drop.verseText, style: OT.verse(size: 27)),
          const SizedBox(height: 12),
          Text(
            '${widget.drop.reference} · ${widget.drop.translation}',
            style: OT.small(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
