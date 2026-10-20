import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../shared/widgets/ios_section.dart';
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

    return CupertinoPageScaffold(
      backgroundColor: IosColors.background,
      child: ready
          ? _HomeScroll(
              settingsController: settingsController,
              checkIns: checkIns,
            )
          : const Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _HomeScroll extends StatelessWidget {
  const _HomeScroll({required this.settingsController, required this.checkIns});

  final SettingsController settingsController;
  final CheckInController checkIns;

  @override
  Widget build(BuildContext context) {
    final night = checkIns.sleepNight;
    final settings = settingsController.settings;
    final schedule = settings.scheduleFor(night);
    final needsPermission =
        settings.remindersEnabled &&
        !settingsController.access.notificationsGranted;

    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          backgroundColor: IosColors.background,
          border: null,
          largeTitle: const Text('今晚'),
          trailing: Tooltip(
            message: '作息设置',
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: () => context.push('/settings'),
              child: const Icon(CupertinoIcons.gear, size: 22),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          sliver: SliverList.list(
            children: [
              if (needsPermission)
                IosSection(
                  child: IosRow(
                    title: '睡前提醒还没有通知权限',
                    showChevron: true,
                    onTap: () => context.push('/settings'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.scheduleKindLabel(night),
                      style: IosType.section,
                    ),
                    const SizedBox(height: 6),
                    Text(schedule.bedtimeLabel, style: IosType.largeTime),
                    const SizedBox(height: 8),
                    Text(
                      '起床 ${schedule.wakeLabel}',
                      style: IosType.row.copyWith(color: IosColors.secondary),
                    ),
                  ],
                ),
              ),
              CheckInPanel(log: checkIns.tonight),
              ReportCard(report: checkIns.report),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '数据只保存在这台手机上。完全免费，没有广告，也没有内购。',
                  style: IosType.footnote,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
