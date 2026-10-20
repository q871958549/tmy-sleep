import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';

/// Inset grouped block: small header, rounded surface, optional footnote.
class IosSection extends StatelessWidget {
  const IosSection({required this.child, this.header, this.footer, super.key});

  final String? header;
  final String? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(header!, style: IosType.section),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: IosColors.grouped,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(footer!, style: IosType.footnote),
            ),
        ],
      ),
    );
  }
}

class IosDivider extends StatelessWidget {
  const IosDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: IosColors.grouped,
      child: Padding(
        padding: EdgeInsets.only(left: 16),
        child: ColoredBox(
          color: IosColors.separator,
          child: SizedBox(height: 0.5, width: double.infinity),
        ),
      ),
    );
  }
}

/// Settings-style row. Minimum height follows the iOS 44pt target.
class IosRow extends StatelessWidget {
  const IosRow({
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    super.key,
  });

  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(title, style: IosType.row)),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(value!, style: IosType.value),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: IosColors.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) {
      return row;
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Align(alignment: Alignment.centerLeft, child: row),
    );
  }
}
