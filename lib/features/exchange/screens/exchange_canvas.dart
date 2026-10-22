import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/services/audio_service.dart';

class ExchangeCanvas extends StatefulWidget {
  final String verseText;
  final String reference;
  final VoidCallback onExchangeCompleted;

  const ExchangeCanvas({
    super.key,
    required this.verseText,
    required this.reference,
    required this.onExchangeCompleted,
  });

  @override
  State<ExchangeCanvas> createState() => _ExchangeCanvasState();
}

class _ExchangeCanvasState extends State<ExchangeCanvas>
    with SingleTickerProviderStateMixin {
  final TextEditingController _burdenController = TextEditingController(
    text: "Carrying chronic anxiety over finances and family burdens...",
  );

  bool _isDissolved = false;
  bool _isDraggingOver = false;

  late AnimationController _dissolveController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _dissolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dissolveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dissolveController.dispose();
    _burdenController.dispose();
    super.dispose();
  }

  void _triggerExchangeDissolution() {
    AudioService().triggerExchangeHaptic();
    _dissolveController.forward().then((_) {
      setState(() {
        _isDissolved = true;
      });
      widget.onExchangeCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Day 4: The Exchange',
          style: LogosTypography.label(color: ink),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lay your heavy burden down. Drag the mastered Scripture over it to dissolve the burden.',
                textAlign: TextAlign.center,
                style: LogosTypography.body(color: ink.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),

              // Top Zone: The Burden Drop Target
              Expanded(
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) {
                    setState(() => _isDraggingOver = true);
                    return true;
                  },
                  onLeave: (_) {
                    setState(() => _isDraggingOver = false);
                  },
                  onAcceptWithDetails: (_) {
                    setState(() => _isDraggingOver = false);
                    _triggerExchangeDissolution();
                  },
                  builder: (context, candidateData, rejectedData) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isDraggingOver
                            ? LogosColors.coral.withValues(alpha: 0.15)
                            : surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDraggingOver
                              ? LogosColors.coral
                              : LogosColors.taupe,
                          width: _isDraggingOver ? 2 : 1,
                        ),
                      ),
                      child: _isDissolved
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: LogosColors.coral,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your burden is dissolved in the Word.',
                                  style: LogosTypography.headline(color: ink),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tear Sheet rendered and saved to your Prayer Altar.',
                                  style: LogosTypography.body(
                                      color: ink.withValues(alpha: 0.6)),
                                ),
                              ],
                            )
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_note,
                                        size: 20,
                                        color: LogosColors.coral,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Your Burden:',
                                        style: LogosTypography.label(
                                            color: LogosColors.coral),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _burdenController,
                                      maxLines: null,
                                      expands: true,
                                      style: LogosTypography.scriptureBody(
                                          color: ink),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Type your burden here...',
                                        hintStyle: TextStyle(
                                            color: ink.withValues(alpha: 0.4)),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '↓ Drop Scripture Here ↓',
                                      style: LogosTypography.caption(
                                        color: LogosColors.coral,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Zone: Draggable Mastered Scripture Card
              if (!_isDissolved)
                Draggable<String>(
                  data: widget.verseText,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LogosColors.sanctuaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.verseText,
                        style: LogosTypography.scriptureBody(
                            color: Colors.white),
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildVerseCard(surface, ink),
                  ),
                  child: _buildVerseCard(surface, ink),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseCard(Color surface, Color ink) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LogosColors.coral, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: LogosColors.coral.withValues(alpha: 0.12),
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
              Text(
                'Mastered Scripture (Drag Upward)',
                style: LogosTypography.label(color: LogosColors.coral),
              ),
              const Icon(Icons.drag_indicator, color: LogosColors.coral),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${widget.verseText}"',
            style: LogosTypography.scriptureBody(color: ink),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.reference,
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
