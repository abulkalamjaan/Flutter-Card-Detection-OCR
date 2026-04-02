# id_ocr

A robust and versatile Flutter plugin for **CNIC (Computerized National Identity Card)** detection and OCR, with specialized support for **Urdu** and **Sindhi** scripts.

This plugin combines the power of **Google ML Kit** for fast document detection and standard text recognition (English/Numeric) with **Tesseract OCR** as a fallback for complex Urdu and Sindhi scripts.

---

## ✨ Features

- **Guided Card Scanning**: Automatic document cropping and perspective correction using `google_mlkit_document_scanner`.
- **Hybrid OCR Engine**:
  - **Google ML Kit**: High-speed extraction for English names, CNIC numbers, and dates.
  - **Tesseract fallback**: Specialized support for Urdu and Sindhi script extraction (names, addresses).
- **Advanced Data Extraction**: 
  - Extracts Name, Father's Name, CNIC Number, and Date of Birth.
  - Supports **Gender** extraction with normalization (`M`/`F`, `Male`/`Female`, Urdu/Sindhi words).
  - Handles **Date of Issue** and **Date of Expiry** with specialized labels (e.g., "Valid Upto").
- **Reliability Features**:
  - Memory-optimized scanner management to prevent native Android crashes (`SIG 9`).
  - Automatic `image_picker` fallback if the native scanner activity fails.
  - Optional Manual Capture mode for full control over image sources.
- **Customizable UI Flow**: Easy-to-integrate services that can fit any design language.
- **Micro-Animations**: Built-in support for scanning animations and loaders.

---

## 🚀 Getting Started

### 1. Add Dependency

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  id_ocr: ^0.1.3
```

### 2. Platform Setup

#### Android
Update your `android/app/build.gradle`:
- `minSdkVersion` should be at least **21**.

Add permissions to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 3. Critical: Android Integration Tips
To avoid common crashes during integration (like `No cropped images returned` or `SIG 9`), ensure the following:
- **Clean MainActivity**: In `android/app/src/main/kotlin/.../MainActivity.kt`, the class should simply extend `FlutterActivity()`. Avoid custom `onActivityResult` overrides unless they call `super`.
- **No Conflicting Plugins**: Do not use `cunning_document_scanner` alongside `id_ocr`, as they conflict during the Activity Result delivery.
- **Hardware Acceleration**: Ensure `android:hardwareAccelerated="true"` is set (default in Flutter) to allow ML Kit to process images.

#### iOS
Add the following to your `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan the CNIC.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your gallery to upload the CNIC image.</string>
```

---

## 🛠 Usage

Integrating `id_ocr` is straightforward. You can use the `ScannerService` for capturing images and `OcrService` for processing them.

### Simple Example

```dart
import 'package:id_ocr/id_ocr.dart';

// 1. Initialize services
final ScannerService _scannerService = ScannerService();
final OcrService _ocrService = OcrService();

// 2. Scan and Process
Future<void> scanAndExtract() async {
  // Capture image using document scanner
  final String? path = await _scannerService.scanDocument();
  
  if (path != null) {
    // Process the image for the front side
    CnicModel extractedData = await _ocrService.processImage(path, isFront: true);
    
    print('Name: ${extractedData.name}');
    print('CNIC: ${extractedData.cnicNumber}');
  }
}
```

### Data Model

The `CnicModel` contains the following fields:
- `name`: Full name of the individual.
- `fatherName`: Father's or Husband's name.
- `cnicNumber`: 13-digit identity number.
- `gender`: Normalized Gender ("Male" or "Female").
- `dob`: Date of Birth.
- `issueDate`: Date of card issue.
- `expiry`: Card expiry date.
- `address`: Residential address (typically from the back side).

---

## 🏗 Guided Scan & Extraction Screen

The plugin is designed to support a seamless **"Guided Scan"** experience similar to the one in the example app:
1. **Instruction**: Show a screen explaining what to scan (Front/Back).
2. **Scanner**: Call `ScannerService.scanDocument()`.
3. **Extraction View**: Immediately after the scanner returns, update your UI to show a loader (e.g., "Extracting Details...") while calling `OcrService.processImage()`.
4. **Repeat**: Repeat for the back side if necessary.

```dart
// Example of the Guided Flow
void onScanTapped() async {
  setState(() => isExtracting = false);
  
  // 1. Scan Front
  final path = await _scannerService.scanDocument();
  if (path == null) return;
  
  // 2. Show Extraction UI
  setState(() => isExtracting = true);
  
  // 3. Process OCR
  final data = await _ocrService.processImage(path, isFront: true);
  
  // 4. Update UI
  setState(() {
    extractedData = data;
    isExtracting = false;
  });
}
```

Check the `example` folder for a full implementation using **GetX** and custom animations.

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve the OCR accuracy or add new features.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
