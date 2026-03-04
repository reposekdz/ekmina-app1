import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  Future<File> generateTransactionReceipt({
    required String transactionId,
    required String userName,
    required String groupName,
    required String type,
    required double amount,
    required DateTime date,
    required String status,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'E-KIMINA RWANDA',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text('Raporo y\'ibikorwa', style: const pw.TextStyle(fontSize: 16))),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            _buildRow('ID:', transactionId),
            _buildRow('Amazina:', userName),
            _buildRow('Itsinda:', groupName),
            _buildRow('Ubwoko:', type),
            _buildRow('Amafaranga:', '${amount.toStringAsFixed(0)} RWF'),
            _buildRow('Itariki:', dateFormat.format(date)),
            _buildRow('Uko bimeze:', status),
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'Murakoze gukoresha E-Kimina',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_$transactionId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> generateGroupReport({
    required String groupName,
    required double totalBalance,
    required int memberCount,
    required List<Map<String, dynamic>> transactions,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Raporo y\'itsinda: $groupName', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Amafaranga yose: ${totalBalance.toStringAsFixed(0)} RWF'),
          pw.Text('Abanyamuryango: $memberCount'),
          pw.SizedBox(height: 20),
          pw.Text('Ibikorwa', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Itariki', 'Ubwoko', 'Amafaranga'],
            data: transactions.map((t) => [t['date'], t['type'], '${t['amount']} RWF']).toList(),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/group_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(onLayout: (_) => pdfFile.readAsBytes());
  }

  Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(bytes: await pdfFile.readAsBytes(), filename: pdfFile.path.split('/').last);
  }

  pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }
}
