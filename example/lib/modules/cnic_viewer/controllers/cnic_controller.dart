import 'package:get/get.dart';
import 'package:id_ocr/id_ocr.dart';

class CnicController extends GetxController {
  final ScannerService _scannerService = ScannerService();
  final OcrService _ocrService = OcrService();

  final Rx<CnicModel> cnicModel = CnicModel().obs;
  final RxBool isLoading = false.obs;
  final RxString frontImagePath = ''.obs;
  final RxString backImagePath = ''.obs;
  // 0: Initial, 1: Front Instr, 2: Front Extracting, 3: Back Instr, 4: Back Extracting, 5: Form
  final RxInt scanStep = 0.obs;

  @override
  void onClose() {
    _scannerService.dispose();
    _ocrService.dispose();
    super.onClose();
  }

  Future<void> startGuidedScan() async {
    // 1. Instruction Front
    scanStep.value = 1;
    await Future.delayed(const Duration(milliseconds: 500));

    // Trigger Scan Front
    bool frontSuccess = await _processStep(isFront: true);
    if (!frontSuccess) {
      scanStep.value = 0;
      return;
    }

    // 2. Instruction Back
    scanStep.value = 3;
    await Future.delayed(
      const Duration(milliseconds: 1500),
    ); // Time to see "Back" instruction

    // Trigger Scan Back
    bool backSuccess = await _processStep(isFront: false);
    if (!backSuccess) {
      return;
    }

    // 3. Complete -> Show Form
    scanStep.value = 5;
    Get.snackbar('Success', 'Extraction completed!');
  }

  Future<bool> _processStep({required bool isFront}) async {
    final path = await _scannerService.scanDocument();
    if (path == null) return false;

    // Set to extracting state
    scanStep.value = isFront ? 2 : 4;
    isLoading.value = true;

    // Simulate some "cool" processing time for animation
    await Future.delayed(const Duration(seconds: 2));

    try {
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

  void reset() {
    scanStep.value = 0;
    frontImagePath.value = '';
    backImagePath.value = '';
    cnicModel.value = CnicModel();
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
