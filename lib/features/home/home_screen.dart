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
import '../sleep/models/sleep_event.dart';
import '../sleep/sleep_controller.dart';
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
    final sleep = context.watch<SleepSessionController>();
    final ready = settingsController.ready && checkIns.ready;
    final colors = SleepPalette.of(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      child: ready
          ? _HomeScroll(
              settingsController: settingsController,
              checkIns: checkIns,
              updateVersion: updates.available?.version,
              onUpdateTap: _openAvailable,
              sleep: sleep,
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
    required this.sleep,
  });

  final SettingsController settingsController;
  final CheckInController checkIns;
  final String? updateVersion;
  final VoidCallback onUpdateTap;
  final SleepSessionController sleep;

  @override
  Widget build(BuildContext context) {
    final night = checkIns.sleepNight;
    final settings = settingsController.settings;
    final schedule = settings.scheduleFor(night);
    final needsPermission =
        settings.remindersEnabled &&
        !settingsController.access.notificationsGranted;
    final colors = SleepPalette.of(context);
    final tonight = sleep.sessionFor(night);
    final sleepLabel = tonight != null && tonight.isOpen ? '回到记录' : '立即入睡';

    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          backgroundColor: colors.background,
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
                      style: IosType.section(colors),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      schedule.bedtimeLabel,
                      style: IosType.largeTime(colors),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '起床 ${schedule.wakeLabel}',
                      style: IosType.row(colors)
                          .copyWith(color: colors.secondary),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  key: const Key('sleep-now'),
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(14),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: () => context.push('/sleep'),
                  child: Text(
                    sleepLabel,
                    style: IosType.row(colors).copyWith(
                      color: colors.onAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                child: Text(
                  '点下去开始记鼾声、梦话和翻身。记录页会保持深色。',
                  style: IosType.footnote(colors),
                ),
              ),
              if (tonight != null && tonight.events.isNotEmpty)
                IosSection(
                  header: '今晚的记录',
                  footer: tonight.note ?? '每条记下持续多久。声音还有相对满幅的峰值，不是房间里的分贝计。',
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            for (final kind in SleepEventKind.values)
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${tonight.countOf(kind)}',
                                      style: IosType.metric(colors),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      kind.label,
                                      style: IosType.section(colors),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      for (final event in tonight.events.reversed.take(8)) ...[
                        const IosDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.clockLabel,
                                style: IosType.row(colors),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${event.kind.label}  ${event.detail}',
                                  style: IosType.value(colors),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              CheckInPanel(log: checkIns.tonight),
              ReportCard(report: checkIns.report),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '数据只保存在这台手机上。完全免费，没有广告，也没有内购。',
                  style: IosType.footnote(colors),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
