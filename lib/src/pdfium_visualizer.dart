import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdfium_dart/pdfium_dart.dart';

class PdfView extends StatefulWidget{
  final String path;
  final double initialZoom;

  const PdfView({
    super.key,
    required this.path,
    this.initialZoom = 1.0,
  });

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  late final Pdfium _pdfium;
  int _pageCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async{
    _pdfium = Pdfium(null);
    if(_pdfium.openDocument(widget.path) != 0) throw Exception('arquivo não carregado');

    setState(() {
      _pageCount = _pdfium.countPages();
      _loaded = true;
    });
  }

  @override
  void dispose(){
    _pdfium.dispose();
    super.dispose();
  }

  Future<Uint8List?> _renderPage(int index, double scale) async{
    final width = (800 * scale).toInt();
    final height = (1000 * scale).toInt();

    final data = _pdfium.renderPage(index, width, height);
    if(data == null) return null;

    final image = img.Image.fromBytes(
      bytes: data.buffer,
      width: width,
      height: height,
      numChannels: 4
    );

    return img.encodePng(image);
  }

  @override
  Widget build(BuildContext context){
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
      
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      boundaryMargin: const EdgeInsets.all(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          itemCount: _pageCount,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return FutureBuilder<Uint8List?>(
              future: _renderPage(index, widget.initialZoom),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  );
                }

                final data = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.memory(
                    data,
                    fit: BoxFit.contain,
                  ),
                );
              },
            );
          },
        ),
      )
    );
  }
}