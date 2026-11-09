import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'components.dart';
import 'organic.dart';

/// A 4:5 card in the ember atmosphere — what a week or verse looks like when shared.
class ShareCard extends StatelessWidget {
  final String kicker;
  final String verse;
  final String reference;
  final String? closing;

  const ShareCard({super.key, required this.kicker, required this.verse, required this.reference, this.closing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 450,
      child: ClipRect(
        child: Container(
          color: OC.a700,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ODecor(big: OC.a600, small: OC.a500, bigSize: 230, bigOffset: Offset(-80, -90), smallOffset: Offset(48, 96), smallSize: 30),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kicker.toUpperCase(), style: OT.kicker(color: OC.a200, size: 11)),
                    const Spacer(),
                    Text(verse,
                        maxLines: 9,
                        overflow: TextOverflow.ellipsis,
                        style: OT.verse(size: verse.length > 160 ? 19 : 23, color: OC.n100)),
                    const SizedBox(height: 12),
                    Text(reference, style: OT.label(size: 13, color: OC.a200)),
                    const Spacer(),
                    Row(
                      children: [
                        if (closing != null) Expanded(child: Text(closing!, style: OT.display(16, color: OC.n100))) else const Spacer(),
                        Text('LOGOS IN ME', style: OT.kicker(color: OC.a200, size: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [card] off-screen and opens the share sheet with it as a PNG
/// (falls back to [fallbackText] if rendering fails).
Future<void> shareCardImage(BuildContext context, ShareCard card, {required String fallbackText}) async {
  final key = GlobalKey();
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -4000,
      top: 0,
      child: RepaintBoundary(key: key, child: MediaQuery(data: const MediaQueryData(), child: Material(child: card))),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('not rendered');
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('no bytes');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/logos_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    entry.remove();
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')], text: fallbackText));
  } catch (_) {
    if (entry.mounted) entry.remove();
    await SharePlus.instance.share(ShareParams(text: fallbackText));
  }
}
