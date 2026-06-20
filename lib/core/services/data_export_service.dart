import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/models.dart';
import '../../core/utils/logger.dart';

class DataExportService {
  static Future<void> exportData(dynamic appState) async {
    try {
      Logger.info('Starting data export');
      
      final payments = appState.transactions
          .where((t) => t.type == TransactionType.income)
          .toList();
      final expenses = appState.transactions
          .where((t) => t.type == TransactionType.expense)
          .toList();

      final Map<String, dynamic> dataMap = {
        'pupils': appState.pupils.map((p) => p.toJson()).toList(),
        'lessons': appState.lessons.map((l) => l.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'mileage': appState.mileageEntries.map((m) => m.toJson()).toList(),
        'openSlots': appState.openSlots.map((s) => s.toJson()).toList(),
        'notifications': appState.notifications.map((n) => n.toJson()).toList(),
        'enquiries': appState.enquiries.map((e) => e.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
      };
      
      final jsonString = jsonEncode(dataMap);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/lesson_tracker_pro_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      Logger.info('Data export completed: ${file.path}');
      
      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Lesson Tracker Pro Backup');
      
    } catch (e, stackTrace) {
      Logger.error('Error exporting data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>?> importData(String filePath) async {
    try {
      Logger.info('Starting data import from: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        Logger.error('Import file does not exist');
        return null;
      }
      
      final jsonString = await file.readAsString();
      final dataMap = jsonDecode(jsonString) as Map<String, dynamic>;
      
      Logger.info('Data import completed');
      return dataMap;
      
    } catch (e, stackTrace) {
      Logger.error('Error importing data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static Future<void> exportToCSV(dynamic appState) async {
    try {
      Logger.info('Starting CSV export');
      
      // Export pupils to CSV
      final pupilsCSV = _generatePupilsCSV(appState.pupils);
      final directory = await getTemporaryDirectory();
      final pupilsFile = File('${directory.path}/pupils_${DateTime.now().millisecondsSinceEpoch}.csv');
      await pupilsFile.writeAsString(pupilsCSV);
      
      // Export lessons to CSV
      final lessonsCSV = _generateLessonsCSV(appState.lessons);
      final lessonsFile = File('${directory.path}/lessons_${DateTime.now().millisecondsSinceEpoch}.csv');
      await lessonsFile.writeAsString(lessonsCSV);
      
      // Export payments to CSV
      final paymentsCSV = _generatePaymentsCSV(appState.payments);
      final paymentsFile = File('${directory.path}/payments_${DateTime.now().millisecondsSinceEpoch}.csv');
      await paymentsFile.writeAsString(paymentsCSV);
      
      Logger.info('CSV export completed');
      
      // Share the files
      await Share.shareXFiles([
        XFile(pupilsFile.path),
        XFile(lessonsFile.path),
        XFile(paymentsFile.path),
      ], text: 'Lesson Tracker Pro CSV Export');
      
    } catch (e, stackTrace) {
      Logger.error('Error exporting to CSV', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  static String _generatePupilsCSV(List pupils) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Phone,Email,Hourly Rate,Status,Total Lessons,Revenue');
    
    for (final pupil in pupils) {
      buffer.writeln(
        '${pupil.fullName},${pupil.phone},${pupil.email},${pupil.hourlyRate},${pupil.status},${pupil.aggregatedTotalLessonsCount},${pupil.grossRevenueEarned}'
      );
    }
    
    return buffer.toString();
  }
  
  static String _generateLessonsCSV(List lessons) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Time,Duration,Pupil ID,Rate,Status');
    
    for (final lesson in lessons) {
      buffer.writeln(
        '${lesson.date},${lesson.time},${lesson.duration},${lesson.pupilId},${lesson.rate},${lesson.status}'
      );
    }
    
    return buffer.toString();
  }
  
  static String _generatePaymentsCSV(List<Transaction> payments) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Amount,Pupil ID,Method,Type,Category');
    
    for (final payment in payments) {
      buffer.writeln(
        '${payment.date},${payment.amount},${payment.pupilId},${payment.paymentMethod},${payment.type},${payment.category}'
      );
    }
    
    return buffer.toString();
  }
}
