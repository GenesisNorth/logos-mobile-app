import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/logos_icons.dart';
import '../../core/theme/logos_theme.dart';
import 'settings_widgets.dart';

/// Daily reminder on/off, time, and evening reflection. Shared by Settings and
/// the bell sheet on the home screen.
class ReminderControls extends StatefulWidget {
  final Color ink;
  const ReminderControls({super.key, required this.ink});

  @override
  State<ReminderControls> createState() => _ReminderControlsState();
}

class _ReminderControlsState extends State<ReminderControls> {
  final _n = NotificationService.instance;

  String _format(int minutes) => MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

  Future<void> _toggle(bool on) async {
    await _n.toggleNotifications(on);
    if (!mounted) return;
    setState(() {});
    if (on && !_n.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notifications are blocked. Allow them in your phone’s settings to get reminders.'),
      ));
    }
  }

  Future<void> _pickTime() async {
    final m = _n.reminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      helpText: 'Daily reminder',
    );
    if (picked == null) return;
    await _n.setReminderMinutes(picked.hour * 60 + picked.minute);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final divider = Divider(height: 1, indent: 52, color: LogosColors.taupe.withValues(alpha: 0.7));
    return Column(
      children: [
        SettingsTile(
          icon: LogosIcons.notificationsActive,
          title: 'Daily reminder',
          subtitle: _n.isEnabled ? 'A gentle nudge for today’s step' : 'Off',
          ink: ink,
          trailing: Switch.adaptive(value: _n.isEnabled, activeTrackColor: LogosColors.coral, onChanged: _toggle),
        ),
        if (_n.isEnabled) ...[
          divider,
          SettingsTile(
            icon: LogosIcons.clock,
            title: 'Reminder time',
            subtitle: _format(_n.reminderMinutes),
            ink: ink,
            onTap: _pickTime,
          ),
          divider,
          SettingsTile(
            icon: LogosIcons.bedtimeOutlined,
            title: 'Evening reflection',
            subtitle: 'A short prompt at ${_format(NotificationService.eveningMinutes)}',
            ink: ink,
            trailing: Switch.adaptive(
              value: _n.eveningReflection,
              activeTrackColor: LogosColors.coral,
              onChanged: (v) async {
                await _n.setEveningReflection(v);
                if (mounted) setState(() {});
              },
            ),
          ),
        ],
      ],
    );
  }
}
