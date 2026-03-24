import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ScannerService {
  late DocumentScanner _documentScanner;

  ScannerService() {
    _documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg},
        mode: ScannerMode.base,
        isGalleryImport: true,
        pageLimit: 1,
      ),
    );
  }

  Future<String?> scanDocument() async {
    try {
      final result = await _documentScanner.scanDocument();
      final images = result.images;
      if (images != null && images.isNotEmpty) {
        return images.first;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  void dispose() {
    _documentScanner.close();
  }
}
