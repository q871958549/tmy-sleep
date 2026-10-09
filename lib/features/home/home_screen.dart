import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/section_card.dart';
import '../checkin/checkin_controller.dart';
import '../checkin/checkin_panel.dart';
import '../report/report_card.dart';
import '../schedule/settings_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final checkIns = context.watch<CheckInController>();
    final ready = settingsController.ready && checkIns.ready;

    return Scaffold(
      appBar: AppBar(
        title: const Text('tmy-sleep'),
        actions: [
          IconButton(
            tooltip: '作息设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : _HomeBody(
              settingsController: settingsController,
              checkIns: checkIns,
            ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.settingsController, required this.checkIns});

  final SettingsController settingsController;
  final CheckInController checkIns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final night = checkIns.sleepNight;
    final settings = settingsController.settings;
    final schedule = settings.scheduleFor(night);
    final needsPermission =
        settings.remindersEnabled &&
        !settingsController.access.notificationsGranted;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (needsPermission) ...[
          Card(
            child: ListTile(
              title: const Text('睡前提醒还没有通知权限'),
              subtitle: const Text('打开通知后，到点会提醒你打卡。'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SectionCard(
          title: '今晚目标',
          subtitle: settings.scheduleKindLabel(night),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('入睡', style: theme.textTheme.bodySmall),
              Text(schedule.bedtimeLabel, style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                '起床 ${schedule.wakeLabel}',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '今晚打卡',
          subtitle: '点一下就行。记错了可以改。',
          child: CheckInPanel(log: checkIns.tonight),
        ),
        const SizedBox(height: 12),
        ReportCard(report: checkIns.report),
        const SizedBox(height: 16),
        Text(
          '数据只保存在这台手机上。完全免费，没有广告，也没有内购。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
