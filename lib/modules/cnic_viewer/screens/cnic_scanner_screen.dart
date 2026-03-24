import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cnic_controller.dart';
import '../widgets/shimmer_widget.dart';

class CnicScannerScreen extends StatelessWidget {
  final CnicController controller = Get.put(CnicController());

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
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.scanStep.value == 0) ...[
                _buildStartButton(),
              ] else if (controller.scanStep.value < 3) ...[
                _buildGuidedInstruction(),
                const SizedBox(height: 24),
              ],
              if (controller.scanStep.value == 3) ...[
                const Text(
                  'Extracted Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildResultForm(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 16),
                _buildResetButton(),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStartButton() {
    return Column(
      children: [
        const SizedBox(height: 40),
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
          ),
          child: const Text(
            'Start Guided Scan',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildGuidedInstruction() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          InstructionAnimation(isFront: controller.scanStep.value == 1),
          const SizedBox(height: 40),
          if (controller.isLoading.value) ...[
            const CircularProgressIndicator(),
          ] else ...[
            TextButton.icon(
              onPressed: controller.scanStep.value == 1
                  ? controller.scanFront
                  : controller.scanBack,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Current Side'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        Get.snackbar('Success', 'Data saved successfully!');
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      child: const Text('Save Data'),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton(
      onPressed: () {
        controller.scanStep.value = 0;
        // Optionally clear data
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Scan Another Card'),
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
          'Date of Birth',
          model.dob ?? '',
          (v) => controller.updateField('dob', v),
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
        key: Key(
          '${label}_$initialValue',
        ), // Force rebuild when initialValue changes
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
