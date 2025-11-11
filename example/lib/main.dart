import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfium_dart/pdfium_dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDFium Viewer',
      theme: ThemeData.dark(),
      home: const PdfHome(),
    );
  }
}

class PdfHome extends StatefulWidget {
  const PdfHome({super.key});

  @override
  State<PdfHome> createState() => _PdfHomeState();
}

class _PdfHomeState extends State<PdfHome> {
  String? _selectedPath;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPath = result.files.single.path!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFium Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Selecionar PDF',
            onPressed: _pickPdf,
          ),
        ],
      ),
      body: _selectedPath == null
      ? const Center(
        child: Text(
          'Selecione um arquivo PDF',
          style: TextStyle(fontSize: 16),
        ),
      )
      : PdfView(
        path: _selectedPath!,
        initialZoom: 1.0,
      ),
    );
  }
}

