import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart'; 
import 'dart:io';
import 'package:pdfium_dart/bind/pdfium_bindings.dart';

class Pdfium {
  late pdfium_wrapper _lib;
  late Pointer<fpdf_document_t__> document;

  Pdfium(){
    try{
      final DynamicLibrary nativeLib = () {
        if (Platform.isLinux || Platform.isAndroid) {
          return DynamicLibrary.open('src/build/libpdfium_dart.so'); // alterar para produção
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

  String getLastError(){
    var error = _lib.pdfium_GetLastError();

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

  void openDoc(String path, {String password = ''}){
    var ppath = path.toNativeUtf8();
    var ppass = password.toNativeUtf8();
    
    try{
      document = _lib.pdfium_LoadDocument(ppath.cast(), ppass.cast());
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

  Uint8List? renderPage(int scrWidth, int scrHeight, int pageIndex){
    final size = calloc<FS_SIZEF>();

    var bool = _lib.pdfium_GetSizeByIndex(document, pageIndex, size.ref); // size não está retornando valores
    print('bool -> $bool');
    if(bool != 0){
      calloc.free(size);
      return null;
    }
    
    int dpi = 150;
    double scale = dpi / 72;
    print('scale -> $scale');
    print('pdfWidth -> ${size.ref.width}');
    print('pdfHeight -> ${size.ref.height}');

    int width = size.ref.width.toInt() * scale.toInt();
    print('width -> $width');
    int height = size.ref.height.toInt() * scale.toInt();
    print('height -> $height');

    var bitmap = _lib.pdfium_CreateBitmapBuffer(width, height, 1);
    if(bitmap == nullptr) return null;
    
    var result = _lib.pdfium_RenderPage(document, bitmap, pageIndex, width, height);
    if(result == 1){
      _lib.pdfium_freeBitmapBuffer(bitmap);
      return null;
    }

    int nBytes = _lib.pdfium_GetBitmapFormat(bitmap);
    int length = sizeOf<Uint8>() * width * height * nBytes;
    
    var rawData = _lib.pdfium_GetBuffer(bitmap);
    
    if(rawData == nullptr){
      _lib.pdfium_freeBitmapBuffer(bitmap);
      return null;
    }

    Uint8List data = rawData.asTypedList(length);

    calloc.free(size);
    _lib.pdfium_freeBitmapBuffer(bitmap);

    return data;
  }

  // Não está retornando dados
  Uint8List? getThumbnail(int pageIndex){
    var bitmap = _lib.pdfium_GetBitmapThumb(document, pageIndex);
    var width = _lib.pdfium_GetBitmapWidth(bitmap);
    var height = _lib.pdfium_GetBitmapHeight(bitmap);
    int nBytes = _lib.pdfium_GetBitmapFormat(bitmap);
    
    int length = sizeOf<Uint8>() * width * height * nBytes;

    var rawData = _lib.pdfium_GetBuffer(bitmap);    

    Uint8List thumb = rawData.asTypedList(length);
    return thumb;
  }
}