import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import '../models/cnic_model.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<CnicModel> processImage(String path, {bool isFront = true}) async {
    // 1. Try with ML Kit (Fast, good for Latin/Numbers)
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    List<String> mlKitLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        mlKitLines.add(line.text.trim());
      }
    }

    CnicModel model = isFront
        ? _extractFrontData(mlKitLines)
        : _extractBackData(mlKitLines);

    // 2. Fallback to Tesseract if Urdu/Sindhi script fields are missing
    bool needsFallback = false;
    if (isFront) {
      needsFallback =
          (model.name == null || model.name!.isEmpty) ||
          (model.fatherName == null || model.fatherName!.isEmpty);
    } else {
      needsFallback = (model.address == null || model.address!.isEmpty);
    }

    if (needsFallback) {
      print(
        'Notice: Fields missing, falling back to Tesseract OCR for Urdu/Sindhi support...',
      );
      try {
        // Run Tesseract with Urdu, Sindhi, and English
        final tesseractText = await TesseractOcr.extractText(
          path,
          config: OCRConfig(language: 'urd+snd+eng'),
        );

        final tesseractLines = tesseractText
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final tesseractModel = isFront
            ? _extractFrontData(tesseractLines)
            : _extractBackData(tesseractLines);

        // Merge results: Keep ML Kit numbers, take Tesseract text if ML Kit failed
        model.name = (model.name == null || model.name!.isEmpty)
            ? tesseractModel.name
            : model.name;
        model.fatherName =
            (model.fatherName == null || model.fatherName!.isEmpty)
            ? tesseractModel.fatherName
            : model.fatherName;
        model.address = (model.address == null || model.address!.isEmpty)
            ? tesseractModel.address
            : model.address;

        // Sometimes Tesseract is better at numbers too if image quality is low
        model.cnicNumber ??= tesseractModel.cnicNumber;
        model.dob ??= tesseractModel.dob;
        model.expiry ??= tesseractModel.expiry;
      } catch (e) {
        print('Error: Tesseract fallback failed: $e');
      }
    }

    return model;
  }

  Future<bool> isFrontSideImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    List<String> lines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        lines.add(line.text.trim());
      }
    }
    return isFrontSide(lines);
  }

  bool isFrontSide(List<String> lines) {
    final cnicRegex = RegExp(r"\d{5}-\d{7}-\d{1}");
    final dateRegex = RegExp(r"\d{2}[-/\.]\d{2}[-/\.]\d{4}");

    int dateCount = 0;
    print('OCR lines detected: $lines');

    for (String line in lines) {
      if (dateRegex.hasMatch(line)) dateCount++;

      if (line.toLowerCase().contains('name') ||
          line.toLowerCase().contains('نام') ||
          line.toLowerCase().contains('father') ||
          line.toLowerCase().contains('ولدیت') ||
          line.toLowerCase().contains('date of birth') ||
          line.toLowerCase().contains('تاریخ پیدائش')) {
        print('Front side detected by keyword: $line');
        return true;
      }
    }

    print('Date count: $dateCount');

    // Robust heuristic: 2 or more dates strongly suggest the back side (Issue & Expiry)
    // unless front keywords were already found.
    if (dateCount >= 2) {
      print('Back side suspected due to date count: $dateCount');
      return false;
    }

    // Check for CNIC number
    for (String line in lines) {
      if (cnicRegex.hasMatch(line)) {
        print('Front side suspected due to CNIC presence and low date count');
        return true;
      }
    }

    print('Side detection inconclusive, defaulting to false (Back)');
    return false;
  }

  CnicModel _extractFrontData(List<String> lines) {
    CnicModel model = CnicModel();

    final cnicRegex = RegExp(r"\d{5}-\d{7}-\d{1}");
    final dateRegex = RegExp(r"\d{2}[-/\.]\d{2}[-/\.]\d{4}");

    // Improved Name extraction regex
    final nameLabels = ['name', 'full name', 'نام'];
    final fatherLabels = [
      'father name',
      'father\'s name',
      'husband name',
      'husband\'s name',
      'ولدیت', // Father Name (Urdu)
      'شوهر جو نالو', // Father/Husband Name (Sindhi)
      'پيءُ جو نالو', // Father Name (Sindhi)
      'شور كانام', //Husband Name (Urdu),
      'والد کا نام', //Father Name (Urdu),
    ];
    print("DATA: $lines");
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase();

      // Extract CNIC
      if (cnicRegex.hasMatch(lines[i])) {
        model.cnicNumber = cnicRegex.stringMatch(lines[i]);
      }

      // Extract Dates
      if (dateRegex.hasMatch(lines[i])) {
        if (line.contains('birth') || line.contains('پیدائش')) {
          model.dob = dateRegex.stringMatch(lines[i]);
        } else if (line.contains('expiry') || line.contains('تِخْ')) {
          model.expiry = dateRegex.stringMatch(lines[i]);
        }
      }

      // Extract Name - look for text after label or on next line
      for (var label in nameLabels) {
        if (line.startsWith(label) || line.contains('$label:')) {
          String extracted = lines[i]
              .substring(lines[i].toLowerCase().indexOf(label) + label.length)
              .replaceAll(':', '')
              .trim();
          if (extracted.length > 2) {
            model.name = extracted;
          } else if (i + 1 < lines.length) {
            model.name = lines[i + 1].trim();
          }
          break;
        }
      }

      // Extract Father Name
      for (var label in fatherLabels) {
        if (line.contains(label)) {
          String extracted = lines[i]
              .substring(lines[i].toLowerCase().indexOf(label) + label.length)
              .replaceAll(':', '')
              .trim();
          if (extracted.length > 2) {
            model.fatherName = extracted;
          } else if (i + 1 < lines.length) {
            model.fatherName = lines[i + 1].trim();
          }
          break;
        }
      }
    }

    // Fallback for dates if labels not found
    List<String> dates = lines
        .where((l) => dateRegex.hasMatch(l))
        .map((l) => dateRegex.stringMatch(l)!)
        .toList();
    if (dates.length >= 2) {
      model.dob ??= dates[0];
      model.expiry ??=
          dates[dates.length - 1]; // Usually the last date is expiry
    }

    return model;
  }

  CnicModel _extractBackData(List<String> lines) {
    CnicModel model = CnicModel();
    final dateRegex = RegExp(r"\d{2}[-/\.]\d{2}[-/\.]\d{4}");

    // Labels for Address in English, Urdu, and Sindhi
    final addressLabels = [
      'address',
      'پتہ', // Urdu
      'پتو', // Sindhi
      'موجودہ پتہ',
      'مستقل پتہ',
    ];

    bool capturingAddress = false;
    List<String> addressLines = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      String lowerLine = line.toLowerCase();

      // Check for address labels
      bool foundLabel = false;
      for (var label in addressLabels) {
        if (lowerLine.contains(label)) {
          foundLabel = true;
          capturingAddress = true;

          // Try to capture text after label on the same line
          int labelIndex = lowerLine.indexOf(label);
          String afterLabel = line
              .substring(labelIndex + label.length)
              .replaceAll(':', '')
              .trim();
          if (afterLabel.isNotEmpty && afterLabel.length > 3) {
            addressLines.add(afterLabel);
          }
          break;
        }
      }

      if (foundLabel) continue;

      if (capturingAddress) {
        // Stop if we hit a date, CNIC number, or other major card elements
        if (dateRegex.hasMatch(line) ||
            RegExp(r"\d{5}-\d{7}-\d{1}").hasMatch(line) ||
            lowerLine.contains('identity') ||
            lowerLine.contains('card') ||
            lowerLine.contains('signature')) {
          capturingAddress = false;
        } else if (line.isNotEmpty) {
          addressLines.add(line);
        }
      }
    }

    // Fallback: If no labels found, capture the largest text block on the back
    if (addressLines.isEmpty) {
      // Find blocks that are not dates or numbers
      List<String> textBlocks = lines
          .where(
            (l) =>
                l.length > 5 &&
                !dateRegex.hasMatch(l) &&
                !RegExp(r"\d{5}-\d{7}-\d{1}").hasMatch(l),
          )
          .toList();
      if (textBlocks.isNotEmpty) {
        model.address = textBlocks.join(' ');
      }
    } else {
      model.address = addressLines.join(' ');
    }

    return model;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
