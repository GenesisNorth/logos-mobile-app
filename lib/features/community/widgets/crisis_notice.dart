import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_flags.dart';
import '../../../core/design/organic.dart';

/// "If you're in danger right now…" — shown wherever people may share grief
/// or distress. Numbers come from remote config so the admin can localise them.
class CrisisNotice extends StatelessWidget {
  final bool dark;
  final bool compact;
  const CrisisNotice({super.key, this.dark = false, this.compact = false});

  Future<void> _open(BuildContext context, String uri) async {
    if (uri.isEmpty) return;
    if (!await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final flags = AppFlags.instance;
    final ink = dark ? OC.n100 : OC.text;
    final link = OT.body(size: 14, color: dark ? OC.a300 : OC.a700, weight: FontWeight.w700)
        .copyWith(decoration: TextDecoration.underline, decorationColor: dark ? OC.a300 : OC.a700);
    final lineUri = flags.text(AppFlags.crisisLineUri);
    final directory = flags.text(AppFlags.crisisDirectoryUrl);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: dark ? OC.n800 : OC.n100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text.rich(
        TextSpan(
          style: OT.body(size: 14, color: ink.withValues(alpha: 0.85), height: 1.45),
          children: [
            TextSpan(text: 'If you’re in danger right now, ', style: OT.body(size: 14, color: ink, weight: FontWeight.w800, height: 1.45)),
            if (lineUri.isNotEmpty)
              TextSpan(
                text: flags.text(AppFlags.crisisLineLabel).replaceFirst(RegExp(r'^In the US, '), ''),
                style: link,
                recognizer: TapGestureRecognizer()..onTap = () => _open(context, lineUri),
              ),
            if (lineUri.isNotEmpty) const TextSpan(text: ' (US), '),
            const TextSpan(text: 'call your local emergency number, or '),
            TextSpan(
              text: 'find a helpline',
              style: link,
              recognizer: TapGestureRecognizer()..onTap = () => _open(context, directory),
            ),
            TextSpan(text: compact ? '.' : '. This is a place of prayer, not an emergency service.'),
          ],
        ),
      ),
    );
  }
}
