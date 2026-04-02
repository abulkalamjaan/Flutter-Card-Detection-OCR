import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ScannerService {
  /// Scans a document using Google ML Kit Document Scanner.
  /// If the scanner fails (common in integrated apps with conflicts),
  /// it automatically falls back to [ImagePicker].
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
      debugPrint('ID_OCR: Starting Google ML Kit Document Scanner...');
      final result = await documentScanner.scanDocument();
      final images = result.images;
      if (images != null && images.isNotEmpty) {
        debugPrint('ID_OCR: Scan successful. Cropped image returned.');
        return images.first;
      }
    } on PlatformException catch (e) {
      debugPrint('ID_OCR: Native Scanner Error: ${e.message}');
      debugPrint('ID_OCR: Error Code: ${e.code}');
    } catch (e) {
      debugPrint('ID_OCR: Unexpected scanner error: $e');
    } finally {
      documentScanner.close();
    }

    // Fallback Mechanism
    debugPrint('ID_OCR: Falling back to manual ImagePicker capture...');
    return await _fallbackToImagePicker();
  }

  Future<String?> _fallbackToImagePicker() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );
      return image?.path;
    } catch (e) {
      debugPrint('ID_OCR: ImagePicker fallback failed: $e');
      return null;
    }
  }

  void dispose() {
    // No longer holding a long-lived instance
  }
}
