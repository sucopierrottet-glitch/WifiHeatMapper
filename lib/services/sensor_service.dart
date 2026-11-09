import 'dart:math' as math;
import 'package:flutter/services.dart';

class SensorSnapshot {
  final double magFieldUt;
  final double mx;
  final double my;
  final double mz;
  final double azimuth;
  final double pitch;
  final double roll;
  final double simulatedWifiDbm;
  final bool hasNativeMag;

  const SensorSnapshot({
    required this.magFieldUt,
    required this.mx,
    required this.my,
    required this.mz,
    required this.azimuth,
    required this.pitch,
    required this.roll,
    required this.simulatedWifiDbm,
    required this.hasNativeMag,
  });
}

class SensorService {
  static const MethodChannel _channel =
      MethodChannel('com.simpleappspg.sensors/data');

  double _calibratedBaseDbm = -54.0;
  double _manualEmfOffsetUt = 0.0;
  int _tick = 0;

  double get calibratedBaseDbm => _calibratedBaseDbm;
  set calibratedBaseDbm(double value) {
    _calibratedBaseDbm = value.clamp(-90.0, -30.0);
  }

  double get manualEmfOffsetUt => _manualEmfOffsetUt;
  set manualEmfOffsetUt(double value) {
    _manualEmfOffsetUt = value.clamp(-40.0, 200.0);
  }

  Future<SensorSnapshot> getSensorSnapshot() async {
    _tick++;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSensorSnapshot',
      );
      if (raw != null) {
        final magUt =
            ((raw['magFieldUt'] as num?)?.toDouble() ?? 46.5) + _manualEmfOffsetUt;
        final mx = (raw['mx'] as num?)?.toDouble() ?? 18.0;
        final my = (raw['my'] as num?)?.toDouble() ?? 24.0;
        final mz = (raw['mz'] as num?)?.toDouble() ?? -35.0;
        final azimuth = (raw['azimuth'] as num?)?.toDouble() ?? 0.0;
        final pitch = (raw['pitch'] as num?)?.toDouble() ?? 0.0;
        final roll = (raw['roll'] as num?)?.toDouble() ?? 0.0;
        final hasMag = (raw['hasMag'] as bool?) ?? false;

        // Subtle realistic Wi-Fi RSSI ripple (+/- 1.5 dBm) plus slight EMF noise floor coupling
        final emfPenalty = magUt > 95.0 ? -3.5 : 0.0;
        final ripple = math.sin(_tick * 0.45) * 1.2;
        final dbm = (_calibratedBaseDbm + ripple + emfPenalty).clamp(-90.0, -30.0);

        return SensorSnapshot(
          magFieldUt: magUt.clamp(5.0, 400.0),
          mx: mx,
          my: my,
          mz: mz,
          azimuth: azimuth,
          pitch: pitch,
          roll: roll,
          simulatedWifiDbm: dbm,
          hasNativeMag: hasMag,
        );
      }
    } catch (_) {
      // Fallback when running in widget test or desktop environment
    }

    final ripple = math.sin(_tick * 0.4) * 1.0;
    final magUt = (46.5 + _manualEmfOffsetUt + math.cos(_tick * 0.3) * 1.5)
        .clamp(5.0, 400.0);
    final dbm = (_calibratedBaseDbm + ripple).clamp(-90.0, -30.0);

    return SensorSnapshot(
      magFieldUt: magUt,
      mx: 19.4,
      my: -14.2,
      mz: 39.8,
      azimuth: (_tick * 6.0) % 360.0,
      pitch: 2.5,
      roll: -1.2,
      simulatedWifiDbm: dbm,
      hasNativeMag: false,
    );
  }
}
