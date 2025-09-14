#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "fpdfview.h"
#include "fpdf_text.h"

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT void pdfium_init(const FPDF_LIBRARY_CONFIG* cfg);

FFI_PLUGIN_EXPORT void pdfium_dispose();

FFI_PLUGIN_EXPORT FPDF_DOCUMENT pdfium_LoadDocument(FPDF_BYTESTRING path, FPDF_BYTESTRING password);

FFI_PLUGIN_EXPORT void pdfium_CloseDocument(FPDF_DOCUMENT doc);

FFI_PLUGIN_EXPORT int pdfium_PageCount(FPDF_DOCUMENT document);

FFI_PLUGIN_EXPORT int pdfium_CharCount(FPDF_DOCUMENT doc, int pageIndex);

FFI_PLUGIN_EXPORT int pdfium_GetPageText(FPDF_DOCUMENT doc, int pageIndex, unsigned short* buffer);

FFI_PLUGIN_EXPORT unsigned short* pdfium_NewBuffer(FPDF_DOCUMENT doc, int pageIndex);

FFI_PLUGIN_EXPORT void pdfium_FreeBuffer(unsigned short* buffer);