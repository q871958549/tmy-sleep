import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import 'models/app_settings.dart';
import '../../shared/widgets/ios_section.dart';
import '../update/update_coordinator.dart';
import '../update/update_prompt.dart';
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

  Future<void> _checkForUpdates() async {
    final updates = context.read<UpdateCoordinator>();
    if (updates.checking) {
      return;
    }
    final result = await updates.manualCheck();
    if (!mounted) {
      return;
    }
    switch (result.kind) {
      case ManualCheckKind.upToDate:
        await _showNotice(
          title: '已是最新版本',
          message: '当前版本 ${updates.currentVersion}',
        );
      case ManualCheckKind.update:
        final release = result.release;
        if (release == null) {
          return;
        }
        await showReleasePrompt(
          context: context,
          release: release,
          currentVersion: updates.currentVersion,
          installer: updates.installer,
        );
      case ManualCheckKind.failed:
        await _showNotice(title: '暂时无法检查', message: '请稍后再试。需要能访问 GitHub。');
    }
  }

  Future<void> _showNotice({required String title, required String message}) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('好'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final updates = context.watch<UpdateCoordinator>();
    final settings = controller.settings;
    final colors = SleepPalette.of(context);
    final versionLabel = updates.checking
        ? '检查中'
        : updates.available == null
        ? updates.currentVersion
        : '新版本 ${updates.available!.version}';

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: colors.background,
            border: null,
            previousPageTitle: '今晚',
            largeTitle: Text('作息'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: [
                IosSection(
                  header: '外观',
                  footer: '可以选择浅色、深色，或跟着系统。入睡记录那一页保持深色，避免刺眼。',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<AppThemeMode>(
                        groupValue: settings.themeMode,
                        thumbColor: colors.thumb,
                        backgroundColor: colors.background,
                        children: {
                          AppThemeMode.system: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('跟随系统', style: IosType.section(colors)),
                          ),
                          AppThemeMode.light: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('浅色', style: IosType.section(colors)),
                          ),
                          AppThemeMode.dark: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('深色', style: IosType.section(colors)),
                          ),
                        },
                        onValueChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          HapticFeedback.selectionClick();
                          controller.setThemeMode(value);
                        },
                      ),
                    ),
                  ),
                ),
                IosSection(
                  header: '工作日',
                  footer: '周一到周五',
                  child: Column(
                    children: [
                      IosRow(
                        title: '入睡',
                        value: settings.weekday.bedtimeLabel,
                        showChevron: true,
                        onTap: () => _pickTime(
                          current: settings.weekday,
                          bedtime: true,
                          onChanged: controller.setWeekday,
                        ),
                      ),
                      const IosDivider(),
                      IosRow(
                        title: '起床',
                        value: settings.weekday.wakeLabel,
                        showChevron: true,
                        onTap: () => _pickTime(
                          current: settings.weekday,
                          bedtime: false,
                          onChanged: controller.setWeekday,
                        ),
                      ),
                    ],
                  ),
                ),
                IosSection(
                  header: '周末',
                  footer: '周六和周日可以单独设置',
                  child: Column(
                    children: [
                      IosRow(
                        title: '周末单独作息',
                        trailing: CupertinoSwitch(
                          key: const Key('weekend-switch'),
                          value: settings.useSeparateWeekend,
                          activeTrackColor: colors.green,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            controller.setUseSeparateWeekend(value);
                          },
                        ),
                      ),
                      if (settings.useSeparateWeekend) ...[
                        const IosDivider(),
                        IosRow(
                          title: '周末入睡',
                          value: settings.weekend.bedtimeLabel,
                          showChevron: true,
                          onTap: () => _pickTime(
                            current: settings.weekend,
                            bedtime: true,
                            onChanged: controller.setWeekend,
                          ),
                        ),
                        const IosDivider(),
                        IosRow(
                          title: '周末起床',
                          value: settings.weekend.wakeLabel,
                          showChevron: true,
                          onTap: () => _pickTime(
                            current: settings.weekend,
                            bedtime: false,
                            onChanged: controller.setWeekend,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IosSection(
                  header: '睡前提醒',
                  footer: [
                    '本地通知，不会上传。可稍后提醒 15 或 30 分钟。',
                    if (controller.scheduleResult.note != null)
                      controller.scheduleResult.note!,
                  ].join('\n'),
                  child: Column(
                    children: [
                      IosRow(
                        title: '到点提醒',
                        trailing: CupertinoSwitch(
                          key: const Key('reminders-switch'),
                          value: settings.remindersEnabled,
                          activeTrackColor: colors.green,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            controller.setRemindersEnabled(value);
                          },
                        ),
                      ),
                      const IosDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('稍后提醒', style: IosType.row(colors)),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoSlidingSegmentedControl<int>(
                                groupValue: settings.snoozeMinutes,
                                thumbColor: colors.thumb,
                                backgroundColor: colors.background,
                                children: const {
                                  15: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('15 分钟'),
                                  ),
                                  30: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text('30 分钟'),
                                  ),
                                },
                                onValueChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  HapticFeedback.selectionClick();
                                  controller.setSnoozeMinutes(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const IosDivider(),
                      IosRow(
                        title: '通知权限',
                        value: controller.access.notificationsGranted
                            ? '已允许'
                            : '未允许',
                      ),
                      const IosDivider(),
                      IosRow(
                        title: '精确闹钟',
                        value: controller.access.exactAlarmsGranted
                            ? '已允许'
                            : '未允许',
                      ),
                      const IosDivider(),
                      IosRow(
                        title: '申请权限',
                        showChevron: true,
                        onTap: controller.requestReminderAccess,
                      ),
                      const IosDivider(),
                      IosRow(
                        title: '打开系统设置',
                        showChevron: true,
                        onTap: openAppSettings,
                      ),
                    ],
                  ),
                ),
                IosSection(
                  header: '版本',
                  footer: '每天凌晨 4 点后第一次打开应用时会自动检查。发现新版本会提示，也可以在这里手动检查。安装包来自 GitHub Releases。',
                  child: IosRow(
                    title: '检查更新',
                    value: versionLabel,
                    trailing: updates.checking
                        ? const CupertinoActivityIndicator()
                        : null,
                    showChevron: true,
                    onTap: _checkForUpdates,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'tmy-sleep 完全免费，没有广告，也没有内购。',
                    style: IosType.footnote(colors),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime({
    required DaySchedule current,
    required bool bedtime,
    required Future<void> Function(DaySchedule schedule) onChanged,
  }) async {
    final initial = TimeOfDay(
      hour: bedtime ? current.bedtimeHour : current.wakeHour,
      minute: bedtime ? current.bedtimeMinute : current.wakeMinute,
    );
    final picked = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) => _TimeSheet(initial: initial),
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

class _TimeSheet extends StatefulWidget {
  const _TimeSheet({required this.initial});

  final TimeOfDay initial;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late TimeOfDay _time = widget.initial;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final colors = SleepPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.grouped,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(_time),
                    child: const Text(
                      '完成',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  widget.initial.hour,
                  widget.initial.minute,
                ),
                onDateTimeChanged: (value) {
                  _time = TimeOfDay(hour: value.hour, minute: value.minute);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
