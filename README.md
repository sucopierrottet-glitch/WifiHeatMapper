# WiFi HeatMapper Pro

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Google Play](https://img.shields.io/badge/Google%20Play-Ready-00E676?logo=google-play)](https://play.google.com)

**WiFi HeatMapper Pro** (`com.simpleappspg.wifiheatmapper`) is an offline-first precision RF & EMF field engineering tool in the SimpleAppsPG Obsidian Dark suite. Built as a **Camino 1 Paid App (100% Pro Unlocked)** with trilingual support (`ES`, `EN`, `PT`).

## Core Capabilities

1. **Interactive 2D Floorplan Thermal Heatmap (`CustomPainter`)**
   - Tap rooms on the architectural blueprint to record Wi-Fi RSSI (`-30 dBm` to `-90 dBm`) and paint radial thermal zones (`#00E676` Green Excellent, `#FFD600` Yellow Fair, `#FF5252` Red Dead Zone).
   - Automatically computes **Optimal Router Coordinates** using coverage-deficit and EMF-penalized centroid weighting.
2. **2.4 GHz & 5 GHz Channel Overlap Analyzer + FSPL Distance Estimator**
   - Evaluates co-channel and adjacent-channel interference across 2.4 GHz (Channels 1–14) and 5 GHz (UNII 36–165) with real-time OFDM spectral bell-curve visualization.
   - Free-Space Path Loss (FSPL) distance and attenuation calculator.
3. **Native Magnetometer EMF Interference Radar (`MethodChannel`)**
   - Reads `com.simpleappspg.sensors/data` (`getSensorSnapshot`) for live magnetic field intensity in microTesla (`µT`) and 3-axis magnetometer components to identify high-interference electrical panels or motors before mounting access points.
4. **Signed A4 PDF Inspection Reports**
   - Generates multi-section engineering PDF reports via `pdf` + `printing` with an interactive `signature` pad.
5. **1-Tap Trilingual Localization (`ES` / `EN` / `PT`)**
   - Instant language switching persisted via `SharedPreferences`.

## Verification

```bash
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```
