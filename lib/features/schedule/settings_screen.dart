import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/section_card.dart';
import 'models/day_schedule.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<SettingsController>().refreshAccess());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('作息设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          SectionCard(
            title: '工作日',
            subtitle: '周一到周五',
            child: Column(
              children: [
                _TimeRow(
                  label: '入睡',
                  value: settings.weekday.bedtimeLabel,
                  onTap: () => _pickTime(
                    context,
                    current: settings.weekday,
                    bedtime: true,
                    onChanged: controller.setWeekday,
                  ),
                ),
                _TimeRow(
                  label: '起床',
                  value: settings.weekday.wakeLabel,
                  onTap: () => _pickTime(
                    context,
                    current: settings.weekday,
                    bedtime: false,
                    onChanged: controller.setWeekday,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '周末',
            subtitle: '周六和周日可以单独设置',
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('weekend-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('周末单独作息'),
                  value: settings.useSeparateWeekend,
                  onChanged: controller.setUseSeparateWeekend,
                ),
                if (settings.useSeparateWeekend) ...[
                  _TimeRow(
                    label: '周末入睡',
                    value: settings.weekend.bedtimeLabel,
                    onTap: () => _pickTime(
                      context,
                      current: settings.weekend,
                      bedtime: true,
                      onChanged: controller.setWeekend,
                    ),
                  ),
                  _TimeRow(
                    label: '周末起床',
                    value: settings.weekend.wakeLabel,
                    onTap: () => _pickTime(
                      context,
                      current: settings.weekend,
                      bedtime: false,
                      onChanged: controller.setWeekend,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '睡前提醒',
            subtitle: '本地通知，不会上传。可稍后提醒 15 或 30 分钟。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  key: const Key('reminders-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('到点提醒'),
                  value: settings.remindersEnabled,
                  onChanged: controller.setRemindersEnabled,
                ),
                const SizedBox(height: 8),
                Text('稍后提醒', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 15, label: Text('15 分钟')),
                    ButtonSegment(value: 30, label: Text('30 分钟')),
                  ],
                  selected: {settings.snoozeMinutes},
                  onSelectionChanged: (values) {
                    controller.setSnoozeMinutes(values.first);
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  '通知权限：${controller.access.notificationsGranted ? '已允许' : '未允许'}',
                ),
                const SizedBox(height: 4),
                Text(
                  '精确闹钟：${controller.access.exactAlarmsGranted ? '已允许' : '未允许'}',
                ),
                if (controller.scheduleResult.note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.scheduleResult.note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: controller.requestReminderAccess,
                      child: const Text('申请权限'),
                    ),
                    TextButton(
                      onPressed: openAppSettings,
                      child: const Text('打开系统设置'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'tmy-sleep 完全免费，没有广告，也没有内购。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context, {
    required DaySchedule current,
    required bool bedtime,
    required Future<void> Function(DaySchedule schedule) onChanged,
  }) async {
    final initial = TimeOfDay(
      hour: bedtime ? current.bedtimeHour : current.wakeHour,
      minute: bedtime ? current.bedtimeMinute : current.wakeMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) {
      return;
    }
    final next = bedtime
        ? current.copyWith(
            bedtimeHour: picked.hour,
            bedtimeMinute: picked.minute,
          )
        : current.copyWith(wakeHour: picked.hour, wakeMinute: picked.minute);
    await onChanged(next);
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
