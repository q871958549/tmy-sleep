import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../shared/widgets/ios_section.dart';
import 'checkin_controller.dart';
import 'models/daily_log.dart';
import 'models/sleep_check_in.dart';

class CheckInPanel extends StatelessWidget {
  const CheckInPanel({required this.log, super.key});

  final DailyLog? log;

  Future<void> _choose(BuildContext context, SleepCheckIn kind) async {
    HapticFeedback.selectionClick();
    if (kind == SleepCheckIn.delayed) {
      final minutes = await showCupertinoModalPopup<int>(
        context: context,
        builder: (context) => _DelaySheet(selected: log?.delayMinutes),
      );
      if (!context.mounted || minutes == null) {
        return;
      }
      await _save(context, kind, delayMinutes: minutes);
      return;
    }
    await _save(context, kind);
  }

  Future<void> _save(
    BuildContext context,
    SleepCheckIn kind, {
    int? delayMinutes,
  }) async {
    try {
      await context.read<CheckInController>().checkIn(
        kind,
        delayMinutes: delayMinutes,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('没有保存'),
          content: const Text('打卡没有写入这台手机，请再试一次。'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('好'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = log?.checkIn;
    final colors = SleepPalette.of(context);
    return IosSection(
      header: '今晚打卡',
      footer: log?.summary ?? '点一下就行。记错了可以改。',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<SleepCheckIn>(
            groupValue: selected,
            thumbColor: colors.thumb,
            backgroundColor: colors.background,
            children: {
              for (final kind in SleepCheckIn.values)
                kind: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    kind.label,
                    style: IosType.row(colors).copyWith(fontSize: 15),
                  ),
                ),
            },
            onValueChanged: (kind) {
              if (kind == null) {
                return;
              }
              _choose(context, kind);
            },
          ),
        ),
      ),
    );
  }
}

class _DelaySheet extends StatelessWidget {
  const _DelaySheet({required this.selected});

  final int? selected;

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
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: colors.separator,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text('推迟了多久？', style: IosType.row(colors)),
            ),
            for (final minutes in delayMinuteChoices) ...[
              const IosDivider(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => Navigator.of(context).pop(minutes),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$minutes 分钟',
                            style: IosType.row(colors),
                          ),
                        ),
                        if (selected == minutes)
                          Icon(
                            CupertinoIcons.check_mark,
                            color: colors.accent,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
