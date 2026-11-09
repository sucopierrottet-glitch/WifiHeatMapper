import 'dart:convert';
import 'dart:math' as math;

enum SignalZone {
  excellent,
  fair,
  deadZone,
}

enum ChannelOverlapStatus {
  clean,
  moderate,
  severe,
}

enum EmfSafetyLevel {
  normal,
  moderate,
  highInterference,
}

class HeatmapSample {
  final String roomId;
  final String roomName;
  final double normalizedX; // 0.0 to 1.0 on floorplan canvas
  final double normalizedY; // 0.0 to 1.0 on floorplan canvas
  final double dbm;
  final double emfMicroTesla;
  final int frequencyMhz;

  const HeatmapSample({
    required this.roomId,
    required this.roomName,
    required this.normalizedX,
    required this.normalizedY,
    required this.dbm,
    this.emfMicroTesla = 46.5,
    this.frequencyMhz = 2437,
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomName': roomName,
        'normalizedX': normalizedX,
        'normalizedY': normalizedY,
        'dbm': dbm,
        'emfMicroTesla': emfMicroTesla,
        'frequencyMhz': frequencyMhz,
      };

  factory HeatmapSample.fromJson(Map<String, dynamic> json) {
    return HeatmapSample(
      roomId: (json['roomId'] as String?) ?? 'living',
      roomName: (json['roomName'] as String?) ?? 'Sala',
      normalizedX: (json['normalizedX'] as num?)?.toDouble() ?? 0.5,
      normalizedY: (json['normalizedY'] as num?)?.toDouble() ?? 0.5,
      dbm: (json['dbm'] as num?)?.toDouble() ?? -58.0,
      emfMicroTesla: (json['emfMicroTesla'] as num?)?.toDouble() ?? 46.5,
      frequencyMhz: (json['frequencyMhz'] as num?)?.toInt() ?? 2437,
    );
  }
}

class OptimalRouterPlacement {
  final double optimalX; // 0.0 to 1.0
  final double optimalY; // 0.0 to 1.0
  final double averageDbm;
  final double coverageScorePercent;
  final String recommendedRoomId;

  const OptimalRouterPlacement({
    required this.optimalX,
    required this.optimalY,
    required this.averageDbm,
    required this.coverageScorePercent,
    required this.recommendedRoomId,
  });
}

class ChannelOverlapResult {
  final int primaryChannel;
  final bool is5Ghz;
  final List<int> overlappingNeighbors;
  final double interferenceScore; // 0 to 100
  final ChannelOverlapStatus status;
  final int recommendedChannel;
  final List<int> nonOverlappingSet;

  const ChannelOverlapResult({
    required this.primaryChannel,
    required this.is5Ghz,
    required this.overlappingNeighbors,
    required this.interferenceScore,
    required this.status,
    required this.recommendedChannel,
    required this.nonOverlappingSet,
  });
}

class EmfClassificationResult {
  final double microTesla;
  final EmfSafetyLevel level;
  final double normalizedIntensity; // 0.0 to 1.0
  final bool safeForRouterPlacement;

  const EmfClassificationResult({
    required this.microTesla,
    required this.level,
    required this.normalizedIntensity,
    required this.safeForRouterPlacement,
  });
}

class FloorplanSurvey {
  final String id;
  final String projectName;
  final String ssid;
  final DateTime createdAt;
  final List<HeatmapSample> samples;
  final int primaryChannel;
  final bool is5Ghz;
  final double peakEmfUt;
  final double optimalRouterX;
  final double optimalRouterY;

  const FloorplanSurvey({
    required this.id,
    required this.projectName,
    required this.ssid,
    required this.createdAt,
    required this.samples,
    required this.primaryChannel,
    required this.is5Ghz,
    required this.peakEmfUt,
    required this.optimalRouterX,
    required this.optimalRouterY,
  });

  double get averageDbm {
    if (samples.isEmpty) return -60.0;
    final sum = samples.fold<double>(0.0, (acc, s) => acc + s.dbm);
    return sum / samples.length;
  }

  double get coverageScore {
    if (samples.isEmpty) return 0.0;
    final sum = samples.fold<double>(
      0.0,
      (acc, s) => acc + WifiCalculator.signalQualityPercent(s.dbm),
    );
    return sum / samples.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectName': projectName,
        'ssid': ssid,
        'createdAt': createdAt.toIso8601String(),
        'samples': samples.map((s) => s.toJson()).toList(),
        'primaryChannel': primaryChannel,
        'is5Ghz': is5Ghz,
        'peakEmfUt': peakEmfUt,
        'optimalRouterX': optimalRouterX,
        'optimalRouterY': optimalRouterY,
      };

  factory FloorplanSurvey.fromJson(Map<String, dynamic> json) {
    final rawSamples = (json['samples'] as List<dynamic>?) ?? [];
    return FloorplanSurvey(
      id: (json['id'] as String?) ?? 'survey-001',
      projectName: (json['projectName'] as String?) ?? 'Planta Principal',
      ssid: (json['ssid'] as String?) ?? 'SimpleApps-Mesh-5G',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime(2026, 10, 15),
      samples: rawSamples
          .map((e) => HeatmapSample.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      primaryChannel: (json['primaryChannel'] as num?)?.toInt() ?? 6,
      is5Ghz: (json['is5Ghz'] as bool?) ?? false,
      peakEmfUt: (json['peakEmfUt'] as num?)?.toDouble() ?? 48.0,
      optimalRouterX: (json['optimalRouterX'] as num?)?.toDouble() ?? 0.5,
      optimalRouterY: (json['optimalRouterY'] as num?)?.toDouble() ?? 0.5,
    );
  }

  String toEncodedJson() => jsonEncode(toJson());
  static FloorplanSurvey fromEncodedJson(String raw) =>
      FloorplanSurvey.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class WifiCalculator {
  /// Converts Wi-Fi RSSI in dBm (-90 dBm to -30 dBm) into a 0..100% quality score.
  static double signalQualityPercent(double dbm) {
    final clamped = dbm.clamp(-90.0, -30.0);
    return ((clamped + 90.0) / 60.0) * 100.0;
  }

  /// Classifies dBm reading into thermal zones:
  /// - Excellent (Green): >= -60 dBm
  /// - Fair (Yellow): -75 dBm <= dbm < -60 dBm
  /// - Dead Zone (Red): < -75 dBm
  static SignalZone classifySignalZone(double dbm) {
    if (dbm >= -60.0) {
      return SignalZone.excellent;
    } else if (dbm >= -75.0) {
      return SignalZone.fair;
    } else {
      return SignalZone.deadZone;
    }
  }

  /// Calculates theoretical Free-Space Path Loss (FSPL) in dB for a given distance (m) and frequency (MHz).
  /// Formula: FSPL(dB) = 20*log10(d_m) + 20*log10(f_MHz) - 27.55
  static double calculateFsplDb({
    required double distanceMeters,
    required double frequencyMhz,
  }) {
    final d = math.max(0.1, distanceMeters);
    final f = math.max(100.0, frequencyMhz);
    final log10d = math.log(d) / math.ln10;
    final log10f = math.log(f) / math.ln10;
    return 20.0 * log10d + 20.0 * log10f - 27.55;
  }

  /// Estimates distance in meters from RSSI (dBm), TX power (dBm), frequency (MHz),
  /// and indoor path-loss exponent (default 2.7 for indoor walls/obstacles).
  static double estimateDistanceMeters({
    required double rssiDbm,
    double txPowerDbm = 20.0,
    double frequencyMhz = 2437.0,
    double pathLossExponent = 2.7,
  }) {
    final f = math.max(100.0, frequencyMhz);
    final n = math.max(1.8, pathLossExponent);
    final pathLossDb = txPowerDbm - rssiDbm;
    // Reference 1-meter free-space loss L0 = 20*log10(f_MHz) - 27.55
    final l0 = (20.0 * (math.log(f) / math.ln10)) - 27.55;
    if (pathLossDb <= l0) {
      return 0.5;
    }
    final exponent = (pathLossDb - l0) / (10.0 * n);
    final meters = math.pow(10.0, exponent).toDouble();
    return meters.clamp(0.5, 150.0);
  }

  /// Returns center frequency in MHz for a 2.4 GHz or 5 GHz Wi-Fi channel.
  static int channelToFrequencyMhz(int channel, {required bool is5Ghz}) {
    if (is5Ghz) {
      return 5000 + (channel * 5);
    }
    if (channel == 14) return 2484;
    return 2407 + (channel * 5);
  }

  /// Analyzes 2.4 GHz (channels 1-14) or 5 GHz (UNII channels 36-165) spectral overlap.
  static ChannelOverlapResult analyzeChannelOverlap({
    required int primaryChannel,
    required List<int> neighborChannels,
    required bool is5Ghz,
  }) {
    final nonOverlapping = is5Ghz
        ? const <int>[36, 40, 44, 48, 149, 153, 157, 161, 165]
        : const <int>[1, 6, 11];

    final overlapping = <int>[];
    double penalty = 0.0;

    for (final neighbor in neighborChannels) {
      final diff = (primaryChannel - neighbor).abs();
      if (!is5Ghz) {
        // 2.4 GHz 20MHz channels are 5MHz apart and 22MHz wide -> overlap if |diff| < 5
        if (diff == 0) {
          overlapping.add(neighbor);
          penalty += 28.0; // Co-channel contention
        } else if (diff < 5) {
          overlapping.add(neighbor);
          // Adjacent-channel interference (ACI) is more destructive than co-channel
          penalty += 36.0 * ((5 - diff) / 4.0);
        }
      } else {
        // 5 GHz 20MHz channels are spaced by 4 channel numbers (20MHz) -> overlap if diff < 4
        if (diff == 0) {
          overlapping.add(neighbor);
          penalty += 25.0;
        } else if (diff < 4) {
          overlapping.add(neighbor);
          penalty += 35.0;
        }
      }
    }

    final score = penalty.clamp(0.0, 100.0);
    final ChannelOverlapStatus status;
    if (score < 15.0) {
      status = ChannelOverlapStatus.clean;
    } else if (score < 55.0) {
      status = ChannelOverlapStatus.moderate;
    } else {
      status = ChannelOverlapStatus.severe;
    }

    // Find best recommended channel from nonOverlapping with minimum penalty against neighborChannels
    int bestChannel = nonOverlapping.first;
    double lowestPenalty = double.infinity;

    for (final candidate in nonOverlapping) {
      double candPenalty = 0.0;
      for (final neighbor in neighborChannels) {
        final diff = (candidate - neighbor).abs();
        if (!is5Ghz) {
          if (diff == 0) {
            candPenalty += 28.0;
          } else if (diff < 5) {
            candPenalty += 36.0 * ((5 - diff) / 4.0);
          }
        } else {
          if (diff == 0) {
            candPenalty += 25.0;
          } else if (diff < 4) {
            candPenalty += 35.0;
          }
        }
      }
      if (candPenalty < lowestPenalty) {
        lowestPenalty = candPenalty;
        bestChannel = candidate;
      }
    }

    return ChannelOverlapResult(
      primaryChannel: primaryChannel,
      is5Ghz: is5Ghz,
      overlappingNeighbors: overlapping,
      interferenceScore: score,
      status: status,
      recommendedChannel: bestChannel,
      nonOverlappingSet: nonOverlapping,
    );
  }

  /// Calculates optimal router coordinates (0.0..1.0, 0.0..1.0) from recorded floorplan samples.
  /// Weak rooms receive higher pull weight so the router shifts to eliminate dead zones while
  /// penalizing rooms with high EMF (>85 µT).
  static OptimalRouterPlacement calculateOptimalRouterPlacement(
    List<HeatmapSample> samples,
  ) {
    if (samples.isEmpty) {
      return const OptimalRouterPlacement(
        optimalX: 0.50,
        optimalY: 0.50,
        averageDbm: -60.0,
        coverageScorePercent: 50.0,
        recommendedRoomId: 'living',
      );
    }

    double weightedX = 0.0;
    double weightedY = 0.0;
    double totalWeight = 0.0;
    double sumDbm = 0.0;
    double sumQuality = 0.0;

    for (final s in samples) {
      sumDbm += s.dbm;
      final quality = signalQualityPercent(s.dbm);
      sumQuality += quality;

      // Deficit weight: weaker signal (-85 dBm) has stronger pull than strong signal (-45 dBm),
      // plus a baseline centrality weight so it stays balanced.
      final deficit = (100.0 - quality) + 35.0;
      // Penalize high EMF locations so router isn't placed on top of a breaker panel
      final emfFactor = s.emfMicroTesla > 90.0 ? 0.55 : 1.0;
      final w = deficit * emfFactor;

      weightedX += s.normalizedX * w;
      weightedY += s.normalizedY * w;
      totalWeight += w;
    }

    // Blend 70% weighted centroid + 30% central hub (0.5, 0.5) for structural wall balance
    final rawX = totalWeight > 0 ? (weightedX / totalWeight) : 0.5;
    final rawY = totalWeight > 0 ? (weightedY / totalWeight) : 0.5;
    final optX = (rawX * 0.75 + 0.5 * 0.25).clamp(0.15, 0.85);
    final optY = (rawY * 0.75 + 0.5 * 0.25).clamp(0.15, 0.85);

    // Closest room to optimal coordinates
    String closestRoom = samples.first.roomId;
    double minDist = double.infinity;
    for (final s in samples) {
      final dx = s.normalizedX - optX;
      final dy = s.normalizedY - optY;
      final dist = dx * dx + dy * dy;
      if (dist < minDist) {
        minDist = dist;
        closestRoom = s.roomId;
      }
    }

    return OptimalRouterPlacement(
      optimalX: optX,
      optimalY: optY,
      averageDbm: sumDbm / samples.length,
      coverageScorePercent: sumQuality / samples.length,
      recommendedRoomId: closestRoom,
    );
  }

  /// Classifies Magnetometer EMF reading in microTesla (µT).
  static EmfClassificationResult classifyEmfLevel(double microTesla) {
    final ut = microTesla.clamp(0.0, 500.0);
    final EmfSafetyLevel level;
    if (ut < 60.0) {
      level = EmfSafetyLevel.normal;
    } else if (ut <= 100.0) {
      level = EmfSafetyLevel.moderate;
    } else {
      level = EmfSafetyLevel.highInterference;
    }

    return EmfClassificationResult(
      microTesla: ut,
      level: level,
      normalizedIntensity: (ut / 150.0).clamp(0.0, 1.0),
      safeForRouterPlacement: ut <= 85.0,
    );
  }
}
