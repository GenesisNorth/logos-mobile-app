import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_flags.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/glance_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/verse_reader.dart';
import '../../core/utils/date_format.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/bloc/journey_state.dart';
import '../journey/data/progress_repository.dart';
import '../journey/screens/translation_notices_screen.dart';
import '../settings/journal_export.dart';

void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

Widget _tokens(int count, {double size = 34}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < JourneyBloc.maxGraceTokens; i++)
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: i < count ? OC.a300 : Colors.transparent,
              shape: BoxShape.circle,
              border: i < count ? null : Border.all(color: OC.a300, width: 2),
            ),
          ),
      ],
    );

Widget graceTokenDots(int count, {double size = 34}) => _tokens(count, size: size);

// ─── Grace ─────────────────────────────────────────────────────────────────

Future<void> showGraceSheet(BuildContext context, JourneyState s) {
  final canRestore = s.graceTokensBalance > 0 && s.isStreakRecoverable();
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(alignment: Alignment.centerLeft, child: Transform.translate(offset: const Offset(-6, 0), child: _tokens(s.graceTokensBalance, size: 40))),
        const SizedBox(height: 18),
        Text('Restore with grace', style: OT.h3()),
        const SizedBox(height: 8),
        Text(
          canRestore
              ? 'Yesterday slipped by. A token covers it, and your ${s.currentStreak}-day streak continues when you practise today.'
              : s.graceTokensBalance == 0
                  ? 'No tokens right now. Finish a full week’s rhythm to earn one back.'
                  : 'Your streak is intact. Grace tokens wait quietly until you need one.',
          style: OT.body(color: OC.text.withValues(alpha: 0.8)),
        ),
        if (canRestore) ...[
          const SizedBox(height: 20),
          OButton('Use a token', onPressed: () {
            context.read<JourneyBloc>().add(const RedeemGraceToken());
            Navigator.pop(ctx);
            _toast(context, 'Grace received. Practise today to keep it going.');
          }),
        ],
      ],
    ),
  );
}

// ─── Tear sheet ────────────────────────────────────────────────────────────

Future<void> showTearSheet(BuildContext context, TearSheetData sheet) {
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Transform.rotate(
          angle: -0.02,
          child: OCard(
            shadow: OShadow.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TEAR SHEET · ${formatLogosDate(sheet.completedAt).toUpperCase()}', style: OT.kicker(color: OC.a700, size: 11)),
                const SizedBox(height: 10),
                Text(sheet.burdenText?.isNotEmpty == true ? sheet.burdenText! : 'A burden, laid down.',
                    style: OT.display(22, height: 1.25)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text('EXCHANGED FOR · ${sheet.reference.toUpperCase()}', style: OT.kicker(color: OC.s700)),
        const SizedBox(height: 8),
        Text(sheet.verseText, style: OT.display(19, height: 1.3)),
        if (sheet.checkIn != null) ...[
          const SizedBox(height: 14),
          OTag(sheet.checkIn == 'lighter' ? 'It’s lighter now' : 'Still carrying — still praying',
              bg: OC.s200, fg: OC.s900),
        ],
      ],
    ),
  );
}

// ─── Account & export ──────────────────────────────────────────────────────

Future<void> showAccountSheet(BuildContext context, JourneyState s) {
  final email = TextEditingController(text: SupabaseService.instance.currentEmail ?? '');
  final password = TextEditingController();
  final cloud = SupabaseService.instance.isConfigured;
  final linked = cloud && !SupabaseService.instance.isAnonymous;
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OAvatar(s.profile.displayName, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.profile.displayName, style: OT.h4().copyWith(fontSize: 24)),
                  const SizedBox(height: 4),
                  OTag(linked ? 'Backed up' : 'Anonymous pilgrim', bg: OC.s200, fg: OC.s900),
                ],
              ),
            ),
            OCircleButton(
              icon: OI.pen,
              tooltip: 'Edit name',
              onTap: () {
                Navigator.pop(ctx);
                _editName(context, s);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          linked
              ? 'Your journey is backed up to ${SupabaseService.instance.currentEmail}.'
              : 'Your journey lives on this device. Link an email to keep it safe across devices.',
          style: OT.body(color: OC.text.withValues(alpha: 0.8)),
        ),
        if (!linked) ...[
          const SizedBox(height: 14),
          OInput(controller: email, hint: 'you@example.com', keyboardType: TextInputType.emailAddress, radius: 999),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _PasswordField(controller: password)),
              const SizedBox(width: 8),
              OButton('Link', expand: false, onPressed: cloud
                  ? () async {
                      final e = email.text.trim();
                      if (!e.contains('@') || password.text.length < 8) {
                        return _toast(ctx, 'Enter your email and a password of 8+ characters.');
                      }
                      final ok = await SupabaseService.instance.linkWithEmail(email: e, password: password.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        _toast(context, ok ? 'Backup is on. Sign in with $e on a new phone.' : 'Couldn’t link right now. Try again later.');
                      }
                    }
                  : null),
            ],
          ),
          if (!cloud) ...[
            const SizedBox(height: 6),
            Text('Backup arrives with accounts — coming soon.', style: OT.small(alpha: 0.6)),
          ],
        ],
        const SizedBox(height: 16),
        OButton('Export journal & covenant', style: OButtonStyle.outline, onPressed: () => exportJourneyJournal(s)),
      ],
    ),
  );
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  const _PasswordField({required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        style: OT.body(size: 16),
        decoration: InputDecoration(
          hintText: 'Password (8+ characters)',
          hintStyle: OT.body(size: 16, color: OC.text.withValues(alpha: 0.4)),
          filled: true,
          fillColor: OC.n100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        ),
      );
}

Future<void> _editName(BuildContext context, JourneyState s) {
  final c = TextEditingController(text: s.profile.displayName);
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your name', style: OT.h3()),
        const SizedBox(height: 14),
        OInput(controller: c, hint: 'Your name', autofocus: true, radius: 999),
        const SizedBox(height: 14),
        OButton('Save', onPressed: () {
          final n = c.text.trim();
          if (n.isNotEmpty) context.read<JourneyBloc>().add(UpdateDisplayName(n));
          Navigator.pop(ctx);
        }),
      ],
    ),
  );
}

// ─── Reading voice ─────────────────────────────────────────────────────────

Future<void> showVoiceSheet(BuildContext context, String verse) {
  return showOSheet(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: VerseReader.instance,
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading voice', style: OT.h3()),
          const SizedBox(height: 4),
          Text('How quickly the verse is read aloud when you tap Listen.', style: OT.small()),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final sp in ReadingSpeed.values)
                OPill(sp.label, selected: VerseReader.instance.speed == sp, onTap: () {
                  VerseReader.instance.setSpeed(sp);
                  VerseReader.instance.speak(verse);
                }),
            ],
          ),
        ],
      ),
    ),
  );
}

// ─── About, privacy & data ─────────────────────────────────────────────────

Future<void> showAboutSheet(BuildContext context) async {
  final info = await PackageInfo.fromPlatform().then((i) => '${i.version} (${i.buildNumber})').catchError((_) => '');
  if (!context.mounted) return;
  final flags = AppFlags.instance;

  Future<void> open(String value, String unavailable) async {
    if (value.isEmpty) return _toast(context, unavailable);
    final uri = Uri.parse(value.contains('@') && !value.startsWith('mailto:') ? 'mailto:$value' : value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      _toast(context, 'Could not open the link.');
    }
  }

  await showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('About & privacy', style: OT.h3()),
        const SizedBox(height: 14),
        OCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Column(
            children: [
              _Row('Privacy policy', onTap: () => open(flags.text(AppFlags.privacyUrl), 'The privacy policy will be published before launch.')),
              _Row('Terms of use', onTap: () => open(flags.text(AppFlags.termsUrl), 'The terms of use will be published before launch.')),
              _Row('Translation notices', onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TranslationNoticesScreen()));
              }),
              _Row('Contact us', onTap: () => open(flags.text(AppFlags.supportEmail), 'Support contact is coming soon.')),
              _Row('Erase data on this phone', danger: true, last: info.isEmpty, onTap: () {
                Navigator.pop(ctx);
                _confirmErase(context);
              }),
              if (info.isNotEmpty) _Row('Version $info', last: true),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _confirmErase(BuildContext context) async {
  final ok = await showOSheet<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Erase everything on this phone?', style: OT.h3()),
        const SizedBox(height: 10),
        Text(
          'Your streak, verses, tear sheets, examen notes, voice prayers and settings will be permanently removed. This cannot be undone.',
          style: OT.body(color: OC.text.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 20),
        OButton('Erase', style: OButtonStyle.dark, onPressed: () => Navigator.pop(ctx, true)),
        const SizedBox(height: 8),
        OButton('Keep my journey', style: OButtonStyle.outline, onPressed: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await VerseReader.instance.stop();
  await NotificationService.instance.toggleNotifications(false);
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  try {
    final docs = await getApplicationDocumentsDirectory();
    final notes = Directory('${docs.path}/prayer_notes');
    if (notes.existsSync()) await notes.delete(recursive: true);
  } catch (_) {}
  if (!context.mounted) return;
  context.read<JourneyBloc>().add(const LoadJourneyProgress());
  Navigator.of(context).popUntil((r) => r.isFirst);
}

class _Row extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool last;
  const _Row(this.label, {this.onTap, this.danger = false, this.last = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: OT.label(size: 16, color: danger ? const Color(0xFFB3261E) : OC.text)),
                  ),
                  if (onTap != null) OIcon(OI.next, size: 16, color: danger ? const Color(0xFFB3261E) : OC.text),
                ],
              ),
            ),
          ),
          if (!last) Divider(height: 1, color: OC.divider),
        ],
      );
}

// ─── Home & lock screen ────────────────────────────────────────────────────

/// Previews of the home-screen widgets and the Live Activity (design 2a/2b),
/// with the Live Activity switch and how to add a widget.
Future<void> showGlanceSheet(BuildContext context, JourneyState s) {
  final glance = GlanceService.instance;
  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
  return showOSheet(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final snap = GlanceSnapshot.from(s);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Home & Lock Screen', style: OT.h2()),
              const SizedBox(height: 14),
              if (isIOS) Center(child: _IslandPreview(snap: snap)),
              if (isIOS) const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: VerseWidgetPreview(snap: snap)),
                  const SizedBox(width: 12),
                  Expanded(child: WeekWidgetPreview(snap: snap)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isIOS
                    ? 'Touch and hold your Home or Lock Screen, tap Edit → Add Widgets, and choose LOGOS IN ME.'
                    : 'Touch and hold your home screen, tap Widgets, and choose LOGOS IN ME.',
                style: OT.small(alpha: 0.75),
              ),
              if (isIOS) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Countdown on lock screen', style: OT.label(size: 16)),
                          Text('Shows when your next step opens, in the Dynamic Island too.', style: OT.small(alpha: 0.7)),
                        ],
                      ),
                    ),
                    OToggle(
                      value: glance.liveActivityEnabled,
                      semanticLabel: 'Countdown on lock screen',
                      onChanged: (v) async {
                        await glance.setLiveActivityEnabled(v, s);
                        set(() {});
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              OButton('Sync to widget', onPressed: () async {
                await glance.sync(s, force: true);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) _toast(context, 'Your widgets are up to date.');
              }),
            ],
          ),
        );
      },
    ),
  );
}

/// Terracotta verse widget (mirrors the native small widget).
class VerseWidgetPreview extends StatelessWidget {
  final GlanceSnapshot snap;
  const VerseWidgetPreview({super.key, required this.snap});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: OC.a700, borderRadius: BorderRadius.circular(26)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(snap.reference.toUpperCase(), style: OT.kicker(color: OC.a200, size: 11)),
              const Spacer(),
              Text(snap.phrase, maxLines: 3, overflow: TextOverflow.ellipsis, style: OT.display(19, color: OC.n100, height: 1.1)),
              const Spacer(),
              Text(snap.status == 'today' ? snap.headline : (snap.status == 'complete' ? 'Week kept' : 'Resting'),
                  style: OT.label(size: 12, color: OC.n100)),
            ],
          ),
        ),
      );
}

/// Cream "This week" widget with the four seeds and the streak.
class WeekWidgetPreview extends StatelessWidget {
  final GlanceSnapshot snap;
  const WeekWidgetPreview({super.key, required this.snap});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: OC.n100, borderRadius: BorderRadius.circular(26)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THIS WEEK', style: OT.kicker(size: 11)),
              const Spacer(),
              Row(children: [for (final d in snap.days) Padding(padding: const EdgeInsets.only(right: 5), child: _SeedDot(state: d))]),
              const Spacer(),
              Text('${snap.streak}-day streak', style: OT.label(size: 12)),
            ],
          ),
        ),
      );
}

class _SeedDot extends StatelessWidget {
  final String state;
  static const size = 22.0;
  const _SeedDot({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == 'locked') {
      return const SizedBox(width: size, height: size, child: CustomPaint(painter: DashedCirclePainter(color: OC.n500, strokeWidth: 1.4)));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: state == 'done' ? OC.s500 : OC.accent, shape: BoxShape.circle),
    );
  }
}

class _IslandPreview extends StatelessWidget {
  final GlanceSnapshot snap;
  const _IslandPreview({required this.snap});

  @override
  Widget build(BuildContext context) {
    final wait = snap.unlockAt?.difference(DateTime.now());
    final label = snap.status == 'resting' ? snap.nextName : (snap.status == 'today' ? 'Day ${snap.nextDay}' : 'Kept');
    final right = wait != null ? '${wait.inHours}h ${wait.inMinutes % 60}m' : (snap.status == 'today' ? 'Today' : '✓');
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 22, height: 22, decoration: const BoxDecoration(color: OC.accent, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: OT.label(size: 14, color: Colors.white)),
          const SizedBox(width: 18),
          Text(right, style: OT.label(size: 14, color: OC.a300)),
        ],
      ),
    );
  }
}
