import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/cnic_controller.dart';
import '../widgets/shimmer_widget.dart';

class CnicScannerScreen extends StatelessWidget {
  final CnicController controller = Get.put(CnicController());

  CnicScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CNIC Detection & Extraction'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildCurrentStep(context),
        );
      }),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (controller.scanStep.value) {
      case 0:
        return _buildStartView(context);
      case 1:
        return _buildInstructionView(isFront: true);
      case 2:
        return _buildExtractingView(isFront: true);
      case 3:
        return _buildInstructionView(isFront: false);
      case 4:
        return _buildExtractingView(isFront: false);
      case 5:
        return _buildResultView();
      default:
        return _buildStartView(context);
    }
  }

  Widget _buildStartView(BuildContext context) {
    return Center(
      key: const ValueKey('start'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.document_scanner, size: 80, color: Colors.indigo),
          const SizedBox(height: 24),
          const Text(
            'Ready to scan your CNIC?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will scan both sides in one sequence.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: controller.startGuidedScan,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
            ),
            child: const Text('Start Scanning', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showManualScanSource(context),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Still having issues? Try Manual Capture'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualScanSource(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Manual Capture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Front Photo'),
              onTap: () {
                Get.back();
                _processManualImage(isFront: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Back Photo'),
              onTap: () {
                Get.back();
                _processManualImage(isFront: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                _processManualImage(isFront: true, isGallery: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processManualImage({required bool isFront, bool isGallery = false}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: isGallery ? ImageSource.gallery : ImageSource.camera,
    );
    
    if (image != null) {
      controller.processManualImage(path: image.path, isFront: isFront);
    }
  }

  Widget _buildInstructionView({required bool isFront}) {
    return Center(
      key: ValueKey('instr_$isFront'),
      child: InstructionAnimation(isFront: isFront),
    );
  }

  Widget _buildExtractingView({required bool isFront}) {
    return Center(
      key: ValueKey('extract_$isFront'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const LaserScannerAnimation(width: 280, height: 180),
              const Icon(Icons.psychology, size: 48, color: Colors.indigo),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Extracting Details...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we process the image',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Extracted Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please verify and edit if necessary',
            style: TextStyle(color: Colors.grey),
          ),
          const Divider(height: 32),
          _buildResultForm(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Get.snackbar('Success', 'Data saved successfully!');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Data'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: controller.reset,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.indigo),
            ),
            child: const Text('Scan Another Card'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultForm() {
    final model = controller.cnicModel.value;
    return Column(
      children: [
        _buildTextField(
          'Full Name',
          model.name ?? '',
          (v) => controller.updateField('name', v),
        ),
        _buildTextField(
          'Father Name',
          model.fatherName ?? '',
          (v) => controller.updateField('fatherName', v),
        ),
        _buildTextField(
          'CNIC Number',
          model.cnicNumber ?? '',
          (v) => controller.updateField('cnicNumber', v),
        ),
        _buildTextField(
          'Gender',
          model.gender ?? '',
          (v) => controller.updateField('gender', v),
        ),
        _buildTextField(
          'Date of Birth',
          model.dob ?? '',
          (v) => controller.updateField('dob', v),
        ),
        _buildTextField(
          'Date of Issue',
          model.issueDate ?? '',
          (v) => controller.updateField('issueDate', v),
        ),
        _buildTextField(
          'Date of Expiry',
          model.expiry ?? '',
          (v) => controller.updateField('expiry', v),
        ),
        _buildTextField(
          'Address',
          model.address ?? '',
          (v) => controller.updateField('address', v),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String initialValue,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        key: Key('${label}_$initialValue'),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: onChanged,
        maxLines: maxLines,
      ),
    );
  }
}
