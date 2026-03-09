import 'dart:io';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ScannerService {
  late DocumentScanner _documentScanner;

  ScannerService() {
    _documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: 1,
      ),
    );
  }

  Future<String?> scanDocument() async {
    try {
      final result = await _documentScanner.scanDocument();
      if (result.images.isNotEmpty) {
        return result.images.first;
      }
    } catch (e) {
      print('Error scanning document: $e');
    }
    return null;
  }

  void dispose() {
    _documentScanner.close();
  }
}
