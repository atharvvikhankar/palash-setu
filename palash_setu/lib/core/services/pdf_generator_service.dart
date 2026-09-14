import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGeneratorService {
  /// Generates a printable bilingual NIPUN Bharat aligned Worksheet PDF
  static Future<Uint8List> generateWorksheetPdf({
    required String title,
    required String grade,
    required String subject,
    required String outcomeCode,
    required List<Map<String, dynamic>> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PALASH SETU — MTB-MLE BILINGUAL WORKSHEET',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Jharkhand Primary Education | Grade: $grade | Subject: $subject',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.amber100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'NIPUN Code: $outcomeCode',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),
                pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Instructions: Match the Hindi classroom words with their Santali (Ol Chiki) vernacular equivalents.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 16),

                // Table of Matching Items
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('S.No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Hindi Word (हिन्दी)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Santali ( Ol Chiki)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Phonetic Guide', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                    // Table Rows
                    ...items.asMap().entries.map((entry) {
                      int idx = entry.key + 1;
                      var item = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$idx.', style: const pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['hindiWord'] ?? item['hindiText'] ?? '', style: const pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['santaliWord'] ?? item['santaliText'] ?? '', style: const pw.TextStyle(fontSize: 12)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['phoneticGuide'] ?? '', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.Spacer(),
                // Footer
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Teacher Signature: __________________', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Generated via PALASH Setu App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
