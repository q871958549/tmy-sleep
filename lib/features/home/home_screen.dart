import 'dart:async';

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
import '../update/update_coordinator.dart';
import '../update/update_prompt.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  var _checking = false;
  var _promptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_promptIfNeeded());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_promptIfNeeded());
    }
  }

  /// Once per sleep day (the day rolls at 04:00). A failed check stays quiet
  /// and tries again the next time the app comes forward.
  Future<void> _promptIfNeeded() async {
    if (!mounted || _promptOpen || _checking) {
      return;
    }
    _checking = true;
    try {
      final updates = context.read<UpdateCoordinator>();
      final release = await updates.autoCheck();
      if (!mounted || release == null || _promptOpen) {
        return;
      }
      _promptOpen = true;
      await showReleasePrompt(
        context: context,
        release: release,
        currentVersion: updates.currentVersion,
        installer: updates.installer,
      );
    } finally {
      _checking = false;
      _promptOpen = false;
    }
  }

  Future<void> _openAvailable() async {
    final updates = context.read<UpdateCoordinator>();
    final release = updates.available;
    if (release == null || _promptOpen) {
      return;
    }
    _promptOpen = true;
    await showReleasePrompt(
      context: context,
      release: release,
      currentVersion: updates.currentVersion,
      installer: updates.installer,
    );
    _promptOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final checkIns = context.watch<CheckInController>();
    final updates = context.watch<UpdateCoordinator>();
    final ready = settingsController.ready && checkIns.ready;

    return CupertinoPageScaffold(
      backgroundColor: IosColors.background,
      child: ready
          ? _HomeScroll(
              settingsController: settingsController,
              checkIns: checkIns,
              updateVersion: updates.available?.version,
              onUpdateTap: _openAvailable,
            )
          : const Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _HomeScroll extends StatelessWidget {
  const _HomeScroll({
    required this.settingsController,
    required this.checkIns,
    required this.updateVersion,
    required this.onUpdateTap,
  });

  final SettingsController settingsController;
  final CheckInController checkIns;
  final String? updateVersion;
  final VoidCallback onUpdateTap;

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
              if (updateVersion != null)
                IosSection(
                  child: IosRow(
                    title: '可更新到 $updateVersion',
                    showChevron: true,
                    onTap: onUpdateTap,
                  ),
                ),
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
