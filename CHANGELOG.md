## 0.1.3

* **Fixed Native Crash**: Added `PlatformException` handling for the "No cropped images returned" error in the document scanner, preventing app termination in integrated projects.
* **Internal Fallback**: Moved the `image_picker` fallback logic from the example app directly into `ScannerService` for better out-of-the-box stability.
* **Integration Documentation**: Added a critical guide for Android `MainActivity` setup and dependency conflict resolution.

## 0.1.2

* **Fixed Android Crash (SIG 9)**: Resolved native process termination in `internalDispatchActivityResult` by optimizing resource management in the `ScannerService`.
* **Enhanced Data Extraction**:
  * Added Gender extraction with automatic normalization (Male/Female).
  * Added support for Date of Issue.
  * Improved Expiry Date extraction with more robust label detection (e.g., "Valid Upto").
* **Fallback Mechanisms**: 
  * Preliminary support for manual capture in the sample app.

## 0.1.1

* Added Gender extraction with automatic normalization (Male/Female).
* Added Date of Issue extraction support.
* Improved Date of Expiry extraction with expanded labels (e.g., "Valid Upto").
* Enhanced Tesseract diagnostic logging.

## 0.1.0

* Initial release of `id_ocr`.
* CNIC OCR support for Urdu and Sindhi.
* Integration with Google ML Kit Document Scanner.
* Integration with Tesseract OCR for Urdu/Sindhi fallback.
* Robust date and CNIC number extraction.
