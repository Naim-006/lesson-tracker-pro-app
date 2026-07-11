import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';
import '../utils/share_bytes.dart';

/// Uploads and retrieves receipt images via Supabase Storage.
class ReceiptStorageService {
  static const String bucket = 'receipts';

  static Future<String?> uploadReceipt({
    required String instructorId,
    required String transactionId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = fileExtension(fileName);
      final storagePath = '$instructorId/$transactionId.$ext';
      final mimeType = mimeTypeFromFileName(fileName);

      await Supabase.instance.client.storage.from(bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

      return storagePath;
    } catch (e, stackTrace) {
      Logger.error('Receipt upload failed', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Resolves a stored path or legacy full URL to a viewable URL.
  static Future<String?> resolveReceiptUrl(String? receiptRef) async {
    if (receiptRef == null || receiptRef.isEmpty) return null;
    if (receiptRef.startsWith('http://') || receiptRef.startsWith('https://')) {
      return receiptRef;
    }

    try {
      return await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(receiptRef, 3600);
    } catch (e, stackTrace) {
      Logger.error('Failed to resolve receipt URL', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<void> downloadAndShare(String receiptRef, String fileName) async {
    final url = await resolveReceiptUrl(receiptRef);
    if (url == null) throw Exception('Could not load receipt');

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Download failed (${response.statusCode})');
    }

    await shareFileBytes(
      bytes: response.bodyBytes,
      fileName: fileName,
      mimeType: mimeTypeFromFileName(fileName),
      subject: 'Receipt',
    );
  }
}
