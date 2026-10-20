import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'sound_window.dart';

/// A microphone window or a motion sample from the phone.
sealed class SleepSample {}

class SoundSample extends SleepSample {
  SoundSample(this.window);

  final SoundWindow window;
}

class MotionSample extends SleepSample {
  MotionSample(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class MonitorNote extends SleepSample {
  MonitorNote(this.message);

  final String message;
}

abstract interface class SleepMonitor {
  Stream<SleepSample> get samples;

  Future<void> start();

  Future<void> stop();
}

class PlatformSleepMonitor implements SleepMonitor {
  PlatformSleepMonitor();

  static const _windowBytes = 16000 * 2;

  final _samples = StreamController<SleepSample>.broadcast();
  final _pending = BytesBuilder(copy: false);
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audio;
  StreamSubscription<UserAccelerometerEvent>? _motion;
  var _running = false;

  @override
  Stream<SleepSample> get samples => _samples.stream;

  @override
  Future<void> start() async {
    if (_running) {
      return;
    }
    _running = true;
    if (kIsWeb) {
      _emit(MonitorNote('网页里不能记录鼾声、梦话和异动。请在 Android 上使用，并保持入睡页打开。'));
      return;
    }
    await _startMicrophone();
    await _startMotion();
  }

  Future<void> _startMicrophone() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _emit(MonitorNote('没有麦克风权限，这次只记录手机的晃动。'));
        return;
      }
      final recorder = AudioRecorder();
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      _recorder = recorder;
      _audio = stream.listen(
        _onPcm,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('microphone stream failed: $error\n$stackTrace');
          _emit(MonitorNote('麦克风中断了，晃动记录还在。'));
        },
      );
    } catch (error, stackTrace) {
      debugPrint('microphone start failed: $error\n$stackTrace');
      _emit(MonitorNote('这台设备暂时听不到声音，这次只记录手机的晃动。'));
    }
  }

  void _onPcm(Uint8List chunk) {
    _pending.add(chunk);
    final bytes = _pending.toBytes();
    if (bytes.length < _windowBytes) {
      return;
    }
    final window = Uint8List.sublistView(bytes, 0, _windowBytes);
    _pending.clear();
    if (bytes.length > _windowBytes) {
      _pending.add(Uint8List.sublistView(bytes, _windowBytes));
    }
    _emit(SoundSample(soundWindowFromPcm16(window)));
  }

  Future<void> _startMotion() async {
    try {
      _motion =
          userAccelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval,
          ).listen(
            (event) => _emit(MotionSample(event.x, event.y, event.z)),
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('motion stream failed: $error\n$stackTrace');
            },
          );
    } catch (error, stackTrace) {
      debugPrint('motion start failed: $error\n$stackTrace');
    }
  }

  void _emit(SleepSample sample) {
    if (!_samples.isClosed) {
      _samples.add(sample);
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _audio?.cancel();
    _audio = null;
    await _motion?.cancel();
    _motion = null;
    final recorder = _recorder;
    _recorder = null;
    _pending.clear();
    if (recorder != null) {
      try {
        await recorder.stop();
        await recorder.dispose();
      } catch (error, stackTrace) {
        debugPrint('microphone stop failed: $error\n$stackTrace');
      }
    }
  }
}
