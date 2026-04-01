import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter/foundation.dart';

class ScannerService {
  Future<String?> scanDocument() async {
    final documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg},
        mode: ScannerMode.base,
        isGalleryImport: true,
        pageLimit: 1,
      ),
    );

    try {
      final result = await documentScanner.scanDocument();
      final images = result.images;
      if (images != null && images.isNotEmpty) {
        return images.first;
      }
    } catch (e) {
      debugPrint('Scanner error: $e');
    } finally {
      documentScanner.close();
    }
    return null;
  }

  void dispose() {
    // No longer holding a long-lived instance
  }
}
