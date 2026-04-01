import 'package:flutter/foundation.dart';
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

    // 2. Fallback to Tesseract if Urdu/Sindhi script fields are missing or garbage
    bool needsFallback = false;
    if (isFront) {
      needsFallback = _isGarbage(model.name) || _isGarbage(model.fatherName);
    } else {
      needsFallback = _isGarbage(model.address);
    }

    if (needsFallback) {
      debugPrint(
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

        debugPrint('DEBUG: Tesseract raw lines: $tesseractLines');

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
        model.issueDate ??= tesseractModel.issueDate;
        model.gender ??= tesseractModel.gender;

        debugPrint(
          'DEBUG: Merged Model: ${model.cnicNumber}, ${model.name}, ${model.dob}',
        );
      } catch (e) {
        debugPrint('Error: Tesseract fallback failed: $e');
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
    final cnicRegex = RegExp(r"[0-9۰-۹]{5}[-\s]?[0-9۰-۹]{7}[-\s]?[0-9۰-۹]{1}");
    final dateRegex = RegExp(
      r"[0-9۰-۹]{2}\s?[-/\.]\s?[0-9۰-۹]{2}\s?[-/\.]\s?[0-9۰-۹]{4}",
    );

    int dateCount = 0;
    debugPrint('OCR lines detected: $lines');

    for (String line in lines) {
      if (dateRegex.hasMatch(line)) dateCount++;

      if (line.toLowerCase().contains('name') ||
          line.toLowerCase().contains('نام') ||
          line.toLowerCase().contains('father') ||
          line.toLowerCase().contains('ولدیت') ||
          line.toLowerCase().contains('date of birth') ||
          line.toLowerCase().contains('تاریخ پیدائش')) {
        debugPrint('Front side detected by keyword: $line');
        return true;
      }
    }

    debugPrint('Date count: $dateCount');

    // Robust heuristic: 2 or more dates strongly suggest the back side (Issue & Expiry)
    // unless front keywords were already found.
    if (dateCount >= 2) {
      debugPrint('Back side suspected due to date count: $dateCount');
      return false;
    }

    // Check for CNIC number
    for (String line in lines) {
      if (cnicRegex.hasMatch(line)) {
        debugPrint('Front side suspected due to CNIC presence and low date count');
        return true;
      }
    }

    debugPrint('Side detection inconclusive, defaulting to false (Back)');
    return false;
  }

  CnicModel _extractFrontData(List<String> lines) {
    CnicModel model = CnicModel();

    final cnicRegex = RegExp(r"[0-9۰-۹]{5}[-\s]?[0-9۰-۹]{7}[-\s]?[0-9۰-۹]{1}");
    final dateRegex = RegExp(
      r"[0-9۰-۹]{2}\s?[-/\.]\s?[0-9۰-۹]{2}\s?[-/\.]\s?[0-9۰-۹]{4}",
    );

    // Improved Name extraction regex
    final nameLabels = [
      'name',
      'full name',
      'نام',
      'نالو',
      'full narne',
      'narne',
    ];
    final fatherLabels = [
      'father name',
      'father narne',
      'father\'s name',
      'husband name',
      'husband narne',
      'husband\'s name',
      'ولدیت', // Father Name (Urdu)
      'شوهر جو نالو', // Father/Husband Name (Sindhi)
      'پيءُ جو نالو', // Father Name (Sindhi)
      'مڑس جو نالو', // Husband Name (Sindhi)
      'شور كانام', //Husband Name (Urdu),
      'والد کا نام', //Father Name (Urdu),
    ];
    // Labels for Gender and Issue Date
    final genderLabels = ['gender', 'sex', 'جنس'];
    final issueLabels = [
      'date of issue',
      'issue date',
      'تاریخ اجراء',
      'جاري ڪيل تاريخ'
    ];
    final expiryLabels = [
      'expiry',
      'expiry date',
      'valid upto',
      'تاریخ تنسیخ',
      'ختم ٿيڻ جي تاريخ',
      'تِخْ', // OCR noise for urdu expiry
      'ختم'
    ];

    print("DATA: $lines");
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase();

      if (cnicRegex.hasMatch(lines[i])) {
        String match = cnicRegex.stringMatch(lines[i])!;
        // Normalize: Ensure it has hyphens for consistency in the model
        match = match.replaceAll(RegExp(r"[-\s]"), "");
        if (match.length == 13) {
          model.cnicNumber =
              "${match.substring(0, 5)}-${match.substring(5, 12)}-${match.substring(12, 13)}";
        } else {
          model.cnicNumber = match;
        }
      }

      // Extract Dates
      if (line.contains('birth') ||
          line.contains('پیدائش') ||
          line.contains('ڄمڻ')) {
        if (dateRegex.hasMatch(lines[i])) {
          model.dob = dateRegex.stringMatch(lines[i]);
        } else if (i + 1 < lines.length && dateRegex.hasMatch(lines[i + 1])) {
          model.dob = dateRegex.stringMatch(lines[i + 1]);
        }
      }

      for (var label in issueLabels) {
        if (line.contains(label)) {
          if (dateRegex.hasMatch(lines[i])) {
            model.issueDate = dateRegex.stringMatch(lines[i]);
          } else if (i + 1 < lines.length &&
              dateRegex.hasMatch(lines[i + 1])) {
            model.issueDate = dateRegex.stringMatch(lines[i + 1]);
          }
          break;
        }
      }

      for (var label in expiryLabels) {
        if (line.contains(label)) {
          if (dateRegex.hasMatch(lines[i])) {
            model.expiry = dateRegex.stringMatch(lines[i]);
          } else if (i + 1 < lines.length &&
              dateRegex.hasMatch(lines[i + 1])) {
            model.expiry = dateRegex.stringMatch(lines[i + 1]);
          }
          break;
        }
      }

      // Extract Gender
      for (var label in genderLabels) {
        if (line.contains(label)) {
          String extracted = lines[i]
              .substring(lines[i].toLowerCase().indexOf(label) + label.length)
              .replaceAll(':', '')
              .trim();
          if (extracted.isEmpty && i + 1 < lines.length) {
            extracted = lines[i + 1].trim();
          }

          if (extracted.isNotEmpty) {
            final lower = extracted.toLowerCase();
            if (lower.startsWith('m') || lower.contains('مرد')) {
              model.gender = 'Male';
            } else if (lower.startsWith('f') ||
                lower.contains('عورت') ||
                lower.contains('مائی')) {
              model.gender = 'Female';
            } else {
              model.gender = extracted;
            }
          }
          break;
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
    if (dates.length >= 3) {
      model.dob ??= dates[0];
      model.issueDate ??= dates[1];
      model.expiry ??= dates[2];
    } else if (dates.length == 2) {
      model.dob ??= dates[0];
      model.expiry ??= dates[1];
    }

    return model;
  }

  CnicModel _extractBackData(List<String> lines) {
    CnicModel model = CnicModel();
    final dateRegex = RegExp(
      r"[0-9۰-۹]{2}\s?[-/\.]\s?[0-9۰-۹]{2}\s?[-/\.]\s?[0-9۰-۹]{4}",
    );

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

    final issueLabels = [
      'date of issue',
      'issue date',
      'تاریخ اجراء',
      'جاري ڪيل تاريخ'
    ];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      String lowerLine = line.toLowerCase();

      // Check for dates on back
      for (var label in issueLabels) {
        if (lowerLine.contains(label)) {
          if (dateRegex.hasMatch(lines[i])) {
            model.issueDate ??= dateRegex.stringMatch(lines[i]);
          } else if (i + 1 < lines.length &&
              dateRegex.hasMatch(lines[i + 1])) {
            model.issueDate ??= dateRegex.stringMatch(lines[i + 1]);
          }
          break;
        }
      }
      
      // Check for expiry labels on back
      final expiryLabels = [
        'expiry',
        'expiry date',
        'valid upto',
        'تاریخ تنسیخ',
        'ختم ٿيڻ جي تاريخ',
        'ختم'
      ];
      for (var label in expiryLabels) {
        if (lowerLine.contains(label)) {
          if (dateRegex.hasMatch(lines[i])) {
            model.expiry ??= dateRegex.stringMatch(lines[i]);
          } else if (i + 1 < lines.length &&
              dateRegex.hasMatch(lines[i + 1])) {
            model.expiry ??= dateRegex.stringMatch(lines[i + 1]);
          }
          break;
        }
      }

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

  bool _isGarbage(String? text) {
    if (text == null || text.trim().isEmpty) return true;
    // Remove symbols and see if anything substantial remains
    final clean = text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
    return clean.isEmpty || clean.length < 2;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
