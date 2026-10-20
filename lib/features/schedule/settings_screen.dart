import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../shared/widgets/ios_section.dart';
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

    return CupertinoPageScaffold(
      backgroundColor: IosColors.background,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(
            backgroundColor: IosColors.background,
            border: null,
            previousPageTitle: '今晚',
            largeTitle: Text('作息'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: [
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
                          activeTrackColor: IosColors.green,
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
                          activeTrackColor: IosColors.green,
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
                            const Text('稍后提醒', style: IosType.row),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoSlidingSegmentedControl<int>(
                                groupValue: settings.snoozeMinutes,
                                thumbColor: IosColors.thumb,
                                backgroundColor: IosColors.background,
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'tmy-sleep 完全免费，没有广告，也没有内购。',
                    style: IosType.footnote,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: IosColors.grouped,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
