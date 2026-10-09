import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'checkin_controller.dart';
import 'models/daily_log.dart';
import 'models/sleep_check_in.dart';

class CheckInPanel extends StatefulWidget {
  const CheckInPanel({required this.log, super.key});

  final DailyLog? log;

  @override
  State<CheckInPanel> createState() => _CheckInPanelState();
}

class _CheckInPanelState extends State<CheckInPanel> {
  bool _pickingDelay = false;

  Future<void> _save(SleepCheckIn kind, {int? delayMinutes}) async {
    try {
      await context.read<CheckInController>().checkIn(
        kind,
        delayMinutes: delayMinutes,
      );
      if (mounted) {
        setState(() => _pickingDelay = false);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('打卡没有保存，请再试一次')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (log != null) ...[
          Text(log.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in SleepCheckIn.values)
              _ChoiceButton(
                label: kind.label,
                selected: log?.checkIn == kind && !_pickingDelay,
                onPressed: () {
                  if (kind == SleepCheckIn.delayed) {
                    setState(() => _pickingDelay = true);
                    return;
                  }
                  _save(kind);
                },
              ),
          ],
        ),
        if (_pickingDelay) ...[
          const SizedBox(height: 14),
          Text('推迟了多久？', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in delayMinuteChoices)
                _ChoiceButton(
                  label: '$minutes 分钟',
                  selected:
                      log?.checkIn == SleepCheckIn.delayed &&
                      log?.delayMinutes == minutes,
                  onPressed: () =>
                      _save(SleepCheckIn.delayed, delayMinutes: minutes),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
