import 'package:flutter/material.dart';

import '../../shared/widgets/section_card.dart';
import 'weekly_report.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({required this.report, super.key});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: '近 7 天',
      subtitle: report.loggedDays == 0
          ? '还没有打卡。记下今晚，明天就能看到变化。'
          : '已打卡 ${report.loggedDays} 天，其中准时 ${report.onTimeDays} 天。'
                '平均推迟把准时记为 0，不含熬夜。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Metric(label: '准时率', value: _rate(report.onTimeRate)),
              _Metric(label: '平均推迟', value: _delay(report.averageDelayMinutes)),
              _Metric(label: '连续准时', value: '${report.streak} 天'),
            ],
          ),
          if (report.stayedUpDays > 0) ...[
            const SizedBox(height: 10),
            Text(
              '这 7 天里熬夜 ${report.stayedUpDays} 天',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _rate(double? rate) {
    if (rate == null) {
      return '—';
    }
    return '${(rate * 100).round()}%';
  }

  static String _delay(double? minutes) {
    if (minutes == null) {
      return '—';
    }
    final rounded = minutes.roundToDouble();
    if ((minutes - rounded).abs() < 0.05) {
      return '${rounded.round()} 分钟';
    }
    return '${minutes.toStringAsFixed(1)} 分钟';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
