import 'package:shared_preferences/shared_preferences.dart';
import '../calculators/wifi_calculator.dart';

class TechProfile {
  final String name;
  final String company;
  final String licenseId;

  const TechProfile({
    required this.name,
    required this.company,
    required this.licenseId,
  });
}

class StorageService {
  static const String _surveysKey = 'wifi_saved_surveys_v1';
  static const String _techNameKey = 'wifi_tech_name_v1';
  static const String _techCompanyKey = 'wifi_tech_company_v1';
  static const String _techLicenseKey = 'wifi_tech_license_v1';

  static List<FloorplanSurvey> getDefaultDemoSurveys() {
    return [
      FloorplanSurvey(
        id: 'WF-2026-01',
        projectName: 'Oficina Central & Penthouse A1',
        ssid: 'SimpleApps-Corp-5G',
        createdAt: DateTime(2026, 10, 18, 10, 30),
        primaryChannel: 36,
        is5Ghz: true,
        peakEmfUt: 52.4,
        optimalRouterX: 0.48,
        optimalRouterY: 0.44,
        samples: const [
          HeatmapSample(
            roomId: 'living',
            roomName: 'Sala Principal',
            normalizedX: 0.22,
            normalizedY: 0.26,
            dbm: -48.0,
            emfMicroTesla: 44.0,
            frequencyMhz: 5180,
          ),
          HeatmapSample(
            roomId: 'office',
            roomName: 'Estudio / Oficina',
            normalizedX: 0.52,
            normalizedY: 0.26,
            dbm: -54.0,
            emfMicroTesla: 52.4,
            frequencyMhz: 5180,
          ),
          HeatmapSample(
            roomId: 'master',
            roomName: 'Dormitorio Principal',
            normalizedX: 0.80,
            normalizedY: 0.26,
            dbm: -66.0,
            emfMicroTesla: 41.2,
            frequencyMhz: 5180,
          ),
          HeatmapSample(
            roomId: 'kitchen',
            roomName: 'Cocina / Comedor',
            normalizedX: 0.22,
            normalizedY: 0.72,
            dbm: -62.0,
            emfMicroTesla: 58.0,
            frequencyMhz: 5180,
          ),
          HeatmapSample(
            roomId: 'bedroom2',
            roomName: 'Habitación 2',
            normalizedX: 0.52,
            normalizedY: 0.72,
            dbm: -71.0,
            emfMicroTesla: 45.0,
            frequencyMhz: 5180,
          ),
          HeatmapSample(
            roomId: 'patio',
            roomName: 'Terraza / Patio',
            normalizedX: 0.80,
            normalizedY: 0.72,
            dbm: -79.0,
            emfMicroTesla: 39.5,
            frequencyMhz: 5180,
          ),
        ],
      ),
    ];
  }

  static Future<List<FloorplanSurvey>> loadSurveys() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_surveysKey);
    if (list == null) {
      final defaults = getDefaultDemoSurveys();
      await saveSurveys(defaults);
      return defaults;
    }
    final result = <FloorplanSurvey>[];
    for (final raw in list) {
      try {
        result.add(FloorplanSurvey.fromEncodedJson(raw));
      } catch (_) {}
    }
    return result;
  }

  static Future<void> saveSurveys(List<FloorplanSurvey> surveys) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = surveys.map((s) => s.toEncodedJson()).toList();
    await prefs.setStringList(_surveysKey, encoded);
  }

  static Future<void> addOrUpdateSurvey(FloorplanSurvey survey) async {
    final current = await loadSurveys();
    final idx = current.indexWhere((s) => s.id == survey.id);
    if (idx >= 0) {
      current[idx] = survey;
    } else {
      current.insert(0, survey);
    }
    await saveSurveys(current);
  }

  static Future<void> deleteSurvey(String id) async {
    final current = await loadSurveys();
    current.removeWhere((s) => s.id == id);
    await saveSurveys(current);
  }

  static Future<TechProfile> loadTechProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return TechProfile(
      name: prefs.getString(_techNameKey) ?? 'Ing. Carlos Mendoza',
      company: prefs.getString(_techCompanyKey) ?? 'SimpleApps Telecom & RF Lab',
      licenseId: prefs.getString(_techLicenseKey) ?? 'CWNA-2026-8841',
    );
  }

  static Future<void> saveTechProfile(TechProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_techNameKey, profile.name);
    await prefs.setString(_techCompanyKey, profile.company);
    await prefs.setString(_techLicenseKey, profile.licenseId);
  }
}
