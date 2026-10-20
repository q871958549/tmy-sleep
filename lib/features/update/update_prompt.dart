import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import 'app_release.dart';
import 'update_installer.dart';

Future<void> showReleasePrompt({
  required BuildContext context,
  required AppRelease release,
  required String currentVersion,
  required UpdateInstaller installer,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UpdateDialog(
      release: release,
      currentVersion: currentVersion,
      installer: installer,
    ),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.release,
    required this.currentVersion,
    required this.installer,
  });

  final AppRelease release;
  final String currentVersion;
  final UpdateInstaller installer;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _working = false;
  bool _cancelled = false;
  double? _progress;
  String? _status;

  Future<void> _update() async {
    setState(() {
      _working = true;
      _cancelled = false;
      _progress = widget.release.apkUrl == null ? null : 0;
      _status = widget.release.apkUrl == null ? '正在打开下载页' : '正在下载更新';
    });
    final outcome = await widget.installer.install(
      widget.release,
      onProgress: (value) {
        if (!mounted || _cancelled) {
          return;
        }
        setState(() => _progress = value);
      },
      isCancelled: () => _cancelled,
    );
    if (!mounted || _cancelled) {
      return;
    }
    switch (outcome) {
      case InstallOutcome.openedInstaller:
      case InstallOutcome.openedBrowser:
        Navigator.of(context).pop();
      case InstallOutcome.needPermission:
        setState(() {
          _working = false;
          _status = '需要允许安装应用';
        });
        await _askForPermission();
      case InstallOutcome.cancelled:
        setState(() => _working = false);
      case InstallOutcome.failed:
        setState(() {
          _working = false;
          _status = '下载没有完成';
        });
    }
  }

  Future<void> _askForPermission() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('允许安装更新'),
        content: const Text('请在系统设置里允许 tmy-sleep 安装应用，然后回到这里再点一次「立即更新」。'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(widget.installer.openInstallPermissionSettings());
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _cancel() {
    _cancelled = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.release.notes.trim();
    final actionLabel = widget.release.apkUrl == null ? '打开下载页' : '立即更新';
    final colors = SleepPalette.of(context);
    return CupertinoAlertDialog(
      title: const Text('发现新版本'),
      content: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            '当前 ${widget.currentVersion}，可更新到 ${widget.release.version}',
            style: IosType.footnote(colors).copyWith(color: colors.label),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(notes, style: IosType.footnote(colors)),
              ),
            ),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(_status!, style: IosType.footnote(colors)),
            const SizedBox(height: 8),
            if (_progress == null)
              const CupertinoActivityIndicator()
            else
              Text(
                '${(_progress! * 100).round()}%',
                style: IosType.row(colors),
              ),
          ],
        ],
      ),
      actions: [
        if (_working)
          CupertinoDialogAction(onPressed: _cancel, child: const Text('取消'))
        else ...[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('以后再说'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _update,
            child: Text(actionLabel),
          ),
        ],
      ],
    );
  }
}
