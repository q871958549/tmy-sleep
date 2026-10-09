# tmy-sleep

免费、开源的入睡作息记录应用。用 Flutter 写成，优先支持 Android，工程里保留了 iOS 工程，方便以后接上。

它只做四件事：

1. 设置目标入睡和起床时间（工作日，以及可选的周末）
2. 到点发一条本地睡前提醒，可以稍后 15 或 30 分钟再提醒
3. 一键打卡：准时、推迟、熬夜
4. 看最近 7 天：准时率、平均推迟分钟、连续准时天数

**永远免费。** 没有广告，没有内购，没有付费墙，也没有账号和云同步。打卡和设置都存在这台手机的 `shared_preferences` 里。

许可：[MIT](LICENSE)。

## 不会做的事

穿戴设备、麦克风睡眠分期、AI 分析、云同步、社交、支付，都不在这个应用里。

## 环境

- Flutter stable（本仓库用 3.47 / Dart 3.13 开发）
- Android 设备或模拟器，已打开 USB 调试
- 最低系统版本跟随 Flutter 默认（当前为 Android 7.0 / API 24）

安装 Flutter：<https://docs.flutter.dev/get-started/install>

## 运行

```bash
flutter pub get
flutter run
```

指定设备：

```bash
flutter devices
flutter run -d <deviceId>
```

检查：

```bash
flutter analyze
flutter test
```

首次启动且「到点提醒」开着时，会请求通知权限。精确闹钟不会在每次打开应用时自动跳进系统设置；在设置页点「申请权限」，或重新打开「到点提醒」时才会去申请。从系统设置返回后，应用会重新读取权限并重排提醒。数据写在本机，关掉应用再打开，作息和打卡还在。

作息日在凌晨 4:00 切换。凌晨 4 点以前打卡，记在前一天晚上。

## Android 通知和精确闹钟

睡前提醒用 `flutter_local_notifications` 排未来 7 次入睡时间。工作日和周末时间不同，所以按天分别排，而不是一条每天重复的闹钟。改设置或重新打开应用时会重排。

需要的权限写在 `android/app/src/main/AndroidManifest.xml`：

| 权限 | 作用 |
| --- | --- |
| `POST_NOTIFICATIONS` | Android 13+ 才能显示通知。没允许的话，闹钟排了也看不见。 |
| `SCHEDULE_EXACT_ALARM` | Android 12+ 的精确闹钟。用户可以在系统设置里关掉。 |
| `RECEIVE_BOOT_COMPLETED` | 重启后由插件把已排好的通知重新登记。 |
| `VIBRATE` | 通知震动。 |

精确闹钟的限制：

- 这里用的是 `SCHEDULE_EXACT_ALARM`，不是 `USE_EXACT_ALARM`。后者会自动授予，但上架应用商店时可能要额外审核，本应用不声明它。
- Android 12 起，用户可以在「设置 → 应用 → 特殊应用权限 → 闹钟和提醒」里关闭精确闹钟。Android 14 起，这个权限默认可能是关闭的，需要应用申请。
- 设置页会显示通知权限和精确闹钟是否已允许。「申请权限」会打开精确闹钟设置；「打开系统设置」进入应用详情。从这些页面返回后会重新读取权限。
- 没拿到精确闹钟时，应用改用非精确闹钟（`inexactAllowWhileIdle`）。系统为了省电，可能把提醒推迟几分钟甚至更久。省电模式、厂商后台限制也会影响送达。
- 通知上的「15 分钟后提醒」或「30 分钟后提醒」由设置里的稍后时长决定。点它会再排一条一次性通知；应用在后台时由通知插件的后台 isolate 处理。
- 排程依赖 Java 8+ 的 desugaring，已在 `android/app/build.gradle.kts` 打开。

iOS 工程可以编译进同一套界面和数据层，但这个 MVP 没有在真机上验证 iOS 通知。接 iOS 时还要在系统里允许通知。

## 目录

```
lib/
  main.dart
  app/                  主题和路由
  core/storage/         shared_preferences JSON
  core/notifications/   本地睡前提醒
  features/schedule/    作息模型和设置页
  features/checkin/     打卡
  features/report/      7 天统计
  features/home/        首页
  shared/
```

## English

tmy-sleep is a free, open-source Flutter app for people who want a steadier bedtime and wake time. Android is the first platform. The iOS runner is in the repo so it can be picked up later.

The MVP lets you:

1. Set a target bedtime and wake time for weekdays, with an optional weekend schedule
2. Get a local bedtime notification, with a 15- or 30-minute snooze
3. Check in with one tap: on time, delayed, or stayed up
4. See a 7-day summary: on-time rate, average delay in minutes, and the current on-time streak

There is no monetization. No ads, no in-app purchases, no paywall, no account, and no cloud sync. Settings and check-ins stay on the device. The license is [MIT](LICENSE).

Wearables, microphone sleep staging, AI analysis, social features, and payments are out of scope.

### Run on Android

Install Flutter stable (developed against 3.47 / Dart 3.13): <https://docs.flutter.dev/get-started/install>

```bash
flutter pub get
flutter devices
flutter run -d <deviceId>
flutter analyze
flutter test
```

The sleep night rolls over at 04:00 local time, so a check-in before then still belongs to the previous evening.

On first launch, if bedtime reminders are on, the app asks for notification permission. It does not jump to the exact-alarm settings on every start. Use **申请权限** on the settings screen (or turn reminders off and on) for that. Coming back to the app refreshes the permission state and reschedules alarms.

### Notification caveats

Bedtime alarms are scheduled with `flutter_local_notifications` for the next seven upcoming bedtimes (separate weekday and weekend times). They are refreshed when settings change and when the app starts.

- `POST_NOTIFICATIONS`: required to show notifications on Android 13 and newer.
- `SCHEDULE_EXACT_ALARM`: exact alarms on Android 12 and newer. The user can revoke this under Settings → Apps → Special app access → Alarms & reminders. On Android 14 it may be off until the app asks. This project does **not** declare `USE_EXACT_ALARM`.
- If exact alarms are not granted, scheduling falls back to inexact alarms, which Doze and OEM battery savers may delay.
- `RECEIVE_BOOT_COMPLETED` lets the plugin restore scheduled notifications after reboot.
- The snooze action (15 or 30 minutes, chosen in settings) posts another one-shot notification, including from a background isolate when the app is not open.
- Core library desugaring is enabled in `android/app/build.gradle.kts`, which the notifications plugin needs for scheduled alarms.

The iOS project shares the UI and storage code. iOS notification delivery is not verified for this MVP.
