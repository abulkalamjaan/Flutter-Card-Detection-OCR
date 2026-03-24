import 'package:get/get.dart';
import '../models/cnic_model.dart';
import '../services/scanner_service.dart';
import '../services/ocr_service.dart';

class CnicController extends GetxController {
  final ScannerService _scannerService = ScannerService();
  final OcrService _ocrService = OcrService();

  final Rx<CnicModel> cnicModel = CnicModel().obs;
  final RxBool isLoading = false.obs;
  final RxString frontImagePath = ''.obs;
  final RxString backImagePath = ''.obs;
  final RxInt scanStep = 0
      .obs; // 0: Idle/Initial, 1: Scanning Front, 2: Scanning Back, 3: Completed

  @override
  void onClose() {
    _scannerService.dispose();
    _ocrService.dispose();
    super.onClose();
  }

  Future<void> startGuidedScan() async {
    // 1. Scan Front
    scanStep.value = 1;
    bool frontSuccess = await _processStep(isFront: true);
    if (!frontSuccess) {
      scanStep.value = 0;
      return;
    }

    // 2. Scan Back
    scanStep.value = 2;
    // Small delay/instruction pause
    await Future.delayed(const Duration(seconds: 1));

    bool backSuccess = await _processStep(isFront: false);
    if (!backSuccess) {
      // Stay on back step to allow retry
      return;
    }

    // 3. Complete
    scanStep.value = 3;
    Get.snackbar('Success', 'Both sides scanned successfully!');
  }

  Future<bool> _processStep({required bool isFront}) async {
    final path = await _scannerService.scanDocument();
    if (path == null) return false;

    isLoading.value = true;
    try {
      final detectedFront = await _ocrService.isFrontSideImage(path);
      if (isFront && !detectedFront) {
        Get.snackbar('Note', 'This might be the back side.');
      } else if (!isFront && detectedFront) {
        Get.snackbar('Note', 'This might be the front side.');
      }

      if (isFront) {
        frontImagePath.value = path;
      } else {
        backImagePath.value = path;
      }

      final extractedData = await _ocrService.processImage(
        path,
        isFront: isFront,
      );
      _updateModel(extractedData);
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to process image: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Keep these for manual trigger if needed, but update to use scanStep
  Future<void> scanFront() async {
    if (await _processStep(isFront: true)) {
      if (scanStep.value == 0) scanStep.value = 1;
    }
  }

  Future<void> scanBack() async {
    if (await _processStep(isFront: false)) {
      scanStep.value = 3;
    }
  }

  void _updateModel(CnicModel newData) {
    cnicModel.update((val) {
      if (newData.name != null) val?.name = newData.name;
      if (newData.fatherName != null) val?.fatherName = newData.fatherName;
      if (newData.cnicNumber != null) val?.cnicNumber = newData.cnicNumber;
      if (newData.dob != null) val?.dob = newData.dob;
      if (newData.expiry != null) val?.expiry = newData.expiry;
      if (newData.address != null) val?.address = newData.address;
    });
  }

  void updateField(String field, String value) {
    cnicModel.update((val) {
      switch (field) {
        case 'name':
          val?.name = value;
          break;
        case 'fatherName':
          val?.fatherName = value;
          break;
        case 'cnicNumber':
          val?.cnicNumber = value;
          break;
        case 'dob':
          val?.dob = value;
          break;
        case 'expiry':
          val?.expiry = value;
          break;
        case 'address':
          val?.address = value;
          break;
      }
    });
  }
}
