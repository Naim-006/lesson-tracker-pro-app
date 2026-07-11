import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import 'pdf_fonts.dart';
import 'share_bytes.dart';

Future<void> shareTransactionPdf({
  required Transaction transaction,
  required String currencySymbol,
}) async {
  final isIncome = transaction.type == TransactionType.income;
  final title = isIncome ? 'Payment Receipt' : 'Expense Receipt';
  final df = DateFormat('dd MMM yyyy');

  final regularFont = await PdfFonts.regular();
  final boldFont = await PdfFonts.bold();
  final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

  final pdf = pw.Document(theme: theme);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: theme,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Lesson Tracker Pro',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 16),
          _pdfRow('Amount', '$currencySymbol${transaction.amount.toStringAsFixed(2)}', bold: true),
          _pdfRow('Date', df.format(transaction.date)),
          if (isIncome)
            _pdfRow('Pupil', transaction.pupilName ?? 'General'),
          if (transaction.paymentMethod != null)
            _pdfRow('Payment Method', labelEnum(transaction.paymentMethod!)),
          if (isIncome && transaction.paymentType != null)
            _pdfRow('Payment Type', labelEnum(transaction.paymentType!)),
          if (!isIncome && transaction.category != null)
            _pdfRow('Category', labelEnum(transaction.category!)),
          _pdfRow('Description', transaction.description),
          pw.Spacer(),
          pw.Text(
            'Generated ${df.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    ),
  );

  final bytes = await pdf.save();
  final prefix = isIncome ? 'payment' : 'expense';

  await shareFileBytes(
    bytes: bytes,
    fileName: '${prefix}_${transaction.id.substring(0, 8)}.pdf',
    mimeType: 'application/pdf',
    subject: title,
    text: '$title — $currencySymbol${transaction.amount.toStringAsFixed(2)}',
  );
}

pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}
