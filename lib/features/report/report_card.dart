import 'package:flutter/widgets.dart';

import '../../app/theme.dart';
import '../../shared/widgets/ios_section.dart';
import 'weekly_report.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({required this.report, super.key});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final footer = report.loggedDays == 0
        ? '还没有打卡。记下今晚，明天就能看到变化。'
        : '已打卡 ${report.loggedDays} 天，其中准时 ${report.onTimeDays} 天。'
              '平均推迟把准时记为 0，不含熬夜。'
              '${report.stayedUpDays > 0 ? ' 这 7 天里熬夜 ${report.stayedUpDays} 天。' : ''}';
    return IosSection(
      header: '近 7 天',
      footer: footer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _Metric(label: '准时率', value: _rate(report.onTimeRate)),
            const _Rule(),
            _Metric(label: '平均推迟', value: _delay(report.averageDelayMinutes)),
            const _Rule(),
            _Metric(label: '连续准时', value: '${report.streak} 天'),
          ],
        ),
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
    return Expanded(
      child: Column(
        children: [
          Text(value, style: IosType.metric, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label, style: IosType.section, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 0.5,
      height: 36,
      child: ColoredBox(color: IosColors.separator),
    );
  }
}
