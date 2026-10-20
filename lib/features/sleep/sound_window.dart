import 'dart:math' as math;
import 'dart:typed_data';

/// One second-ish slice of microphone audio, reduced to a few numbers.
class SoundWindow {
  const SoundWindow({required this.rms, required this.zcr, this.bandRatio = 0});

  /// Root-mean-square level, 0 to 1, relative to full scale.
  final double rms;

  /// Zero-crossing rate, 0 to 1.
  final double zcr;

  /// Share of energy between 100 Hz and 1000 Hz. Snoring sits in this band.
  final double bandRatio;

  @override
  bool operator ==(Object other) {
    return other is SoundWindow &&
        other.rms == rms &&
        other.zcr == zcr &&
        other.bandRatio == bandRatio;
  }

  @override
  int get hashCode => Object.hash(rms, zcr, bandRatio);
}

/// Reads little-endian 16-bit PCM at 16 kHz. Short buffers are silence.
SoundWindow soundWindowFromPcm16(Uint8List bytes) {
  final samples = bytes.length ~/ 2;
  if (samples < 2) {
    return const SoundWindow(rms: 0, zcr: 0);
  }
  final data = ByteData.sublistView(bytes);
  var sumSquares = 0.0;
  var crossings = 0;
  var previous = 0;
  final wave = samples >= _fftSize ? Float64List(_fftSize) : null;
  for (var index = 0; index < samples; index++) {
    final sample = data.getInt16(index * 2, Endian.little);
    sumSquares += sample * sample;
    if ((sample >= 0 && previous < 0) || (sample < 0 && previous >= 0)) {
      crossings += 1;
    }
    previous = sample;
    if (wave != null && index < _fftSize) {
      wave[index] = sample / 32768.0;
    }
  }
  final rms = math.sqrt(sumSquares / samples) / 32768.0;
  return SoundWindow(
    rms: rms,
    zcr: crossings / samples,
    bandRatio: wave == null ? 0 : lowBandRatio(wave),
  );
}

const _fftSize = 2048;
const _sampleRate = 16000;

/// Fraction of FFT energy from 100 Hz through 1000 Hz.
double lowBandRatio(Float64List samples) {
  if (samples.length < _fftSize) {
    return 0;
  }
  final real = Float64List(_fftSize);
  final imag = Float64List(_fftSize);
  for (var index = 0; index < _fftSize; index++) {
    final hann = 0.5 * (1 - math.cos(2 * math.pi * index / (_fftSize - 1)));
    real[index] = samples[index] * hann;
  }
  _fft(real, imag);
  final binHz = _sampleRate / _fftSize;
  var total = 0.0;
  var band = 0.0;
  for (var bin = 1; bin < _fftSize ~/ 2; bin++) {
    final power = real[bin] * real[bin] + imag[bin] * imag[bin];
    final hz = bin * binHz;
    total += power;
    if (hz >= 100 && hz <= 1000) {
      band += power;
    }
  }
  if (total <= 0) {
    return 0;
  }
  return band / total;
}

void _fft(Float64List real, Float64List imag) {
  final n = real.length;
  var j = 0;
  for (var i = 1; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final swapReal = real[i];
      real[i] = real[j];
      real[j] = swapReal;
      final swapImag = imag[i];
      imag[i] = imag[j];
      imag[j] = swapImag;
    }
  }
  for (var length = 2; length <= n; length <<= 1) {
    final angle = -2 * math.pi / length;
    final stepReal = math.cos(angle);
    final stepImag = math.sin(angle);
    for (var start = 0; start < n; start += length) {
      var turnReal = 1.0;
      var turnImag = 0.0;
      final half = length >> 1;
      for (var k = 0; k < half; k++) {
        final evenReal = real[start + k];
        final evenImag = imag[start + k];
        final oddIndex = start + k + half;
        final oddReal = real[oddIndex] * turnReal - imag[oddIndex] * turnImag;
        final oddImag = real[oddIndex] * turnImag + imag[oddIndex] * turnReal;
        real[start + k] = evenReal + oddReal;
        imag[start + k] = evenImag + oddImag;
        real[oddIndex] = evenReal - oddReal;
        imag[oddIndex] = evenImag - oddImag;
        final nextReal = turnReal * stepReal - turnImag * stepImag;
        turnImag = turnReal * stepImag + turnImag * stepReal;
        turnReal = nextReal;
      }
    }
  }
}

enum SoundGuess { quiet, snore, talk }

/// A rough split, not a medical classifier.
///
/// Snoring is loud, low-crossing, and concentrated between 100 Hz and 1000 Hz.
/// Speech crosses zero more often. A low rumble below that band stays quiet.
SoundGuess classifySound(SoundWindow window) {
  if (window.rms < 0.045) {
    return SoundGuess.quiet;
  }
  if (window.zcr < 0.08 && window.rms >= 0.05 && window.bandRatio >= 0.45) {
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

/// How far the peak sits below digital full scale. This is not a sound-level meter.
int dbBelowFullScale(double rms) {
  final safe = rms.clamp(0.0001, 1.0);
  return (-20 * math.log(safe) / math.ln10).round();
}
