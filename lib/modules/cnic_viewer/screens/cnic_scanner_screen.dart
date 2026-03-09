import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cnic_controller.dart';

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
              _buildScanButtons(),
              const SizedBox(height: 24),
              _buildImagePreviews(),
              const SizedBox(height: 24),
              const Text(
                'Extracted Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
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
            ],
          ),
        );
      }),
    );
  }

  Widget _buildScanButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.scanFront,
            icon: const Icon(Icons.camera_front),
            label: const Text('Scan Front'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[100]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.scanBack,
            icon: const Icon(Icons.camera_rear),
            label: const Text('Scan Back'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[100]),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviews() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text('Front Side'),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: controller.frontImagePath.value.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(controller.frontImagePath.value),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              const Text('Back Side'),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: controller.backImagePath.value.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(controller.backImagePath.value),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ],
          ),
        ),
      ],
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
