import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart'; 
import 'dart:io';
import 'package:pdfium_dart/bind/pdfium_bindings.dart';

class Pdfium {
  late pdfium_wrapper _lib;
  late Pointer<fpdf_document_t__> document;

  Pdfium(Pointer<FPDF_LIBRARY_CONFIG>? pdfiumConfig){
    pdfiumConfig == null ? pdfiumConfig = nullptr : null;
    try{
      final DynamicLibrary nativeLib = () {
        if (Platform.isLinux || Platform.isAndroid) {
          return DynamicLibrary.open('libpdfium.so');
        } else if (Platform.isWindows) {
          return DynamicLibrary.open('libpdfium.dll');
        } else {
          throw UnsupportedError('Unsupported platform');
        }
      }();

      _lib = pdfium_wrapper(nativeLib);

      _lib.FPDF_InitLibraryWithConfig(pdfiumConfig);
    } catch(e){
      throw Exception(e);
    }
  }

  dispose(){
    _lib.FPDF_DestroyLibrary();
  }

  String getLastError(){
    var error = _lib.FPDF_GetLastError();

    switch(error){
      case 0:
        return 'SUCCESS';
      case 1:
        return 'UNKNOWN';
      case 2:
        return 'ERR_FILE';
      case 3:
        return 'ERR_FORMAT';
      case 4:
        return 'ERR_PASSWORD';
      case 5:
        return 'ERR_SECURITY';
      case 6:
        return 'ERR_PAGE';
      case 7:
        return 'ERR_XFALOAD';
      case 8:
        return 'ERR_XFALAYOUT';
      default:
        return 'UNKNOWN';
    }
  }

  int openDocument(String path, {String password = ''}){
    var ppath = path.toNativeUtf8();
    var ppass = password.toNativeUtf8();

    document = _lib.FPDF_LoadDocument(ppath.cast(), ppass.cast());
    if(document.address == 0) return 1;

    calloc.free(ppath);
    calloc.free(ppass);
    
    return 0;
  }

  int countPages(){
    return _lib.FPDF_GetPageCount(document);
  }

  int countChars(int pageIndex) {
    final page = _lib.FPDF_LoadPage(document, pageIndex);
    if (page.address == 0) return -1;

    final textPage = _lib.FPDFText_LoadPage(page);
    if (textPage.address == 0) {
      _lib.FPDF_ClosePage(page);
      return -1;
    }

    final count = _lib.FPDFText_CountChars(textPage);

    _lib.FPDFText_ClosePage(textPage);
    _lib.FPDF_ClosePage(page);

    return count;
  }

  String getText(int pageIndex){
    FPDF_PAGE page = _lib.FPDF_LoadPage(document, pageIndex);
    if(page == nullptr) return '';

    FPDF_TEXTPAGE txtPage = _lib.FPDFText_LoadPage(page);
    if(txtPage == nullptr){
      _lib.FPDF_ClosePage(page);
      return '';
    }

    int pageLen = _lib.FPDFText_CountChars(txtPage);

    Pointer<UnsignedShort> buffer = malloc<UnsignedShort>((pageLen + 1) * sizeOf<UnsignedShort>());

    _lib.FPDFText_GetText(
      txtPage,
      0,
      pageLen,
      buffer
    );

    _lib.FPDFText_ClosePage(txtPage);
    _lib.FPDF_ClosePage(page);

    final List<int> bufContent = []; 
    for(int i=0; i<pageLen; i++){
      bufContent.add(buffer[i]);
    }
    
    malloc.free(buffer);

    return String.fromCharCodes(bufContent);
  }

  Uint8List? renderPage(
  int pageIndex,
  int width,
  int height
) {
  final FPDF_PAGE page = _lib.FPDF_LoadPage(document, pageIndex);
  if (page == nullptr) return null;

  final bitmap = _lib.FPDFBitmap_Create(width, height, 0);
  if (bitmap.address == 0){
    _lib.FPDF_ClosePage(page);
    return null;
  }

  final stride = _lib.FPDFBitmap_GetStride(bitmap);

  _lib.FPDFBitmap_FillRect(
    bitmap,
    0,
    0,
    width,
    height,
    0xFFFFFFFF
  );

  _lib.FPDF_RenderPageBitmap(
    bitmap,
    page,
    0,
    0,
    width,
    height,
    0,
    FPDF_ANNOT | FPDF_REVERSE_BYTE_ORDER
  );

  final buffer = _lib.FPDFBitmap_GetBuffer(bitmap);
  if(buffer == nullptr) return null;
  if(buffer.address == 0) return null;
  
  final rgba =Uint8List.fromList(
    buffer.cast<Uint8>().asTypedList(stride * height)
  );

  _lib.FPDFBitmap_Destroy(bitmap);
  _lib.FPDF_ClosePage(page);

  return rgba;
}

  Uint8List? getThumbnail(int pageIndex){
    final page = _lib.FPDF_LoadPage(document, pageIndex);

    final bitmap = _lib.FPDFPage_GetThumbnailAsBitmap(page);
    if(bitmap == nullptr){
      _lib.FPDF_ClosePage(page);
      return null;
    }

    final stride = _lib.FPDFBitmap_GetStride(bitmap);
    final height = _lib.FPDFBitmap_GetHeight(bitmap);
    
    final length = stride * height;

    final buffer = _lib.FPDFBitmap_GetBuffer(bitmap) as Pointer<Uint8>;    
    if(buffer == nullptr){
      _lib.FPDF_ClosePage(page);
      return null;
    }

    final thumb = Uint8List.fromList(buffer.asTypedList(length));
    _lib.FPDF_ClosePage(page);
    if(thumb.isEmpty) return null;    

    return thumb;
  }
}