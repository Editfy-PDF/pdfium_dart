#include "pdfium_wrapper.h"

FPDF_LIBRARY_CONFIG config = {2, NULL, NULL, 0};

FFI_PLUGIN_EXPORT void pdfium_init(const FPDF_LIBRARY_CONFIG* cfg) {
  const FPDF_LIBRARY_CONFIG* final_cfg = cfg ? cfg : &config;
  FPDF_InitLibraryWithConfig(final_cfg);
}

FFI_PLUGIN_EXPORT void pdfium_dispose(){
  FPDF_DestroyLibrary();
}

FFI_PLUGIN_EXPORT FPDF_DOCUMENT pdfium_LoadDocument(FPDF_BYTESTRING path, FPDF_BYTESTRING password){
  return FPDF_LoadDocument(path, password);
}

FFI_PLUGIN_EXPORT void pdfium_CloseDocument(FPDF_DOCUMENT doc){
  FPDF_CloseDocument(doc);
}

FFI_PLUGIN_EXPORT int pdfium_PageCount(FPDF_DOCUMENT document){
  return FPDF_GetPageCount(document);
}

FFI_PLUGIN_EXPORT int pdfium_CharCount(FPDF_DOCUMENT doc, int pageIndex){
  FPDF_PAGE page = FPDF_LoadPage(doc, pageIndex);
  if (!page) return -1;
  
  FPDF_TEXTPAGE txtPage = FPDFText_LoadPage(page);
  if (!txtPage) {
    FPDF_ClosePage(page);
    return -1;
  }
   
  int charCount = FPDFText_CountChars(txtPage);

  FPDFText_ClosePage(txtPage);
  FPDF_ClosePage(page);

  return charCount;
}

FFI_PLUGIN_EXPORT int pdfium_GetPageText(FPDF_DOCUMENT doc, int pageIndex, unsigned short* buffer){
  FPDF_PAGE page = FPDF_LoadPage(doc, pageIndex);
  if (!page) return -1;
  
  FPDF_TEXTPAGE txtPage = FPDFText_LoadPage(page);
  if (!txtPage) {
    FPDF_ClosePage(page);
    return -1;
  }

  int pageLen = FPDFText_CountChars(txtPage);

  int result = FPDFText_GetText(
    txtPage,
    0,
    pageLen,
    buffer
  );

  FPDFText_ClosePage(txtPage);
  FPDF_ClosePage(page);

  return result > 0 ? result : -1;
}

FFI_PLUGIN_EXPORT unsigned short* pdfium_NewBuffer(FPDF_DOCUMENT doc, int pageIndex){
  FPDF_PAGE page = FPDF_LoadPage(doc, pageIndex);
  if (!page) return NULL;
  
  FPDF_TEXTPAGE txtPage = FPDFText_LoadPage(page);
  if (!txtPage) {
    FPDF_ClosePage(page);
    return NULL;
  }

  int pageLen = FPDFText_CountChars(txtPage);

  FPDFText_ClosePage(txtPage);
  FPDF_ClosePage(page);

  int pageSize = (pageLen + 1) * sizeof(unsigned short);
  
  unsigned short* buffer = (unsigned short*) malloc(pageSize);
  return buffer ? buffer : NULL;
}

FFI_PLUGIN_EXPORT void pdfium_FreeBuffer(unsigned short* buffer) {
    free(buffer);
}
