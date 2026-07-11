import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Shares file bytes on mobile, desktop, and web without [path_provider].
Future<void> shareFileBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  String? subject,
  String? text,
}) async {
  await Share.shareXFiles(
    [
      XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: mimeType,
      ),
    ],
    subject: subject,
    text: text,
  );
}

String fileExtension(String fileName) {
  if (!fileName.contains('.')) return 'jpg';
  return fileName.split('.').last.toLowerCase();
}

String mimeTypeFromFileName(String fileName) {
  switch (fileExtension(fileName)) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'image/jpeg';
  }
}
