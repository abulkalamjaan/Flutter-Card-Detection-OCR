# Flutter OCR Developer Guide

This guide provides a technical overview of the **Flutter OCR** application, designed for CNIC (Computerized National Identity Card) detection and text extraction.

## Project Overview

The application leverages Google ML Kit and Tesseract OCR to scan and extract information from identification cards. It features a **Guided Scanning Flow** that sequentially prompts the user for both the front and back sides of the card in a single session. It is built using the **GetX** pattern for state management and navigation, following a modular architecture.

## Architecture

The project follows a modular directory structure as per the `Patterns.md` rule:

- `lib/modules/`: Contains feature-specific modules.
  - `cnic_viewer/`: The core module for CNIC scanning and processing.
    - `controllers/`: Business logic and state management (GetX).
    - `models/`: Data classes.
    - `screens/`: UI components.
    - `services/`: External service integrations (OCR, Scanner).

### State Management
The app uses **GetX** for reactive state management.
- `CnicController` (`lib/modules/cnic_viewer/controllers/cnic_controller.dart`) manages the `CnicModel` state, loading indicators, image paths, and the `scanStep` (guided flow state).
- Components listen to changes using `Obx`.

### Guided Scanning Process
The `startGuidedScan` method in the controller orchestrates the following:
1. **Front Side Scan:** Prompts the user and waits for the front side image.
2. **Back Side Scan:** Automatically prompts for the back side after the front is processed.
3. **Data Extraction:** Processes both images using the dual-engine strategy.
4. **Result Presentation:** Displays the final extracted data in a confirmed form.

### Scanning Mode
- **ScannerMode.base:** The application uses the `base` mode to provide a clean scanning experience without additional filtering or grayscale screens, returning the original image for processing.

## Core Functionality: CNIC OCR

The OCR logic is encapsulated in `OcrService` (`lib/modules/cnic_viewer/services/ocr_service.dart`).

### Dual-Engine Strategy
1. **Google ML Kit (Primary):** Fast and accurate for Latin characters and numbers. Used for initial text extraction and field identification.
2. **Tesseract OCR (Fallback/Specialized):** Used specifically for Urdu and Sindhi script extraction when ML Kit results are incomplete.

### Side Detection
`OcrService` includes a heuristic to determine if an image is the Front or Back of a card based on:
- Keywords (e.g., "Name", "نام", "Father", "ولدیت").
- Date counts (Back sides typically have Issue and Expiry dates).
- Regex patterns for CNIC numbers.

### Field Extraction
Specific Regex patterns are used to extract:
- **CNIC Number:** Flexible pattern `\d{5}[-\s]?\d{7}[-\s]?\d{1}` to handle varying OCR results (with or without hyphens/spaces).
- **Dates (DOB/Expiry):** `\d{2}[-/\.]\d{2}[-/\.]\d{4}`
- **Names/Addresses:** Extracted based on surrounding labels in multiple languages (English, Urdu, Sindhi).

## Setup and Installation

### Dependencies
Key packages used:
- `get`: ^4.6.6 (State management)
- `google_mlkit_text_recognition`: ^0.14.0 (OCR)
- `google_mlkit_document_scanner`: ^0.2.0 (Scanning UI)
- `tesseract_ocr`: ^0.4.0 (Multilingual OCR)

### Assets
The project requires Tesseract data files for Urdu and Sindhi:
- `assets/tessdata/`: Should contain `.traineddata` files.
- `assets/tessdata_config.json`: Configuration for the OCR engine.

### Run the App
1. Ensure Flutter SDK is installed.
2. Run `flutter pub get` to fetch dependencies.
3. Use `flutter run` to launch on a connected device/emulator.

## Coding Standards

- **OOP Concepts:** Encapsulate logic in services and controllers to ensure reusability.
- **DRY (Don't Repeat Yourself):** Shared logic (like Regex matching) should be centralized.
- **GetX Patterns:** Use `Get.put` for dependency injection and `Obx` for UI updates.
