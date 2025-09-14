import 'dart:ffi';
import 'package:ffi/ffi.dart'; 
import 'dart:io';
import 'package:pdfium_dart/bind/pdfium_bindings.dart';

class Pdfium {
  late pdfium_wrapper _lib;
  late Pointer<fpdf_document_t__> document;

  Pdfium(){
    try{
      final DynamicLibrary nativeLib = () {
        if (Platform.isLinux) {
          return DynamicLibrary.open('libpdfium_dart.so');
        } else if (Platform.isWindows) {
          return DynamicLibrary.open('pdfium_dart.dll');
        } else {
          throw UnsupportedError('Unsupported platform');
        }
      }();

      _lib = pdfium_wrapper(nativeLib);
    
      _lib.pdfium_init(nullptr);
    } catch(e){
      stdout.write(e);
    }
  }

  dispose(){
    _lib.pdfium_dispose();
  }

  void openDoc(String path){
    var ppath = path.toNativeUtf8();
    
    try{
      document = _lib.pdfium_LoadDocument(ppath.cast(), nullptr);
    } catch(e){
      stdout.write(e);
    } finally{
      calloc.free(ppath);
    }
  }

  int countPages(){
    return _lib.pdfium_PageCount(document);
  }

  int countChars(int pageIndex){
    return _lib.pdfium_CharCount(document, pageIndex);
  }

  String getText(int pageIndex){
    final buffer = _lib.pdfium_NewBuffer(document, pageIndex);
    if(buffer == nullptr){
      return '';
    }

    final charLen = _lib.pdfium_GetPageText(document, pageIndex, buffer);
    if(charLen == -1){
      return '';
    }

    final List<int> bufContent = []; 
    for(int i=0; i<charLen; i++){
      bufContent.add(buffer[i]);
    }
    
    calloc.free(buffer);

    return String.fromCharCodes(bufContent);
  }
}