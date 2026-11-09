import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifiheatmapper/calculators/wifi_calculator.dart';
import 'package:wifiheatmapper/l10n/app_strings.dart';
import 'package:wifiheatmapper/main.dart';

void main() {
  group('WifiCalculator Deterministic RF & EMF Unit Tests', () {
    test('Signal quality score & zone classification from dBm (-30 to -90 dBm)', () {
      expect(WifiCalculator.signalQualityPercent(-30.0), closeTo(100.0, 0.01));
      expect(WifiCalculator.signalQualityPercent(-60.0), closeTo(50.0, 0.01));
      expect(WifiCalculator.signalQualityPercent(-90.0), closeTo(0.0, 0.01));

      expect(WifiCalculator.classifySignalZone(-50.0), SignalZone.excellent);
      expect(WifiCalculator.classifySignalZone(-68.0), SignalZone.fair);
      expect(WifiCalculator.classifySignalZone(-82.0), SignalZone.deadZone);
    });

    test('Free-Space Path Loss (FSPL) & distance estimator', () {
      final fspl10m = WifiCalculator.calculateFsplDb(
        distanceMeters: 10.0,
        frequencyMhz: 2437.0,
      );
      expect(fspl10m, greaterThan(55.0));
      expect(fspl10m, lessThan(65.0));

      final nearDist = WifiCalculator.estimateDistanceMeters(
        rssiDbm: -45.0,
        txPowerDbm: 20.0,
        frequencyMhz: 2437.0,
      );
      final farDist = WifiCalculator.estimateDistanceMeters(
        rssiDbm: -80.0,
        txPowerDbm: 20.0,
        frequencyMhz: 2437.0,
      );
      expect(farDist, greaterThan(nearDist));
    });

    test('2.4GHz and 5GHz channel overlap analyzer', () {
      final congested24 = WifiCalculator.analyzeChannelOverlap(
        primaryChannel: 6,
        neighborChannels: [5, 6, 7],
        is5Ghz: false,
      );
      expect(congested24.status, ChannelOverlapStatus.severe);
      expect(congested24.recommendedChannel, anyOf(1, 11));

      final clean50 = WifiCalculator.analyzeChannelOverlap(
        primaryChannel: 149,
        neighborChannels: [36, 40, 44],
        is5Ghz: true,
      );
      expect(clean50.status, ChannelOverlapStatus.clean);
      expect(clean50.overlappingNeighbors, isEmpty);
    });

    test('Optimal router coordinates from grid samples', () {
      const samples = [
        HeatmapSample(
          roomId: 'living',
          roomName: 'Sala',
          normalizedX: 0.20,
          normalizedY: 0.25,
          dbm: -48.0,
        ),
        HeatmapSample(
          roomId: 'patio',
          roomName: 'Terraza',
          normalizedX: 0.80,
          normalizedY: 0.75,
          dbm: -84.0,
        ),
      ];
      final opt = WifiCalculator.calculateOptimalRouterPlacement(samples);
      // Should pull slightly toward the weak (-84 dBm) room at (0.80, 0.75)
      expect(opt.optimalX, greaterThan(0.50));
      expect(opt.optimalY, greaterThan(0.50));
      expect(opt.averageDbm, closeTo(-66.0, 0.01));
    });

    test('EMF microTesla safety & interference level classification', () {
      expect(
        WifiCalculator.classifyEmfLevel(45.0).level,
        EmfSafetyLevel.normal,
      );
      expect(
        WifiCalculator.classifyEmfLevel(75.0).level,
        EmfSafetyLevel.moderate,
      );
      expect(
        WifiCalculator.classifyEmfLevel(125.0).level,
        EmfSafetyLevel.highInterference,
      );
      expect(
        WifiCalculator.classifyEmfLevel(125.0).safeForRouterPlacement,
        isFalse,
      );
    });
  });

  group('WifiHeatMapper App Widget & Navigation Tests', () {
    testWidgets('WelcomeLandingScreen enters HomeNavigationScreen and switches ES/EN/PT', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final langController = LanguageController();
      await langController.loadSavedLanguage();

      await tester.pumpWidget(
        WifiHeatMapperApp(languageController: langController),
      );
      await tester.pumpAndSettle();

      // Verify WelcomeLandingScreen & btnWelcomeEnter key
      final enterBtn = find.byKey(const Key('btnWelcomeEnter'));
      expect(enterBtn, findsOneWidget);

      await tester.ensureVisible(enterBtn);
      await tester.tap(enterBtn);
      await tester.pumpAndSettle();

      // Verify Floorplan Heatmap Canvas is shown on Tab 0
      expect(find.byKey(const Key('floorplanHeatmapCanvas')), findsOneWidget);

      // Tap on the floorplan canvas to record a room sample
      await tester.tap(find.byKey(const Key('floorplanHeatmapCanvas')));
      await tester.pump();

      // Navigate to Settings Tab (index 3) and test 1-tap language switching
      final bottomNav = find.byKey(const Key('mainBottomNav'));
      expect(bottomNav, findsOneWidget);

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();

      // Switch to English
      await tester.tap(find.byKey(const Key('langBtn_en')));
      await tester.pumpAndSettle();
      expect(langController.langCode, 'en');
      expect(find.text('Settings & Engineer Profile'), findsOneWidget);

      // Switch to Portuguese
      await tester.tap(find.byKey(const Key('langBtn_pt')));
      await tester.pumpAndSettle();
      expect(langController.langCode, 'pt');
      expect(find.text('Configurações e Perfil Técnico'), findsOneWidget);
    });
  });
}
