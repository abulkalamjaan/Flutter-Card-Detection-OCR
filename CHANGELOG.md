## 0.1.2

* **Fixed Android Crash (SIG 9)**: Resolved native process termination in `internalDispatchActivityResult` by optimizing resource management in the `ScannerService`.
* **Enhanced Data Extraction**:
  * Added Gender extraction with automatic normalization (Male/Female).
  * Added support for Date of Issue.
  * Improved Expiry Date extraction with more robust label detection (e.g., "Valid Upto").
* **Fallback Mechanisms**: 
  * Added automatic `image_picker` fallback if the Document Scanner fails.
  * Added Manual Capture UI in the sample app for maximum stability.

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
