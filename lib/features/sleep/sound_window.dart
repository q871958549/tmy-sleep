import 'dart:math' as math;
import 'dart:typed_data';

/// One second-ish slice of microphone audio, reduced to two numbers.
class SoundWindow {
  const SoundWindow({required this.rms, required this.zcr});

  /// Root-mean-square level, 0 to 1.
  final double rms;

  /// Zero-crossing rate, 0 to 1.
  final double zcr;
}

/// Reads little-endian 16-bit PCM. Short buffers are treated as silence.
SoundWindow soundWindowFromPcm16(Uint8List bytes) {
  final samples = bytes.length ~/ 2;
  if (samples < 2) {
    return const SoundWindow(rms: 0, zcr: 0);
  }
  final data = ByteData.sublistView(bytes);
  var sumSquares = 0.0;
  var crossings = 0;
  var previous = 0;
  for (var index = 0; index < samples; index++) {
    final sample = data.getInt16(index * 2, Endian.little);
    sumSquares += sample * sample;
    if ((sample >= 0 && previous < 0) || (sample < 0 && previous >= 0)) {
      crossings += 1;
    }
    previous = sample;
  }
  final rms = math.sqrt(sumSquares / samples) / 32768.0;
  return SoundWindow(rms: rms, zcr: crossings / samples);
}

enum SoundGuess { quiet, snore, talk }

/// A rough split, not a medical classifier.
///
/// Snoring sits at a low zero-crossing rate. Speech crosses zero more often.
SoundGuess classifySound(SoundWindow window) {
  if (window.rms < 0.045) {
    return SoundGuess.quiet;
  }
  if (window.zcr < 0.08 && window.rms >= 0.05) {
    return SoundGuess.snore;
  }
  if (window.zcr >= 0.12 && window.rms >= 0.05) {
    return SoundGuess.talk;
  }
  return SoundGuess.quiet;
}

/// User acceleration with gravity removed, in meters per second squared.
bool isMovement(double x, double y, double z) {
  final magnitude = math.sqrt(x * x + y * y + z * z);
  return magnitude >= 2.5;
}
