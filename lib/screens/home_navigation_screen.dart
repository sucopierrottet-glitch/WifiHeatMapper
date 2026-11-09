import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../calculators/wifi_calculator.dart';
import '../l10n/app_strings.dart';
import '../services/pdf_report_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RoomZoneSpec {
  final String id;
  final String translationKey;
  final Rect normalizedRect;

  const RoomZoneSpec({
    required this.id,
    required this.translationKey,
    required this.normalizedRect,
  });

  Offset get center => normalizedRect.center;
}

const List<RoomZoneSpec> kDefaultFloorplanRooms = [
  RoomZoneSpec(
    id: 'living',
    translationKey: 'roomLiving',
    normalizedRect: Rect.fromLTWH(0.04, 0.06, 0.30, 0.42),
  ),
  RoomZoneSpec(
    id: 'office',
    translationKey: 'roomOffice',
    normalizedRect: Rect.fromLTWH(0.35, 0.06, 0.30, 0.42),
  ),
  RoomZoneSpec(
    id: 'master',
    translationKey: 'roomMaster',
    normalizedRect: Rect.fromLTWH(0.66, 0.06, 0.30, 0.42),
  ),
  RoomZoneSpec(
    id: 'kitchen',
    translationKey: 'roomKitchen',
    normalizedRect: Rect.fromLTWH(0.04, 0.52, 0.30, 0.42),
  ),
  RoomZoneSpec(
    id: 'bedroom2',
    translationKey: 'roomBedroom2',
    normalizedRect: Rect.fromLTWH(0.35, 0.52, 0.30, 0.42),
  ),
  RoomZoneSpec(
    id: 'patio',
    translationKey: 'roomPatio',
    normalizedRect: Rect.fromLTWH(0.66, 0.52, 0.30, 0.42),
  ),
];

class HomeNavigationScreen extends StatefulWidget {
  final LanguageController languageController;
  final int initialTabIndex;

  const HomeNavigationScreen({
    super.key,
    required this.languageController,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  late int _currentTab;
  final SensorService _sensorService = SensorService();
  Timer? _sensorTimer;

  SensorSnapshot _snapshot = const SensorSnapshot(
    magFieldUt: 46.5,
    mx: 18.2,
    my: -12.4,
    mz: 38.0,
    azimuth: 45.0,
    pitch: 1.2,
    roll: -0.8,
    simulatedWifiDbm: -54.0,
    hasNativeMag: false,
  );

  // Floorplan state
  final TextEditingController _surveyNameCtrl = TextEditingController(
    text: 'Oficina Central & Penthouse A1',
  );
  final TextEditingController _ssidCtrl = TextEditingController(
    text: 'SimpleApps-Mesh-5G',
  );
  String _selectedRoomId = 'living';
  double _calibratedDbm = -54.0;
  List<HeatmapSample> _samples = [];

  // Spectrum & FSPL state
  bool _is5Ghz = false;
  int _primaryChannel = 6;
  final List<int> _neighbor24Channels = [1, 3, 6, 9, 11];
  final List<int> _neighbor50Channels = [36, 40, 44, 149];
  double _txPowerDbm = 20.0;
  double _emfCalibrationOffset = 0.0;

  // Saved surveys & Tech profile
  List<FloorplanSurvey> _savedSurveys = [];
  final TextEditingController _techNameCtrl = TextEditingController();
  final TextEditingController _techCompanyCtrl = TextEditingController();
  final TextEditingController _techLicenseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTabIndex;
    _initDefaultFloorplanSamples();
    _loadPersistedData();
    _pollSensors();
    _sensorTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _pollSensors(),
    );
  }

  void _initDefaultFloorplanSamples() {
    final defaults = StorageService.getDefaultDemoSurveys().first.samples;
    _samples = List<HeatmapSample>.from(defaults);
  }

  Future<void> _loadPersistedData() async {
    final surveys = await StorageService.loadSurveys();
    final profile = await StorageService.loadTechProfile();
    if (!mounted) return;
    setState(() {
      _savedSurveys = surveys;
      _techNameCtrl.text = profile.name;
      _techCompanyCtrl.text = profile.company;
      _techLicenseCtrl.text = profile.licenseId;
    });
  }

  Future<void> _pollSensors() async {
    final snap = await _sensorService.getSensorSnapshot();
    if (!mounted) return;
    setState(() {
      _snapshot = snap;
    });
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _surveyNameCtrl.dispose();
    _ssidCtrl.dispose();
    _techNameCtrl.dispose();
    _techCompanyCtrl.dispose();
    _techLicenseCtrl.dispose();
    super.dispose();
  }

  void _recordRoomSample(String roomId, AppStrings s, {Offset? tapNormalized}) {
    final spec = kDefaultFloorplanRooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => kDefaultFloorplanRooms.first,
    );
    final pos = tapNormalized ?? spec.center;
    final freq = WifiCalculator.channelToFrequencyMhz(
      _primaryChannel,
      is5Ghz: _is5Ghz,
    );

    final newSample = HeatmapSample(
      roomId: spec.id,
      roomName: s.get(spec.translationKey),
      normalizedX: pos.dx.clamp(0.05, 0.95),
      normalizedY: pos.dy.clamp(0.05, 0.95),
      dbm: _calibratedDbm,
      emfMicroTesla: _snapshot.magFieldUt,
      frequencyMhz: freq,
    );

    setState(() {
      _selectedRoomId = spec.id;
      final existingIdx = _samples.indexWhere((e) => e.roomId == spec.id);
      if (existingIdx >= 0) {
        _samples[existingIdx] = newSample;
      } else {
        _samples.add(newSample);
      }
    });
  }

  void _handleCanvasTap(
    TapDownDetails details,
    Size canvasSize,
    AppStrings s,
  ) {
    final nx = (details.localPosition.dx / canvasSize.width).clamp(0.05, 0.95);
    final ny = (details.localPosition.dy / canvasSize.height).clamp(0.05, 0.95);
    final tapPt = Offset(nx, ny);

    RoomZoneSpec matched = kDefaultFloorplanRooms.first;
    for (final room in kDefaultFloorplanRooms) {
      if (room.normalizedRect.contains(tapPt)) {
        matched = room;
        break;
      }
    }
    _recordRoomSample(matched.id, s, tapNormalized: tapPt);
  }

  Future<void> _saveCurrentSurvey(AppStrings s) async {
    final opt = WifiCalculator.calculateOptimalRouterPlacement(_samples);
    double peakEmf = _snapshot.magFieldUt;
    for (final sample in _samples) {
      if (sample.emfMicroTesla > peakEmf) {
        peakEmf = sample.emfMicroTesla;
      }
    }

    final survey = FloorplanSurvey(
      id: 'WF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      projectName: _surveyNameCtrl.text.trim().isEmpty
          ? 'Planta Wi-Fi Pro'
          : _surveyNameCtrl.text.trim(),
      ssid: _ssidCtrl.text.trim().isEmpty
          ? 'SimpleApps-5G'
          : _ssidCtrl.text.trim(),
      createdAt: DateTime.now(),
      samples: List<HeatmapSample>.from(_samples),
      primaryChannel: _primaryChannel,
      is5Ghz: _is5Ghz,
      peakEmfUt: peakEmf,
      optimalRouterX: opt.optimalX,
      optimalRouterY: opt.optimalY,
    );

    await StorageService.addOrUpdateSurvey(survey);
    final updated = await StorageService.loadSurveys();
    if (!mounted) return;
    setState(() {
      _savedSurveys = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.get('surveySavedMsg')),
        backgroundColor: AppTheme.surfaceElevated,
      ),
    );
  }

  Future<void> _openSignatureAndExportModal(
    FloorplanSurvey survey,
    AppStrings s,
  ) async {
    final sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.get('signatureDialogTitle'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.get('signatureDialogSub'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentCyan, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Signature(
                    controller: sigController,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => sigController.clear(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(s.get('clearSignature')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('btnConfirmGeneratePdf'),
                      onPressed: () async {
                        Uint8List? sigBytes;
                        if (sigController.isNotEmpty) {
                          sigBytes = await sigController.toPngBytes();
                        }
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        final profile = TechProfile(
                          name: _techNameCtrl.text.trim().isEmpty
                              ? 'Ing. Carlos Mendoza'
                              : _techNameCtrl.text.trim(),
                          company: _techCompanyCtrl.text.trim().isEmpty
                              ? 'SimpleApps Telecom Lab'
                              : _techCompanyCtrl.text.trim(),
                          licenseId: _techLicenseCtrl.text.trim().isEmpty
                              ? 'CWNA-2026'
                              : _techLicenseCtrl.text.trim(),
                        );
                        await PdfReportService.previewAndSharePdf(
                          survey: survey,
                          techProfile: profile,
                          signaturePngBytes: sigBytes,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: Text(s.get('generatePdfNow')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.languageController,
      builder: (context, _) {
        final s = AppStrings.of(widget.languageController.langCode);
        return Scaffold(
          backgroundColor: AppTheme.backgroundObsidian,
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(
                  Icons.wifi_tethering_rounded,
                  color: AppTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.get('appTitle'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${_snapshot.magFieldUt.toStringAsFixed(1)} µT',
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(
            index: _currentTab,
            children: [
              _buildHeatmapTab(s),
              _buildChannelAndEmfRadarTab(s),
              _buildSavedSurveysTab(s),
              _buildSettingsTab(s),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            key: const Key('mainBottomNav'),
            selectedIndex: _currentTab,
            onDestinationSelected: (idx) => setState(() => _currentTab = idx),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map_rounded),
                label: s.get('tabHeatmap'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.radar_outlined),
                selectedIcon: const Icon(Icons.radar_rounded),
                label: s.get('tabRadar'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                selectedIcon: const Icon(Icons.picture_as_pdf_rounded),
                label: s.get('tabSurveys'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: s.get('tabSettings'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: INTERACTIVE FLOORPLAN THERMAL HEATMAP CANVAS
  // ---------------------------------------------------------------------------
  Widget _buildHeatmapTab(AppStrings s) {
    final optPlacement = WifiCalculator.calculateOptimalRouterPlacement(_samples);
    final currentQuality = WifiCalculator.signalQualityPercent(_calibratedDbm);
    final currentDist = WifiCalculator.estimateDistanceMeters(
      rssiDbm: _calibratedDbm,
      txPowerDbm: _txPowerDbm,
      frequencyMhz: WifiCalculator.channelToFrequencyMhz(
        _primaryChannel,
        is5Ghz: _is5Ghz,
      ).toDouble(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project & SSID Header Inputs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _surveyNameCtrl,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: s.get('surveyNameLabel'),
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.apartment_rounded,
                          size: 18,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _ssidCtrl,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: s.get('ssidLabel'),
                        isDense: true,
                        prefixIcon: const Icon(
                          Icons.wifi_rounded,
                          size: 18,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Live KPI Row
          Row(
            children: [
              Expanded(
                child: _KpiTile(
                  label: s.get('calibratedDbm'),
                  value: '${_calibratedDbm.toStringAsFixed(0)} dBm',
                  sub: '${currentQuality.toStringAsFixed(0)}% ${s.get("signalQuality")}',
                  accent: _calibratedDbm >= -60
                      ? AppTheme.accentGreen
                      : (_calibratedDbm >= -75
                          ? AppTheme.accentAmber
                          : AppTheme.accentRed),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  label: s.get('estDistance'),
                  value: '${currentDist.toStringAsFixed(1)} m',
                  sub: _is5Ghz ? '5 GHz FSPL' : '2.4 GHz FSPL',
                  accent: AppTheme.accentCyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KpiTile(
                  label: s.get('optimalRouterPos'),
                  value:
                      'X:${(optPlacement.optimalX * 100).toStringAsFixed(0)}% Y:${(optPlacement.optimalY * 100).toStringAsFixed(0)}%',
                  sub:
                      '${s.get("coverageScore")}: ${optPlacement.coverageScorePercent.toStringAsFixed(0)}%',
                  accent: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Floorplan Canvas Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.get('tapFloorplanHint'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 265,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return GestureDetector(
                          key: const Key('floorplanHeatmapCanvas'),
                          onTapDown: (details) =>
                              _handleCanvasTap(details, size, s),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomPaint(
                              size: size,
                              painter: FloorplanHeatmapPainter(
                                rooms: kDefaultFloorplanRooms,
                                samples: _samples,
                                selectedRoomId: _selectedRoomId,
                                optimalPlacement: optPlacement,
                                strings: s,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Legend
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _LegendDot(
                        color: AppTheme.accentGreen,
                        text: s.get('legendExcellent'),
                      ),
                      _LegendDot(
                        color: AppTheme.accentAmber,
                        text: s.get('legendFair'),
                      ),
                      _LegendDot(
                        color: AppTheme.accentRed,
                        text: s.get('legendWeak'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Room Selector Chips + Signal Calibration Slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kDefaultFloorplanRooms.map((room) {
                      final isSelected = _selectedRoomId == room.id;
                      return ChoiceChip(
                        key: Key('roomChip_${room.id}'),
                        label: Text(s.get(room.translationKey)),
                        selected: isSelected,
                        selectedColor:
                            AppTheme.accentGreen.withValues(alpha: 0.25),
                        onSelected: (_) {
                          setState(() => _selectedRoomId = room.id);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${s.get("calibratedDbm")}: ${_calibratedDbm.toStringAsFixed(0)} dBm',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        'EMF: ${_snapshot.magFieldUt.toStringAsFixed(1)} µT',
                        style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    key: const Key('sliderCalibratedDbm'),
                    value: _calibratedDbm,
                    min: -90.0,
                    max: -30.0,
                    divisions: 60,
                    label: '${_calibratedDbm.toStringAsFixed(0)} dBm',
                    onChanged: (val) {
                      setState(() {
                        _calibratedDbm = val;
                        _sensorService.calibratedBaseDbm = val;
                      });
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const Key('btnRecordRoomSample'),
                          onPressed: () => _recordRoomSample(_selectedRoomId, s),
                          icon: const Icon(Icons.add_location_alt_rounded),
                          label: Text(s.get('recordPointBtn')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        key: const Key('btnSaveSurvey'),
                        onPressed: () => _saveCurrentSurvey(s),
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(s.get('saveSurveyBtn')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: CHANNEL OVERLAP & MAGNETOMETER EMF RADAR
  // ---------------------------------------------------------------------------
  Widget _buildChannelAndEmfRadarTab(AppStrings s) {
    final activeNeighbors = _is5Ghz ? _neighbor50Channels : _neighbor24Channels;
    final overlapResult = WifiCalculator.analyzeChannelOverlap(
      primaryChannel: _primaryChannel,
      neighborChannels: activeNeighbors,
      is5Ghz: _is5Ghz,
    );
    final emfClass = WifiCalculator.classifyEmfLevel(_snapshot.magFieldUt);
    final freqMhz = WifiCalculator.channelToFrequencyMhz(
      _primaryChannel,
      is5Ghz: _is5Ghz,
    ).toDouble();
    final fsplEstMeters = WifiCalculator.estimateDistanceMeters(
      rssiDbm: _calibratedDbm,
      txPowerDbm: _txPowerDbm,
      frequencyMhz: freqMhz,
    );

    final channelChoices = _is5Ghz
        ? const <int>[36, 40, 44, 48, 149, 153, 157, 161, 165]
        : const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Spectrum & Channel Overlap Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.get('spectrumTitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          key: const Key('chipBand24'),
                          label: Text(s.get('band24')),
                          selected: !_is5Ghz,
                          onSelected: (_) {
                            setState(() {
                              _is5Ghz = false;
                              _primaryChannel = 6;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          key: const Key('chipBand50'),
                          label: Text(s.get('band50')),
                          selected: _is5Ghz,
                          onSelected: (_) {
                            setState(() {
                              _is5Ghz = true;
                              _primaryChannel = 36;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      painter: SpectrumOverlapPainter(
                        primaryChannel: _primaryChannel,
                        neighborChannels: activeNeighbors,
                        is5Ghz: _is5Ghz,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: channelChoices.map((ch) {
                      final selected = _primaryChannel == ch;
                      return InkWell(
                        onTap: () => setState(() => _primaryChannel = ch),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.accentGreen
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ch $ch',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? const Color(0xFF04140B)
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.get("overlapStatus")}: ${overlapResult.status == ChannelOverlapStatus.clean ? s.get("overlapClean") : (overlapResult.status == ChannelOverlapStatus.moderate ? s.get("overlapModerate") : s.get("overlapSevere"))}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: overlapResult.status ==
                                    ChannelOverlapStatus.clean
                                ? AppTheme.accentGreen
                                : (overlapResult.status ==
                                        ChannelOverlapStatus.moderate
                                    ? AppTheme.accentAmber
                                    : AppTheme.accentRed),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s.get("recommendedChannels")}: ${overlapResult.nonOverlappingSet.join(", ")} (Best: Ch ${overlapResult.recommendedChannel})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Magnetometer EMF Interference Radar Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.get('emfRadarTitle'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _snapshot.hasNativeMag
                              ? s.get('sensorLive')
                              : s.get('sensorSim'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 165,
                    child: CustomPaint(
                      painter: EmfRadarPainter(
                        microTesla: _snapshot.magFieldUt,
                        azimuthDeg: _snapshot.azimuth,
                        level: emfClass.level,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    emfClass.level == EmfSafetyLevel.normal
                        ? s.get('emfSafe')
                        : (emfClass.level == EmfSafetyLevel.moderate
                            ? s.get('emfCaution')
                            : s.get('emfHigh')),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: emfClass.level == EmfSafetyLevel.normal
                          ? AppTheme.accentGreen
                          : (emfClass.level == EmfSafetyLevel.moderate
                              ? AppTheme.accentAmber
                              : AppTheme.accentRed),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _emfCalibrationOffset,
                    min: -20.0,
                    max: 120.0,
                    divisions: 70,
                    label:
                        'Offset: ${_emfCalibrationOffset.toStringAsFixed(0)} µT',
                    onChanged: (val) {
                      setState(() {
                        _emfCalibrationOffset = val;
                        _sensorService.manualEmfOffsetUt = val;
                      });
                      _pollSensors();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. FSPL Distance Estimator Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.get('fsplTitle'),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${s.get("txPowerLabel")}: ${_txPowerDbm.toStringAsFixed(0)} dBm • ${s.get("estDistance")}: ${fsplEstMeters.toStringAsFixed(1)} m',
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: _txPowerDbm,
                    min: 12.0,
                    max: 30.0,
                    divisions: 18,
                    onChanged: (v) => setState(() => _txPowerDbm = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: SAVED FLOORPLAN SURVEYS & SIGNED PDF REPORTS
  // ---------------------------------------------------------------------------
  Widget _buildSavedSurveysTab(AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.get('savedSurveysTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (_savedSurveys.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.get('noSurveysYet'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ..._savedSurveys.map((survey) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              survey.projectName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${survey.coverageScore.toStringAsFixed(0)}% ${s.get("coverageScore")}',
                              style: const TextStyle(
                                color: AppTheme.accentGreen,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'SSID: ${survey.ssid} • ${survey.samples.length} ${s.get("samplesCount")} • ${s.get("avgSignal")}: ${survey.averageDbm.toStringAsFixed(1)} dBm • EMF: ${survey.peakEmfUt.toStringAsFixed(1)} µT',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _surveyNameCtrl.text = survey.projectName;
                                _ssidCtrl.text = survey.ssid;
                                _samples = List<HeatmapSample>.from(
                                  survey.samples,
                                );
                                _is5Ghz = survey.is5Ghz;
                                _primaryChannel = survey.primaryChannel;
                                _currentTab = 0;
                              });
                            },
                            icon: const Icon(Icons.map_rounded, size: 17),
                            label: Text(s.get('loadSurveyBtn')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              key: Key('btnExportPdf_${survey.id}'),
                              onPressed: () =>
                                  _openSignatureAndExportModal(survey, s),
                              icon: const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 17,
                              ),
                              label: Text(s.get('exportPdfBtn')),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await StorageService.deleteSurvey(survey.id);
                              final list = await StorageService.loadSurveys();
                              if (!mounted) return;
                              setState(() => _savedSurveys = list);
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.accentRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: SETTINGS & 1-TAP TRILINGUAL SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildSettingsTab(AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.get('settingsTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        // 1-Tap Trilingual Switcher Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.get('languageLabel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LanguageButton(
                      key: const Key('langBtn_es'),
                      code: 'es',
                      label: 'Español (ES)',
                      isSelected: widget.languageController.langCode == 'es',
                      onTap: () => widget.languageController.setLanguage('es'),
                    ),
                    const SizedBox(width: 8),
                    _LanguageButton(
                      key: const Key('langBtn_en'),
                      code: 'en',
                      label: 'English (EN)',
                      isSelected: widget.languageController.langCode == 'en',
                      onTap: () => widget.languageController.setLanguage('en'),
                    ),
                    const SizedBox(width: 8),
                    _LanguageButton(
                      key: const Key('langBtn_pt'),
                      code: 'pt',
                      label: 'Português (PT)',
                      isSelected: widget.languageController.langCode == 'pt',
                      onTap: () => widget.languageController.setLanguage('pt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Technician Profile Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.get('techProfileTitle'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _techNameCtrl,
                  decoration: InputDecoration(
                    labelText: s.get('techNameLabel'),
                    prefixIcon: const Icon(Icons.engineering_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _techCompanyCtrl,
                  decoration: InputDecoration(
                    labelText: s.get('techCompanyLabel'),
                    prefixIcon: const Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _techLicenseCtrl,
                  decoration: InputDecoration(
                    labelText: s.get('techLicenseLabel'),
                    prefixIcon: const Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  key: const Key('btnSaveTechProfile'),
                  onPressed: () async {
                    await StorageService.saveTechProfile(
                      TechProfile(
                        name: _techNameCtrl.text.trim(),
                        company: _techCompanyCtrl.text.trim(),
                        licenseId: _techLicenseCtrl.text.trim(),
                      ),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.get('profileSavedMsg'))),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(s.get('saveProfileBtn')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Pro Unlocked Forever Banner
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.accentGreen,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.get('proForeverTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.get('proForeverSub'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Privacy Policy Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.get('privacyPolicyTitle'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentCyan,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.get('privacyPolicyBody'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================

class FloorplanHeatmapPainter extends CustomPainter {
  final List<RoomZoneSpec> rooms;
  final List<HeatmapSample> samples;
  final String selectedRoomId;
  final OptimalRouterPlacement optimalPlacement;
  final AppStrings strings;

  FloorplanHeatmapPainter({
    required this.rooms,
    required this.samples,
    required this.selectedRoomId,
    required this.optimalPlacement,
    required this.strings,
  });

  Color _zoneColor(double dbm) {
    final zone = WifiCalculator.classifySignalZone(dbm);
    switch (zone) {
      case SignalZone.excellent:
        return AppTheme.accentGreen;
      case SignalZone.fair:
        return AppTheme.accentAmber;
      case SignalZone.deadZone:
        return AppTheme.accentRed;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF080D16);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle blueprint grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 1. Paint Thermal Heatmap Radial Blooms for each sample
    for (final sample in samples) {
      final center = Offset(
        sample.normalizedX * size.width,
        sample.normalizedY * size.height,
      );
      final color = _zoneColor(sample.dbm);
      final radius = size.width * 0.26;
      final radialPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.48),
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, radialPaint);
    }

    // 2. Paint Architectural Room Blueprint Walls & Labels
    for (final room in rooms) {
      final rect = Rect.fromLTWH(
        room.normalizedRect.left * size.width,
        room.normalizedRect.top * size.height,
        room.normalizedRect.width * size.width,
        room.normalizedRect.height * size.height,
      );
      final isSelected = room.id == selectedRoomId;
      final matchingSample = samples.where((e) => e.roomId == room.id).toList();
      final roomSample = matchingSample.isNotEmpty ? matchingSample.first : null;

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 : 1.4
        ..color = isSelected
            ? AppTheme.accentCyan
            : const Color(0xFF475569);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      // Room Title
      final titleSpan = TextSpan(
        text: strings.get(room.translationKey),
        style: TextStyle(
          color: isSelected ? AppTheme.accentCyan : AppTheme.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      final titleTp = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 12);
      titleTp.paint(canvas, Offset(rect.left + 6, rect.top + 6));

      // Room dBm Badge
      if (roomSample != null) {
        final col = _zoneColor(roomSample.dbm);
        final dbmText = '${roomSample.dbm.toStringAsFixed(0)} dBm';
        final dbmTp = TextPainter(
          text: TextSpan(
            text: dbmText,
            style: TextStyle(
              color: col,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        dbmTp.paint(
          canvas,
          Offset(
            rect.center.dx - dbmTp.width / 2,
            rect.center.dy - dbmTp.height / 2 + 6,
          ),
        );
      }
    }

    // 3. Paint Optimal Router Placement Marker
    final routerPos = Offset(
      optimalPlacement.optimalX * size.width,
      optimalPlacement.optimalY * size.height,
    );
    final routerGlow = Paint()
      ..color = AppTheme.accentCyan.withValues(alpha: 0.28);
    canvas.drawCircle(routerPos, 18, routerGlow);

    final routerCore = Paint()..color = AppTheme.accentCyan;
    canvas.drawCircle(routerPos, 7, routerCore);

    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(routerPos, 11, ringPaint);
  }

  @override
  bool shouldRepaint(covariant FloorplanHeatmapPainter oldDelegate) => true;
}

class SpectrumOverlapPainter extends CustomPainter {
  final int primaryChannel;
  final List<int> neighborChannels;
  final bool is5Ghz;

  SpectrumOverlapPainter({
    required this.primaryChannel,
    required this.neighborChannels,
    required this.is5Ghz,
  });

  double _channelToX(int ch, double width) {
    if (!is5Ghz) {
      return ((ch - 1) / 13.0) * (width - 40) + 20;
    }
    const channels = [36, 40, 44, 48, 149, 153, 157, 161, 165];
    final idx = channels.indexOf(ch);
    final safeIdx = idx < 0 ? 0 : idx;
    return (safeIdx / (channels.length - 1)) * (width - 40) + 20;
  }

  void _drawBellCurve(
    Canvas canvas,
    Size size,
    double centerX,
    double spreadWidth,
    Color color,
    bool filled,
  ) {
    final path = Path();
    final baseLine = size.height - 24;
    final peakHeight = filled ? size.height * 0.72 : size.height * 0.50;

    path.moveTo(centerX - spreadWidth, baseLine);
    path.cubicTo(
      centerX - spreadWidth * 0.55,
      baseLine,
      centerX - spreadWidth * 0.35,
      baseLine - peakHeight,
      centerX,
      baseLine - peakHeight,
    );
    path.cubicTo(
      centerX + spreadWidth * 0.35,
      baseLine - peakHeight,
      centerX + spreadWidth * 0.55,
      baseLine,
      centerX + spreadWidth,
      baseLine,
    );

    if (filled) {
      final fillPath = Path.from(path)..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = color.withValues(alpha: 0.26),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = filled ? 2.6 : 1.6,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0B0F19);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bg,
    );

    final spread = is5Ghz ? 26.0 : (size.width / 13.0) * 2.2;

    // Neighbor channels
    for (final nCh in neighborChannels) {
      final nx = _channelToX(nCh, size.width);
      _drawBellCurve(
        canvas,
        size,
        nx,
        spread,
        AppTheme.accentAmber.withValues(alpha: 0.75),
        false,
      );
    }

    // Active Primary Channel
    final px = _channelToX(primaryChannel, size.width);
    _drawBellCurve(canvas, size, px, spread, AppTheme.accentGreen, true);

    // Axis line
    final axisY = size.height - 24;
    canvas.drawLine(
      Offset(12, axisY),
      Offset(size.width - 12, axisY),
      Paint()..color = AppTheme.borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant SpectrumOverlapPainter oldDelegate) => true;
}

class EmfRadarPainter extends CustomPainter {
  final double microTesla;
  final double azimuthDeg;
  final EmfSafetyLevel level;

  EmfRadarPainter({
    required this.microTesla,
    required this.azimuthDeg,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.44;

    final Color activeColor = level == EmfSafetyLevel.normal
        ? AppTheme.accentGreen
        : (level == EmfSafetyLevel.moderate
            ? AppTheme.accentAmber
            : AppTheme.accentRed);

    for (final factor in [1.0, 0.68, 0.36]) {
      canvas.drawCircle(
        center,
        maxR * factor,
        Paint()
          ..color = activeColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }

    // Sweep line
    final rad = azimuthDeg * (math.pi / 180.0);
    final tip = Offset(
      center.dx + math.cos(rad) * maxR,
      center.dy + math.sin(rad) * maxR,
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = activeColor
        ..strokeWidth = 2.4,
    );

    // Center readout
    final tp = TextPainter(
      text: TextSpan(
        text: '${microTesla.toStringAsFixed(1)} µT',
        style: TextStyle(
          color: activeColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant EmfRadarPainter oldDelegate) => true;
}

// =============================================================================
// SMALL UI HELPERS
// =============================================================================

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String code;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    super.key,
    required this.code,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentGreen.withValues(alpha: 0.18)
                : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.accentGreen : AppTheme.borderColor,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.accentGreen : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
