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

  @override
  void onClose() {
    _scannerService.dispose();
    _ocrService.dispose();
    super.onClose();
  }

  Future<void> scanFront() async {
    final path = await _scannerService.scanDocument();
    if (path != null) {
      isLoading.value = true;
      try {
        final isFront = await _ocrService.isFrontSideImage(path);
        if (!isFront) {
          Get.snackbar(
            'Note',
            'This might be the back side, check the results.',
          );
        }

        frontImagePath.value = path;
        final recognizedText = await _ocrService.processImage(
          path,
          isFront: true,
        );
        _updateModel(recognizedText);
      } catch (e) {
        Get.snackbar('Error', 'Failed to process front image: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> scanBack() async {
    final path = await _scannerService.scanDocument();
    if (path != null) {
      isLoading.value = true;
      try {
        final isFront = await _ocrService.isFrontSideImage(path);
        if (isFront) {
          Get.snackbar(
            'Note',
            'This might be the front side, check the results.',
          );
        }

        backImagePath.value = path;
        final extractedData = await _ocrService.processImage(
          path,
          isFront: false,
        );
        _updateModel(extractedData);
      } catch (e) {
        Get.snackbar('Error', 'Failed to process back image: $e');
      } finally {
        isLoading.value = false;
      }
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
