import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:id_ocr/id_ocr.dart';
import 'modules/cnic_viewer/screens/cnic_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CNIC OCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: CnicScannerScreen(),
    );
  }
}
