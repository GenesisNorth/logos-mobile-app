import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_flags.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/verse_reader.dart';
import '../../core/theme/logos_icons.dart';
import '../../core/theme/logos_theme.dart';
import '../../core/widgets/logos_dialog.dart';
import '../examen/controllers/examen_controller.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/bloc/journey_state.dart';
import '../journey/data/bible_translations.dart';
import '../journey/screens/translation_picker_sheet.dart';
import 'account_sync_sheet.dart';
import 'journal_export.dart';
import 'reminder_controls.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final ExamenController examenController;
  const SettingsScreen({super.key, required this.examenController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notifications = NotificationService.instance;
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((_) {});
  }

  Future<void> _editName(JourneyState state) async {
    final controller = TextEditingController(text: state.profile.displayName);
    final name = await showLogosDialog<String>(
      context,
      title: 'Your name',
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
      confirmLabel: 'Save',
      onConfirm: () => controller.text.trim(),
    );
    if (name != null && name.isNotEmpty && mounted) {
      context.read<JourneyBloc>().add(UpdateDisplayName(name));
    }
  }

  Future<void> _openLink(String value, {required String unavailable}) async {
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(unavailable)));
      return;
    }
    final uri = Uri.parse(value.contains('@') && !value.startsWith('mailto:') ? 'mailto:$value' : value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  Future<void> _eraseData() async {
    final confirmed = await showLogosDialog<bool>(
      context,
      title: 'Erase all data on this phone?',
      message:
          'Your streak, verses, Tear Sheets, voice prayers and settings will be permanently removed from this phone. This cannot be undone.',
      confirmLabel: 'Erase',
      destructive: true,
      onConfirm: () => true,
    );
    if (confirmed != true || !mounted) return;

    await VerseReader.instance.stop();
    await _notifications.toggleNotifications(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      final docs = await getApplicationDocumentsDirectory();
      final notes = Directory('${docs.path}/prayer_notes');
      if (notes.existsSync()) await notes.delete(recursive: true);
    } catch (_) {}
    if (!mounted) return;
    context.read<JourneyBloc>().add(const LoadJourneyProgress());
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final flags = AppFlags.instance;

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: AppIcon(LogosIcons.arrowBack, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ink)),
      ),
      body: BlocBuilder<JourneyBloc, JourneyState>(
        builder: (context, state) {
          final translation = translationByKey(state.activeDrop.translation);
          return ListenableBuilder(
            listenable: Listenable.merge([widget.examenController, VerseReader.instance]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                SettingsSection('Profile', ink: ink, children: [
                  SettingsTile(
                    icon: LogosIcons.user,
                    title: 'Name',
                    subtitle: state.profile.displayName,
                    ink: ink,
                    onTap: () => _editName(state),
                  ),
                ]),
                SettingsSection('Practice', ink: ink, children: [
                  SettingsTile(
                    icon: LogosIcons.bookOpen,
                    title: 'Bible translation',
                    subtitle: translation != null ? '${translation.name} (${translation.key})' : state.activeDrop.translation,
                    ink: ink,
                    onTap: () => showTranslationPicker(
                      context,
                      current: state.activeDrop.translation,
                      previews: state.activeDrop.translations,
                      onSelected: (key) => context.read<JourneyBloc>().add(SelectTranslation(key)),
                    ),
                  ),
                  SettingsTile(
                    icon: LogosIcons.volumeHigh,
                    title: 'Reading voice speed',
                    ink: ink,
                    below: SegmentedButton<ReadingSpeed>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: LogosColors.coral.withValues(alpha: 0.15),
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: [
                        for (final s in ReadingSpeed.values)
                          ButtonSegment(value: s, label: Text(s.label, style: const TextStyle(fontSize: 12))),
                      ],
                      selected: {VerseReader.instance.speed},
                      onSelectionChanged: (v) {
                        VerseReader.instance.setSpeed(v.first);
                        VerseReader.instance.speak(state.activeDrop.verseText);
                      },
                    ),
                  ),
                  SettingsTile(
                    icon: LogosIcons.moon,
                    title: 'Evening mode',
                    subtitle: 'A darker, quieter look for night reading',
                    ink: ink,
                    trailing: Switch.adaptive(
                      value: widget.examenController.isExamenMode,
                      activeTrackColor: LogosColors.coral,
                      onChanged: (_) => widget.examenController.toggleExamenPreview(),
                    ),
                  ),
                ]),
                SettingsSection('Reminders', ink: ink, children: [ReminderControls(ink: ink)]),
                SettingsSection('Your data', ink: ink, children: [
                  SettingsTile(
                    icon: LogosIcons.cloudUpload,
                    title: 'Back up & restore',
                    subtitle: SupabaseService.instance.isConfigured
                        ? (SupabaseService.instance.isAnonymous ? 'Not backed up yet' : 'Backed up')
                        : 'Coming soon — your journey is saved on this phone',
                    ink: ink,
                    onTap: SupabaseService.instance.isConfigured ? () => showAccountSyncSheet(context) : null,
                  ),
                  SettingsTile(
                    icon: LogosIcons.share,
                    title: 'Export my journal',
                    subtitle: 'Share a text copy of your journey',
                    ink: ink,
                    onTap: () => exportJourneyJournal(state),
                  ),
                  SettingsTile(
                    icon: LogosIcons.delete,
                    title: 'Erase data on this phone',
                    ink: ink,
                    destructive: true,
                    onTap: _eraseData,
                  ),
                ]),
                SettingsSection('About', ink: ink, children: [
                  SettingsTile(
                    icon: LogosIcons.legal,
                    title: 'Privacy policy',
                    ink: ink,
                    onTap: () => _openLink(flags.text(AppFlags.privacyUrl),
                        unavailable: 'The privacy policy will be published before launch.'),
                  ),
                  SettingsTile(
                    icon: LogosIcons.legal,
                    title: 'Terms of use',
                    ink: ink,
                    onTap: () => _openLink(flags.text(AppFlags.termsUrl),
                        unavailable: 'The terms of use will be published before launch.'),
                  ),
                  SettingsTile(
                    icon: LogosIcons.bookOpen,
                    title: 'Translation notices',
                    ink: ink,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const TranslationNoticesScreen())),
                  ),
                  SettingsTile(
                    icon: LogosIcons.mail,
                    title: 'Contact us',
                    ink: ink,
                    onTap: () => _openLink(flags.text(AppFlags.supportEmail),
                        unavailable: 'Support contact is coming soon.'),
                  ),
                  if (_version.isNotEmpty)
                    SettingsTile(icon: LogosIcons.info, title: 'Version', subtitle: _version, ink: ink),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

