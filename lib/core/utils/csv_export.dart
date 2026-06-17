import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

Future<void> exportTransactionsCsv({
  required List<Transaction> transactions,
  required DateTime start,
  required DateTime end,
  required String currencySymbol,
}) async {
  final filtered = transactions.where((t) {
    return !t.date.isBefore(start) && !t.date.isAfter(end);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final income = filtered
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (s, t) => s + t.amount);
  final expense = filtered
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (s, t) => s + t.amount);

  final df = DateFormat('yyyy-MM-dd');
  final lines = <String>[
    'Date,Type,Description,Amount,Pupil,Category,Payment Method',
    ...filtered.map((t) {
      final type = t.type == TransactionType.income ? 'Income' : 'Expense';
      return '${df.format(t.date)},$type,"${t.description.replaceAll('"', '""')}",'
          '${t.amount.toStringAsFixed(2)},'
          '${t.pupilName ?? ""},'
          '${t.category?.name ?? ""},'
          '${t.paymentMethod?.name ?? ""}';
    }),
    '',
    'Summary,,,,,',
    'Total Income,,,$currencySymbol${income.toStringAsFixed(2)},,,',
    'Total Expenses,,,$currencySymbol${expense.toStringAsFixed(2)},,,',
    'Profit,,,$currencySymbol${(income - expense).toStringAsFixed(2)},,,',
  ];

  final content = lines.join('\n');
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/lesson_tracker_export_${df.format(start)}_${df.format(end)}.csv',
  );
  await file.writeAsString(content);
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'Lesson Tracker Pro — Financial Export',
  );
}
