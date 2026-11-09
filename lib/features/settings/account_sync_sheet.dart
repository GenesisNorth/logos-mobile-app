import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/logos_icons.dart';
import '../../core/theme/logos_theme.dart';

/// Lets an anonymous pilgrim attach an email so progress can be restored on
/// another device. Only reachable when the cloud backend is configured.
Future<void> showAccountSyncSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _AccountSyncSheet(),
  );
}

class _AccountSyncSheet extends StatefulWidget {
  const _AccountSyncSheet();

  @override
  State<_AccountSyncSheet> createState() => _AccountSyncSheetState();
}

class _AccountSyncSheetState extends State<_AccountSyncSheet> {
  late final TextEditingController _email =
      TextEditingController(text: SupabaseService.instance.currentEmail ?? '');
  final TextEditingController _password = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();
    if (!email.contains('@') || pass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and a password of at least 8 characters.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await SupabaseService.instance.linkWithEmail(email: email, password: pass);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Backup is on. Sign in with $email to restore your journey.'
          : 'Could not turn on backup right now. Please try again later.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? LogosColors.examenSurface : Colors.white;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final linked = !SupabaseService.instance.isAnonymous;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const AppIcon(LogosIcons.shieldRounded, color: LogosColors.coral, size: 22),
            const SizedBox(width: 10),
            Text('Back up your journey',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          ]),
          const SizedBox(height: 8),
          Text(
            linked
                ? 'Backup is on for ${SupabaseService.instance.currentEmail ?? 'your account'}.'
                : 'Add an email so your streak, verses and Tear Sheets can be restored on a new phone.',
            style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: ink.withValues(alpha: 0.7)),
          ),
          if (!linked) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password (8+ characters)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LogosColors.coral,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Turn on backup', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
