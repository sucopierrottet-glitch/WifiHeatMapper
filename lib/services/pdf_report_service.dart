import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../calculators/wifi_calculator.dart';
import 'storage_service.dart';

class PdfReportService {
  static Future<Uint8List> buildSurveyPdfBytes({
    required FloorplanSurvey survey,
    required TechProfile techProfile,
    Uint8List? signaturePngBytes,
  }) async {
    final doc = pw.Document(
      title: 'WiFi HeatMapper Pro - ${survey.projectName}',
      author: techProfile.name,
    );

    final optimal = WifiCalculator.calculateOptimalRouterPlacement(survey.samples);
    final emfStatus = WifiCalculator.classifyEmfLevel(survey.peakEmfUt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0B0F19'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'WIFI HEATMAPPER PRO • RF & EMF AUDIT REPORT',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#00E676'),
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'IEEE 802.11 / ITU-R P.1238 Indoor Propagation & EMF Assessment',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#CBD5E1'),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'ID: ${survey.id}',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#38BDF8'),
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${survey.createdAt.year}-${survey.createdAt.month.toString().padLeft(2, '0')}-${survey.createdAt.day.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#94A3B8'),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Project & Engineer Metadata
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROJECT: ${survey.projectName}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Network SSID: ${survey.ssid} (${survey.is5Ghz ? "5 GHz" : "2.4 GHz"} • Ch ${survey.primaryChannel})',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Engineer: ${techProfile.name}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${techProfile.company} • Lic: ${techProfile.licenseId}',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Executive KPI Summary Row
          pw.Row(
            children: [
              _buildKpiBox(
                'AVERAGE RSSI',
                '${optimal.averageDbm.toStringAsFixed(1)} dBm',
                'Quality: ${optimal.coverageScorePercent.toStringAsFixed(0)}%',
              ),
              pw.SizedBox(width: 10),
              _buildKpiBox(
                'OPTIMAL ROUTER',
                'X:${(optimal.optimalX * 100).toStringAsFixed(0)}% Y:${(optimal.optimalY * 100).toStringAsFixed(0)}%',
                'Zone: ${optimal.recommendedRoomId.toUpperCase()}',
              ),
              pw.SizedBox(width: 10),
              _buildKpiBox(
                'PEAK EMF FIELD',
                '${survey.peakEmfUt.toStringAsFixed(1)} uT',
                emfStatus.safeForRouterPlacement ? 'SAFE FOR AP' : 'HIGH EMF WARNING',
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          pw.Text(
            'ROOM-BY-ROOM THERMAL COVERAGE & FSPL SCHEDULE',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),

          // Room Samples Table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 9.5,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#161F30'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              'Room / Zone',
              'Coordinates',
              'Signal (dBm)',
              'Quality',
              'FSPL Est. Dist',
              'EMF (uT)',
              'Status',
            ],
            data: survey.samples.map((s) {
              final q = WifiCalculator.signalQualityPercent(s.dbm);
              final dist = WifiCalculator.estimateDistanceMeters(
                rssiDbm: s.dbm,
                frequencyMhz: s.frequencyMhz.toDouble(),
              );
              final zone = WifiCalculator.classifySignalZone(s.dbm);
              final statusStr = zone == SignalZone.excellent
                  ? 'EXCELLENT'
                  : (zone == SignalZone.fair ? 'FAIR' : 'DEAD ZONE');
              return [
                s.roomName,
                '(${(s.normalizedX * 100).toStringAsFixed(0)}%, ${(s.normalizedY * 100).toStringAsFixed(0)}%)',
                '${s.dbm.toStringAsFixed(1)} dBm',
                '${q.toStringAsFixed(0)}%',
                '${dist.toStringAsFixed(1)} m',
                '${s.emfMicroTesla.toStringAsFixed(1)} uT',
                statusStr,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          // Signature & Certification Block
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CERTIFICATION & TECHNICAL APPROVAL',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'This report certifies the on-site Wi-Fi RSSI thermal propagation, Free-Space Path Loss (FSPL) attenuation, and magnetometer EMF interference measurements recorded on device.',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromHex('#475569'),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Signed by: ${techProfile.name} (${techProfile.licenseId})',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (signaturePngBytes != null)
                      pw.Container(
                        width: 140,
                        height: 55,
                        child: pw.Image(pw.MemoryImage(signaturePngBytes)),
                      )
                    else
                      pw.Container(
                        width: 140,
                        height: 40,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '[Digital Signature Certified]',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColor.fromHex('#64748B'),
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ),
                    pw.Container(
                      width: 150,
                      height: 1,
                      color: PdfColor.fromHex('#0F172A'),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Authorized RF Engineer Signature',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildKpiBox(String title, String value, String sub) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F1F5F9'),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#475569'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0B0F19'),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              sub,
              style: pw.TextStyle(
                fontSize: 8.5,
                color: PdfColor.fromHex('#047857'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> previewAndSharePdf({
    required FloorplanSurvey survey,
    required TechProfile techProfile,
    Uint8List? signaturePngBytes,
  }) async {
    final bytes = await buildSurveyPdfBytes(
      survey: survey,
      techProfile: techProfile,
      signaturePngBytes: signaturePngBytes,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'WiFiHeatMapper_${survey.id}.pdf',
    );
  }
}
